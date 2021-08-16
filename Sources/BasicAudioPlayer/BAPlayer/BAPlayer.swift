//
//  BAPlayer.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import AVFoundation

/// A base class to create AVAudioEngine-based audio players.
open class BAPlayer {
    
    public private(set) var status: Status = .ready {
        didSet { delegate?.audioPlayer(self, statusChangedFrom: oldValue, to: status) }
    }
    
    public var loops: Bool = false
    
    public var delegate: BAPlayerDelegate?
    
    /// The playback point as a number of audio frames.
    public var currentFrame: AVAudioFramePosition {
        get {
            let cf = segmentStartingFrame + (playerNode.sampleTime ?? sampleTimeBeforeStop)
            return min(cf, audioFile.length)
        }
        set { seek(to: newValue) }
    }
    
    /// The playback point, in seconds, within the timeline of the sound associated with the player.
    open var currentTime: TimeInterval {
        get {
            Double(currentFrame) / audioFile.processingFormat.sampleRate
        }
        set {
            seek(to: AVAudioFramePosition(newValue * audioFile.processingFormat.sampleRate))
        }
    }
    
    public var format: AVAudioFormat {
        audioFile.processingFormat
    }
    
    public var duration: TimeInterval {
        Double(audioFile.length) / audioFile.processingFormat.sampleRate
    }
    
    public var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = max(0.0, min(newValue, 1.0)) }
    }
    
    public var audioFile: AVAudioFile
    
    public let engine: AVAudioEngine = .init()
    
    public let playerNode: AVAudioPlayerNode = .init()
    
    /// The starting frame of the scheduled segment of the audio file.
    private var segmentStartingFrame: AVAudioFramePosition = 0
    
    /// The playback time elapsed before stopping the playback, as a number of audio samples.
    private var sampleTimeBeforeStop: AVAudioFramePosition = 0
    
    /// Indicates whether the playerNode needs to reschedule.
    private var mustReschedule: Bool = false
    
    public init(url itemURL: URL) throws {
        
        audioFile = try AVAudioFile(forReading: itemURL)
        
        attachNodes()
        connectNodes()
        
        playerNode.scheduleFile(audioFile, at: nil)
        
        engine.prepare()
    }
    
    open func load(url itemURL: URL) throws {
        
        stop()
        
        audioFile = try AVAudioFile(forReading: itemURL)
        
        connectNodes()
        
        playerNode.scheduleFile(audioFile, at: nil)
        
        segmentStartingFrame = 0
        sampleTimeBeforeStop = 0
        
        mustReschedule = false
        
        engine.prepare()
    }
    
    /// Attaches audio nodes to the player's audio engine.
    open func attachNodes() {
        engine.attach(playerNode)
    }
    
    /// Connects the player's audio nodes.
    open func connectNodes() {
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
    }
    
    open func play() {
        guard status != .playing else { return }
        
        if !engine.isRunning {
            do {
                try engine.start()
            }
            catch {
                print(error.localizedDescription)
            }
        }
        
        if mustReschedule {
            segmentStartingFrame = 0
            
            playerNode.stop()
            playerNode.scheduleFile(audioFile, at: nil)
            
            mustReschedule = false
        }
        
        startPlaybackCompletionObserver()
        
        playerNode.play()
        status = .playing
    }
    
    open func pause() {
        
        guard status == .playing else { return }
        
        sampleTimeBeforeStop = playerNode.sampleTime!
        playerNode.pause()
        engine.pause()
        status = .paused
    }
    
    open func stop() {
        
        if status == .playing {// If the player is already paused, there's no need to update sampleTimeBeforeStop.
            sampleTimeBeforeStop = playerNode.sampleTime ?? 0
        }
        
        playerNode.stop()
        engine.stop()
        mustReschedule = true
        status = .ready
    }
    
    internal func seek(to frame: AVAudioFramePosition) {
        
        segmentStartingFrame = max(0, min(frame, audioFile.length))
        sampleTimeBeforeStop = 0
        
        let wasPlaying = (status == .playing)
        
        playerNode.stop()
        
        if segmentStartingFrame < audioFile.length {
            playerNode.scheduleSegment(
                audioFile,
                startingFrame: segmentStartingFrame,
                frameCount: AVAudioFrameCount(audioFile.length - segmentStartingFrame),
                at: nil
            )
            
            mustReschedule = false
            
            if wasPlaying { playerNode.play() }
        }
        else {
            engine.stop()
            mustReschedule = true
            status = .ready
        }
    }
    
    /// Calls the playback completion handler when the scheduled audio has been completely played.
    private func startPlaybackCompletionObserver() {
        
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            guard let self = self,
                  self.status == .playing
            else { return }
            
            if (self.currentFrame >= self.audioFile.length) {
                self.playbackCompletionHandler()
            }
            
            self.startPlaybackCompletionObserver()
        }
        .tolerance = 0.02
    }
    
    /// Called when the scheduled audio has been completely played.
    open func playbackCompletionHandler() {
        
        segmentStartingFrame = 0
        
        if status == .playing && loops {
            playerNode.stop()
            
            playerNode.scheduleFile(audioFile, at: nil)
            
            playerNode.play()
        }
        else {
            sampleTimeBeforeStop = audioFile.length
            mustReschedule = true
            engine.stop()
            status = .ready
        }
    }
}

//
//  AudioPlayer.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import AVFoundation

/// A base class to create audio players based on AVAudioEngine.
open class AudioPlayer {
    
    public private(set) var status: Status = .ready {
        didSet { delegate?.audioPlayerStatusChanged(self) }
    }
    
    public var loops: Bool = false
    
    public var delegate: AudioPlayerDelegate?
    
    public var currentFrame: AVAudioFramePosition {
        get { playerNode.currentFrame + segmentStartingFrame }
        set { seek(to: newValue) }
    }
    
    open var currentTime: TimeInterval {
        get {
            Double(currentFrame) / audioFile.processingFormat.sampleRate
        }
        set {
            seek(to: AVAudioFramePosition(newValue * audioFile.processingFormat.sampleRate))
        }
    }
    
    public var duration: TimeInterval {
        Double(audioFile.length) / audioFile.processingFormat.sampleRate
    }
    
    public var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = max(0.0, min(newValue, 1.0)) }
    }
    
    public var audioFile: AVAudioFile!
    
    public let engine: AVAudioEngine = .init()
    
    public let playerNode: AudioPlayerNode = .init()
    
    /// The starting frame of the scheduled segment of the audio file.
    private var segmentStartingFrame: AVAudioFramePosition = 0
    
    /// If true the player must reschedule the AVAudioFile on playing.
    private var mustReschedule: Bool = false
    
    public init(url itemURL: URL) throws {
        
        audioFile = try AVAudioFile(forReading: itemURL)
        
        attachNodes()
        connectNodes()
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: playbackCompletionHandler)
        
        engine.prepare()
    }
    
    public func load(url itemURL: URL) throws {
        
        if status != .ready { stop() }
        
        audioFile = try AVAudioFile(forReading: itemURL)
        
        connectNodes()
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: playbackCompletionHandler)
        
        if mustReschedule { mustReschedule = false }
        
        engine.prepare()
    }
    
    open func attachNodes() {
        engine.attach(playerNode)
    }
    
    open func connectNodes() {
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
    }
    
    //MARK: - Playback Control Functions
    
    open func play() {
        guard status != .playing else { return }
        
        if !engine.isRunning {
            do { try engine.start() }
            catch { print(error.localizedDescription) }
        }
        
        if mustReschedule {
            mustReschedule = false
            playerNode.stop()
            playerNode.scheduleFile(audioFile, at: nil, completionHandler: playbackCompletionHandler)
        }
        
        playerNode.play()
        status = .playing
    }
    
    open func pause() {
        playerNode.pause()
        engine.pause()
        engine.reset()
        status = .paused
    }
    
    open func stop() {
        playerNode.stop()
        engine.stop()
        segmentStartingFrame = 0
        mustReschedule = true
        status = .ready
    }
    
    internal func seek(to frame: AVAudioFramePosition) {
        
        if frame >= audioFile.length {
            loops ? seek(to: 0) : stop()
        }
        else {
            segmentStartingFrame = max(0, frame)
            
            let wasPlaying = playerNode.isPlaying
            
            playerNode.stop()
            
            playerNode.scheduleSegment(audioFile,
                                       startingFrame: segmentStartingFrame,
                                       frameCount: AVAudioFrameCount(audioFile.length - segmentStartingFrame),
                                       at: nil,
                                       completionHandler: playbackCompletionHandler)
            
            if mustReschedule { mustReschedule = false }
            if wasPlaying { playerNode.play() }
        }
        
    }
    
    /// Called when the scheduled audio has been completely played.
    open func playbackCompletionHandler() {
        DispatchQueue.main.async { [self] in
            segmentStartingFrame = 0
            
            if loops {
                playerNode.stop()
                playerNode.scheduleFile(audioFile, at: nil, completionHandler: playbackCompletionHandler)
                playerNode.play()
            }
            else {
                mustReschedule = true
                engine.stop()
                status = .ready
            }
        }
    }
}

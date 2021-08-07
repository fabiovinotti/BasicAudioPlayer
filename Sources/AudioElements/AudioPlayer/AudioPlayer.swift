//
//  AudioPlayer.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import AVFoundation
import Combine

/// A base class to create AVAudioEngine-based audio players.
open class AudioPlayer {
    
    public private(set) var status: Status = .ready {
        didSet { delegate?.audioPlayer(self, statusChangedFrom: oldValue, to: status) }
    }
    
    public var loops: Bool = false
    
    public var delegate: AudioPlayerDelegate?
    
    /// The playback point as a number of audio frames.
    public var currentFrame: AVAudioFramePosition {
        get { segmentStartingFrame + (playerNode.sampleTime ?? sampleTimeBeforeStop) }
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
    
    private var playbackCompletionSubscription: Cancellable?
    
    public init(url itemURL: URL) throws {
        
        audioFile = try AVAudioFile(forReading: itemURL)
        
        attachNodes()
        connectNodes()
        
        playbackCompletionSubscription = playerNode.scheduleFilePublisher(audioFile, at: nil)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: playbackCompletionHandler)
        
        engine.prepare()
    }
    
    public func load(url itemURL: URL) throws {
        
        stop()
        
        audioFile = try AVAudioFile(forReading: itemURL)
        
        connectNodes()
        
        playbackCompletionSubscription = playerNode.scheduleFilePublisher(audioFile, at: nil)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: playbackCompletionHandler)
        
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
            do { try engine.start() }
            catch { print(error.localizedDescription) }
        }
        
        if mustReschedule {
            segmentStartingFrame = 0
            
            playerNode.stop()
            playbackCompletionSubscription = playerNode.scheduleFilePublisher(audioFile, at: nil)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: playbackCompletionHandler)
            
            mustReschedule = false
        }
        
        playerNode.play()
        status = .playing
    }
    
    open func pause() {
        
        guard status == .playing else { return }
        
        sampleTimeBeforeStop = playerNode.sampleTime!
        playerNode.pause()
        engine.pause()
        engine.reset()
        status = .paused
    }
    
    open func stop() {
        
        playbackCompletionSubscription?.cancel()
        
        if status == .playing {// If the player is already paused, there's no need to update sampleTimeBeforeStop.
            sampleTimeBeforeStop = playerNode.sampleTime ?? 0
        }
        
        playerNode.stop()
        engine.stop()
        mustReschedule = true
        status = .ready
    }
    
    internal func seek(to frame: AVAudioFramePosition) {
        
        if frame >= audioFile.length {
            loops ? seek(to: 0) : stop()
        }
        else {
            sampleTimeBeforeStop = 0
            segmentStartingFrame = max(0, frame)
            
            let wasPlaying = (status == .playing)
            
            playbackCompletionSubscription?.cancel()
            playerNode.stop()
            
            playbackCompletionSubscription = playerNode.scheduleSegmentPublisher(
                audioFile,
                startingFrame: segmentStartingFrame,
                frameCount: AVAudioFrameCount(audioFile.length - segmentStartingFrame),
                at: nil
            )
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: playbackCompletionHandler)
            
            if mustReschedule { mustReschedule = false }
            if wasPlaying { playerNode.play() }
        }
        
    }
    
    /// Called when the scheduled audio has been completely played.
    open func playbackCompletionHandler() {
        
        segmentStartingFrame = 0
        
        if loops {
            playerNode.stop()
            
            playbackCompletionSubscription = playerNode.scheduleFilePublisher(audioFile, at: nil)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: playbackCompletionHandler)
            
            playerNode.play()
        }
        else {
            mustReschedule = true
            engine.stop()
            status = .ready
        }
    }
}

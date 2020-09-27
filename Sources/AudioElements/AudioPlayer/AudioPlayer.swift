//
//  AudioPlayer.swift
//  
//
//  Created by Fabio Vinotti on 9/17/20.
//

import AVFoundation
import MediaPlayer
import Combine

/// A base class to create audio players based on AVAudioEngine.
open class AudioPlayer {
    
    public var status: PlaybackStatus = .ready {
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
        audioFile.duration
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
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: completionHandler)
        
        engine.prepare()
    }
    
    public func load(url itemURL: URL) throws {
        
        if status != .ready { stop() }
        
        audioFile = try AVAudioFile(forReading: itemURL)
        
        connectNodes()
        
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: completionHandler)
        
        if mustReschedule { mustReschedule = false }
        
        engine.prepare()
    }
    
    open func attachNodes() {
        engine.attach(playerNode)
    }
    
    open func connectNodes() {
        engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
    }
    
    /// The function called when the scheduled audio has been completely played.
    open func completionHandler() {
        DispatchQueue.main.async { [unowned self] in
            segmentStartingFrame = 0
            mustReschedule = true
            
            loops ? play() : engine.stop()
        }
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
            playerNode.scheduleFile(audioFile, at: nil, completionHandler: completionHandler)
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
        
        segmentStartingFrame = min(max(0, frame), audioFile.length)
        
        if segmentStartingFrame == audioFile.length {
            stop()
            return
        }
        
        let wasPlaying = playerNode.isPlaying
        playerNode.stop()
        
        playerNode.scheduleSegment(audioFile,
                                   startingFrame: segmentStartingFrame,
                                   frameCount: AVAudioFrameCount(audioFile.length - segmentStartingFrame),
                                   at: nil,
                                   completionHandler: completionHandler)
        
        if mustReschedule { mustReschedule = false }
        if wasPlaying { playerNode.play() }
    }
    
}

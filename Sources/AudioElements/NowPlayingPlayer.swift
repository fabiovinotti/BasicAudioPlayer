//
//  NowPlayingPlayer.swift
//  
//
//  Created by Fabio Vinotti on 9/21/20.
//

import AVFoundation
import MediaPlayer
import Combine

open class NowPlayingPlayer: AudioPlayer, NowPlayable {
    
    public override var currentTime: TimeInterval {
        get { super.currentTime }
        set {
            super.currentTime = newValue
            updateNowPlayingInfo(playbackTime: Float(currentTime))
        }
    }
    
    public var rate: Float {
        get { timePitchNode.rate }
        set {
            timePitchNode.rate = newValue
            setPlaybackInfo(playbackRate: newValue, playbackTime: Float(currentTime))
        }
    }
    
    public var pitch: Float {
        get { timePitchNode.pitch }
        set { timePitchNode.pitch = newValue }
    }
    
    private let timePitchNode: AVAudioUnitTimePitch = .init()
    
    private var audioSessionInterruptionSubscription: AnyCancellable?
    
    open override func attachNodes() {
        engine.attach(playerNode)
        engine.attach(timePitchNode)
    }
    
    open override func connectNodes() {
        engine.connect(playerNode, to: timePitchNode, format: audioFile.processingFormat)
        engine.connect(timePitchNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
    }
    
    open override func completionHandler() {
        super.completionHandler()
        
        DispatchQueue.main.async {
            self.updateNowPlayingInfo(playbackTime: Float(self.currentTime))
        }
    }
    
    //MARK: - Initializers
    
    public override init(url itemURL: URL) throws {
        
        try super.init(url: itemURL)
        
        try activateAudioSession()
        
        enableRemoteCommands()
        setPlaybackInfo(playbackRate: 0.0, playbackTime: 0.0)
    }
    
    public convenience init(item: NowPlayableItem) throws {
        
        try self.init(url: item.assetURL)
        
        setNowPlayingInfo(from: item)
    }
    
    //MARK: - Load new item
    public override func load(url itemURL: URL) throws {
        
        try super.load(url: itemURL)
        
        setPlaybackInfo(playbackRate: 0.0, playbackTime: 0.0)
    }
    
    public func load(item: NowPlayableItem) throws {
        
        try super.load(url: item.assetURL)
        
        setNowPlayingInfo(from: item)
        setPlaybackInfo(playbackRate: 0.0, playbackTime: 0.0)
    }
    
    //MARK: - Playback control functions
    
    public override func play() {

        super.play()
        
        updateNowPlayingInfo(playbackRate: timePitchNode.rate)
    }
    
    public override func pause() {
        
        super.pause()
        
        setPlaybackInfo(playbackRate: 0.0, playbackTime: Float(currentTime))
    }
    
    public override func stop() {
        
        super.stop()
        
        updateNowPlayingInfo(playbackRate: 0.0)
    }
    
    //MARK: - Audio Session Management
    
    public func activateAudioSession() throws {
        
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.playback)
        try audioSession.setActive(true)
        
        audioSessionInterruptionSubscription = NotificationCenter.default
            .publisher(for: AVAudioSession.interruptionNotification)
            .sink(receiveValue: handleAudioSessionInterruption)
    }
    
    public func deactivateAudioSession() throws {
        
        audioSessionInterruptionSubscription?.cancel()
        
        try AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func handleAudioSessionInterruption(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo,
              let typeKey = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeKey)
        else { return }
        
        switch type {
        
        case .began:
            handleAudioSessionInterruptionBegan()
            
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                
                guard let optionsKey = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
                else { return }
                
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsKey)
                let shouldResume = options.contains(.shouldResume)
                
                handleAudioSessionInterruptionEnded(shouldResume: shouldResume)
            }
            catch {
                print("Failed to activate audio session after interruption ended: \(error)")
            }
            
        @unknown default:
            print("Unknown AVAudioSession.InterruptionType.")
        }
    }
    
    open func handleAudioSessionInterruptionBegan() {
        
    }
    
    open func handleAudioSessionInterruptionEnded(shouldResume: Bool) {
        if status == .playing {
            shouldResume ? playerNode.play() : pause()
        }
    }
    
    //MARK: - Remote Commands Handling
    
    open var enabledRemoteCommands: [RemoteCommand : RemoteCommand.CommandHandler] {
        [
            .play: {_ in
                self.play()
                return .success
            },
            
            .pause: {_ in
                self.pause()
                return.success
            },
            
            .togglePlayPause: {_ in
                self.status == .playing ? self.pause() : self.play()
                return .success
            },
            
            .stop: {_ in
                self.stop()
                return .success
            },
            
            .skipBackward: { event in
                guard let command = event.command as? MPSkipIntervalCommand,
                      let interval = command.preferredIntervals.first
                else {
                    return .commandFailed
                }
                
                self.currentTime = self.currentTime - Double(truncating: interval)
                return .success
            },
            
            .skipForward: { event in
                guard let command = event.command as? MPSkipIntervalCommand,
                      let interval = command.preferredIntervals.first
                else {
                    return .commandFailed
                }
                
                self.currentTime = self.currentTime + Double(truncating: interval)
                return .success
            },
            
            .changePlaybackPosition: { event in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }
                
                self.currentTime = event.positionTime
                return .success
            }
        ]
    }
    
    open var disabledRemoteCommands: [RemoteCommand]  {
        .init()
    }
}

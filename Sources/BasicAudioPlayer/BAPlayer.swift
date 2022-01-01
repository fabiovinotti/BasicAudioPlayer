//
//  BAPlayer.swift
//
//
//  Created by Fabio Vinotti on 25/11/21.
//

import AVFoundation
import Combine

/// A base class to create AVAudioEngine-based audio players.
open class BAPlayer {
    public typealias Status = AudioPlayerNode.Status
        
    /// The status of the underlying player node. It provides information about the playback status.
    public var status: Status {
        playerNode.status
    }
    
    /// Publishes the new status when it changes.
    public var statusPublisher: AnyPublisher<Status, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    /// Fires when the scheduled audio data have been completely played.
    public var playbackCompletionPublisher: AnyPublisher<Void, Never> {
        playbackCompletionSubject.eraseToAnyPublisher()
    }
    
    open var doesLoop: Bool {
        get { playerNode.doesLoop }
        set { playerNode.doesLoop = newValue }
    }
    
    public var currentTime: TimeInterval {
        get { playerNode.currentTime }
        set {
            if newValue >= duration {
                switch status {
                case .noSource:
                    playerNode.seek(to: newValue)
                case .ready:
                    playerNode.seek(to: 0)
                case .playing:
                    stop()
                    playerNode.seek(to: 0)
                case .paused:
                    playerNode.seek(to: 0)
                }
            } else {
                playerNode.seek(to: newValue)
            }
        }
    }
    
    public var duration: TimeInterval {
        playerNode.duration
    }
    
    public var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = max(0.0, min(newValue, 1.0)) }
    }
    
    public var file: AVAudioFile? {
        playerNode.file
    }
    
    public let engine = AVAudioEngine()
    
    public let playerNode = AudioPlayerNode()
    
    private let statusSubject = PassthroughSubject<Status, Never>()
    private let playbackCompletionSubject = PassthroughSubject<Void, Never>()
    
    public init() {
        playerNode.delegate = self
        attachNodes()
    }
    
    public convenience init(file: AVAudioFile) {
        self.init()
        load(file: file)
    }
    
    public convenience init(url fileURL: URL) throws {
        let f = try AVAudioFile(forReading: fileURL)
        self.init(file: f)
    }
    
    public func load(url fileURL: URL) throws {
        let f = try AVAudioFile(forReading: fileURL)
        load(file: f)
    }
    
    open func load(file: AVAudioFile) {
        playerNode.load(file: file)
        connectNodes()
        playerNode.schedule(at: nil)
        engine.prepare()
    }
    
    /// Attaches audio nodes to the player's audio engine.
    open func attachNodes() {
        engine.attach(playerNode.node)
    }
    
    /// Connects the player's audio nodes.
    open func connectNodes() {
        guard let f = file else {
            log("An error occurred while connecting nodes: No audio file available", level: .error)
            return
        }
        
        engine.connect(playerNode.node, to: engine.mainMixerNode, format: f.processingFormat)
    }
    
    public func play() {
        guard status != .noSource else {
            log("An error occurred on play: no audio source has been loaded yet", level: .error)
            return
        }
        
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                log("An error occurred on play: starting the engine failed with error: \(error.localizedDescription)", level: .error)
            }
        }
        
        playerNode.play()
    }
    
    public func pause() {
        guard status == .playing else { return }
        playerNode.pause()
        engine.pause()
    }
    
    public func stop() {
        guard status == .playing || status == .paused else { return }
        playerNode.stop()
        engine.stop()
    }
    
    private func playbackCompletionHandler() {
        playerNode.segmentStart = 0
        playerNode.segmentEnd = playerNode.duration
        
        if !doesLoop {
            engine.stop()
        }
    }
}

// MARK: - Playback Time Observer
extension BAPlayer {

    //TODO: Observers should stop when the playback is stopped or paused, and resumed on play.
    
    public func addTimeObserver(interval: TimeInterval, queue: DispatchQueue?, block: @escaping () -> Void) -> Any {
        let t = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        t.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        t.setEventHandler(handler: block)
        t.activate()
        return t
    }
    
    public func removeTimeObserver(_ observer: Any) {
        guard let o = observer as? DispatchSourceTimer else {
            log("An error occurred while removing time observer: The object provided is not an observer.", level: .error)
            return
        }
        
        o.cancel()
    }
    
    /// Executes a function when the indicated playback time is reached.
    public func onPlaybackTime(_ time: TimeInterval, queue: DispatchQueue?, execute block: @escaping () -> Void) -> Any {
        return addTimeObserver(interval: 0.01, queue: queue) { [weak self] in
            guard let self = self else { return }
            let ct = self.currentTime
            if ct >= time && ct <= time + 0.1 {  block() }
        }
    }
    
}

//MARK: - AudioPlayerNodeDelegate
extension BAPlayer: AudioPlayerNodeDelegate {
    
    public func playerNodeStatusDidChange(_ node: AudioPlayerNode, from oldStatus: AudioPlayerNode.Status, to newStatus: AudioPlayerNode.Status) {
        statusSubject.send(newStatus)
    }
    
    public func playerNodePlaybackDidComplete(_ node: AudioPlayerNode) {
        playbackCompletionHandler()
        playbackCompletionSubject.send()
    }
}

//
//  BAPlayer.swift
//
//
//  Created by Fabio Vinotti on 25/11/21.
//

import AVFoundation

/// A base class to create AVAudioEngine-based audio players.
open class BAPlayer: AudioPlayerNodeDelegate {
    
    // MARK: - Properties
    
    public let engine = AVAudioEngine()
    public let playerNode = AudioPlayerNode()
    
    public typealias Status = AudioPlayerNode.Status
    /// The status of the underlying player node. It provides information about the playback status.
    public var status: Status {
        playerNode.status
    }
    
    public var file: AVAudioFile? {
        playerNode.file
    }
    
    public var duration: TimeInterval {
        playerNode.duration
    }
    
    open var doesLoop: Bool {
        get { playerNode.doesLoop }
        set { playerNode.doesLoop = newValue }
    }
    
    open var currentTime: TimeInterval {
        get { playerNode.currentTime }
        set { playerNode.seek(to: newValue) }
    }
    
    // MARK: - Initializers
    
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
    
    // MARK: - Audio File Loaders
    
    open func load(file: AVAudioFile) {
        playerNode.load(file: file)
        connectNodes()
        playerNode.schedule(at: nil)
        engine.prepare()
    }
    
    public func load(url fileURL: URL) throws {
        let f = try AVAudioFile(forReading: fileURL)
        load(file: f)
    }
    
    // MARK: - Nodes Management
    
    /// Attaches the audio nodes to the engine.
    ///
    /// This method is called automatically when the nodes need to be attached to the engine.
    /// If your subclass adds new nodes that must be attached to its engine, override
    /// this function to include the code necessary to attach the nodes.
    open func attachNodes() {
        engine.attach(playerNode.node)
    }
    
    /// Connects the audio nodes to the engine.
    ///
    /// This method is called automatically when the nodes need to be connected.
    /// If your subclass adds new nodes that must be connected, override
    /// this function and implement the connections inside it.
    open func connectNodes() {
        guard let format = file?.processingFormat else {
            log("An error occurred while connecting nodes: No audio file available", level: .error)
            return
        }
        
        engine.connect(playerNode.node, to: engine.mainMixerNode, format: format)
    }
    
    // MARK: - Playback Control
    
    open func play() {
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
    
    open func pause() {
        guard status == .playing else { return }
        playerNode.pause()
        engine.pause()
    }
    
    open func stop() {
        guard status == .playing || status == .paused else { return }
        playerNode.stop()
        engine.stop()
    }
    
    // MARK: - AudioPlayerNodeDelegate
    
    /// Called by the playerNode when its status changes.
    ///
    /// Override this function in order to react to a status change.
    open func playerNodeStatusDidChange(_ node: AudioPlayerNode, from oldStatus: AudioPlayerNode.Status, to newStatus: AudioPlayerNode.Status) {}
    
    /// Called by the playerNode when the playback is completed.
    open func playerNodePlaybackDidComplete(_ node: AudioPlayerNode) {
        playerNode.segmentStart = 0
        playerNode.segmentEnd = playerNode.duration
        
        if !doesLoop {
            engine.stop()
        }
    }
}

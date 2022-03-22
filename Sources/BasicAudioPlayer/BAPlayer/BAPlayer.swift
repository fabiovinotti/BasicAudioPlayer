//
//  BasicAudioPlayer
//  BAPlayer.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFoundation

/// A base class to create AVAudioEngine-based audio players.
open class BAPlayer: AudioPlayerNodeDelegate {
    
    // MARK: - Properties
    
    public let engine = AVAudioEngine()
    public let playerNode = AudioPlayerNode()
    
    public typealias Status = AudioPlayerNode.Status
    /// The status of the underlying audio player node. It provides information about the playback status.
    public var status: AudioPlayerNode.Status {
        playerNode.status
    }
    
    public var file: AVAudioFile? {
        playerNode.file
    }
    
    public var duration: TimeInterval {
        playerNode.duration
    }
    
    public var doesLoop: Bool {
        get { playerNode.doesLoop }
        set { playerNode.doesLoop = newValue }
    }
    
    public var currentTime: TimeInterval {
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
    
    deinit {
        stop()
    }
    
    // MARK: - Audio File Loaders
    
    public func load(file: AVAudioFile) {
        stop()
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
            log(level: .error, "An error occurred while connecting nodes: No audio file available")
            return
        }
        
        // Disconnect nodes
        engine.disconnectNodeInput(engine.mainMixerNode)
        engine.disconnectNodeInput(engine.outputNode)
        
        // Connecting to mainMixerNode causes the engine to throw -10878.
        // It is apparently harmless.
        // https://stackoverflow.com/questions/69206206/getting-throwing-10878-when-adding-a-source-to-a-mixer
        engine.connect(playerNode.node, to: engine.mainMixerNode, format: format)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: format)
    }
    
    // MARK: - Controlling Playback
    
    public func play() {
        guard status != .noSource else {
            log(level: .error, "No audio file to play. Load an audio file before calling play.")
            return
        }
        
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                log(level: .error, "Failed to start the engine: \(error.localizedDescription)")
            }
        }
        
        playerNode.play()
    }
    
    public func pause() {
        guard status == .playing else {
            log(level: .info, "The player is not playing.")
            return
        }
        
        playerNode.pause()
        engine.pause()
    }
    
    public func stop() {
        guard status == .playing || status == .paused else {
            log(level: .info, "The player is already stopped.")
            return
        }
        
        playerNode.stop()
        engine.stop()
    }
    
    // MARK: - AudioPlayerNodeDelegate
    
    public func playerNodeStatusDidChange(_ node: AudioPlayerNode,
                                          from oldStatus: AudioPlayerNode.Status,
                                          to newStatus: AudioPlayerNode.Status) {}
    
    public func playerNodePlaybackDidComplete(_ node: AudioPlayerNode) {
        playerNode.segmentStart = 0
        playerNode.segmentEnd = playerNode.duration
        
        if !doesLoop {
            engine.stop()
        }
    }
}

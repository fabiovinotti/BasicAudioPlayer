//
//  BasicAudioPlayer
//  BAPlayer.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFoundation

/// A basic audio player built with AVAudioEngine and its accessory elements.
///
/// Under the hood, BAPlayer coordinates an audio engine and an audio player node,
/// so that the two do not need to be managed directly.
///
/// You can add an unlimited number of audio units to the player to affect the audio
/// coming out of the player node.
public class BAPlayer {
    
    // MARK: - Properties
    
    /// The audio engine that drives playback and rendering.
    public let engine = AVAudioEngine()
    
    /// The player node responsible for scheduling and playing audio data.
    public let playerNode = AudioPlayerNode()
    
    public typealias Status = AudioPlayerNode.Status
    
    /// The status of the underlying audio player node.
    public var status: AudioPlayerNode.Status {
        playerNode.status
    }
    
    /// The currently loaded audio file, or `nil` if none is loaded.
    public var file: AVAudioFile? {
        playerNode.file
    }
    
    /// The current playback time, in seconds.
    ///
    /// Setting this property seeks to the specified time.
    public var currentTime: TimeInterval {
        get { playerNode.currentTime }
        set { playerNode.seek(to: newValue) }
    }
    
    /// The total duration of the loaded audio file, in seconds.
    public var duration: TimeInterval {
        playerNode.duration
    }
    
    /// Whether playback restarts when it reaches the end.
    public var doesLoop: Bool {
        get { playerNode.doesLoop }
        set { playerNode.doesLoop = newValue }
    }
    
    /// All audio units added to the player.
    ///
    /// The order reflects the signal chain: the source node of the first unit
    /// is the player node; the destination node of the last unit is the
    /// engine's main mixer node.
    public private(set) var audioUnits: [AVAudioUnit] = []
    
    /// A closure executed when the player node status changes.
    private var onStatusChangeHandler: ((Status) -> Void)?
    
    // MARK: - Creating a Player
    
    /// Creates a player and loads the file at the specified URL.
    ///
    /// - Parameter fileURL: The URL of the audio file to load.
    public convenience init(url fileURL: URL) throws {
        let f = try AVAudioFile(forReading: fileURL)
        self.init(file: f)
    }
    
    /// Creates a player and loads the specified file.
    ///
    /// - Parameter file: The audio file to load.
    public convenience init(file: AVAudioFile) {
        self.init()
        load(file: file)
    }
    
    /// Creates a player.
    public init() {
        playerNode.delegate = self
        engine.attach(playerNode.node)
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Loading Audio Files
    
    /// Loads an audio file from the given URL.
    ///
    /// Stops any current playback, reconfigures the audio graph, and
    /// prepares the engine for playback.
    ///
    /// - Parameter fileURL: The URL of the audio file to load.
    public func load(url fileURL: URL) throws {
        let f = try AVAudioFile(forReading: fileURL)
        load(file: f)
    }
    
    /// Loads an audio file for playback.
    ///
    /// Stops any current playback, reconfigures the audio graph, and
    /// prepares the engine for playback.
    ///
    /// - Parameter file: The audio file to load.
    public func load(file: AVAudioFile) {
        stop()
        playerNode.load(file: file)
        redoConnections()
        playerNode.schedule(at: nil)
        engine.prepare()
    }
    
    // MARK: - Controlling Playback
    
    /// Starts or resumes playback.
    ///
    ///
    /// - Parameter when: The `AVAudioTime` at which to start playback, or `nil` for immediately.
    public func play(at when: AVAudioTime? = nil) {
        guard status != .noSource else {
            log.info("Failed to play: No audio file is loaded.")
            return
        }
        
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                log.error("Failed to start the engine: \(error.localizedDescription)")
            }
        }
        
        playerNode.play(at: when)
    }
    
    /// Pauses playback and the audio engine.
    ///
    /// Does nothing if the player is not currently playing.
    public func pause() {
        guard status == .playing else {
            log.info("Couldn't pause the player: the player is not playing.")
            return
        }
        
        playerNode.pause()
        engine.pause()
    }
    
    /// Stops playback and the audio engine, removing any scheduled events.
    ///
    /// Does nothing when no audio file is loaded.
    public func stop() {
        guard status != .noSource else {
            log.info("Couldn't stop the player: the player is already stopped.")
            return
        }
        
        playerNode.stop()
        engine.stop()
    }
    
    // MARK: - Managing Audio Units
    
    /// Adds an audio unit to the end of the signal chain.
    ///
    /// Stops playback while reconfiguring the audio graph. If a file is loaded,
    /// the new unit is connected between the previous last node and the main
    /// mixer node.
    ///
    /// - Parameter unit: The audio unit to add.
    public func addAudioUnit(_ unit: AVAudioUnit) {
        stop()
        
        audioUnits.append(unit)
        engine.attach(unit)
        
        guard let format = file?.processingFormat else {
            // Nodes are connected when a file is loaded.
            // If no file has been loaded yet, there is no
            // point in connecting the new audio unit.
            return
        }
        
        let mixer = engine.mainMixerNode
        
        guard let inputConnection = engine.inputConnectionPoint(for: mixer, inputBus: 0) else {
            log.error("Nodes are not connected even if a file is loaded.")
            redoConnections() // Try to correct connections.
            return
        }
        
        guard let inputNode = inputConnection.node,
              inputNode !== unit // Node is already connected to mixer.
        else { return }
        
        engine.disconnectNodeInput(mixer, bus: 0)
        engine.connect(inputNode, to: unit, fromBus: inputConnection.bus, toBus: 0, format: format)
        engine.connect(unit, to: mixer, format: format)
    }
    
    // MARK: - Managing Connections
    
    /// Disconnects all audio nodes and then reconnects them.
    private func redoConnections() {
        disconnectNodes()
        connectNodes()
    }
    
    /// Removes all connections between audio nodes.
    private func disconnectNodes() {
        engine.disconnectNodeInput(engine.outputNode)
        engine.disconnectNodeInput(engine.mainMixerNode)
        
        for node in audioUnits {
            engine.disconnectNodeInput(node)
        }
    }
    
    /// Connects all audio nodes in the signal chain.
    private func connectNodes() {
        guard let format = file?.processingFormat else {
            log.error("Failed to connect audio nodes: no audio file is loaded.")
            return
        }
        
        // Connecting to engine.mainMixerNode causes the engine to throw -10878.
        // It is apparently harmless.
        // https://stackoverflow.com/questions/69206206/getting-throwing-10878-when-adding-a-source-to-a-mixer

        let mixer = engine.mainMixerNode

        if audioUnits.isEmpty {
            engine.connect(playerNode.node, to: mixer, format: format)
            engine.connect(mixer, to: engine.outputNode, format: format)
            return
        }
        
        // Player → first unit
        engine.connect(playerNode.node, to: audioUnits[0], format: format)
        
        // Chain audio units together
        for i in 0..<(audioUnits.count - 1) {
            engine.connect(audioUnits[i], to: audioUnits[i + 1], format: format)
        }
        
        // Last unit → mixer → output
        engine.connect(audioUnits[audioUnits.count - 1], to: mixer, format: format)
        engine.connect(mixer, to: engine.outputNode, format: format)
    }
    
    // MARK: - Handling Events

    /// Registers a closure to be called when the player status changes.
    ///
    /// Pass `nil` to remove a previously registered handler.
    ///
    /// - Parameter action: The closure to execute, receiving the new status.
    public func onStatusChange(perform action: ((Status) -> Void)? = nil) {
        onStatusChangeHandler = action
    }

}

// MARK: - AudioPlayerNodeDelegate

extension BAPlayer: AudioPlayerNodeDelegate {

    public func playerNodeStatusDidChange(_ node: AudioPlayerNode,
                                          from oldStatus: AudioPlayerNode.Status,
                                          to newStatus: AudioPlayerNode.Status) {

        onStatusChangeHandler?(newStatus)
    }

    public func playerNodePlaybackDidComplete(_ node: AudioPlayerNode) {
        if !doesLoop {
            engine.stop()
        }
    }

}

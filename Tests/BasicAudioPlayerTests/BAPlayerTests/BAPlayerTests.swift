//
//  BasicAudioPlayer
//  BAPlayerTests.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import XCTest
import AVFoundation
@testable import BasicAudioPlayer

class BAPlayerTests: XCTestCase {
    
    // MARK: - Test Case Setup
    
    private static var audioFile: AVAudioFile!
    
    static override func setUp() {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac")
        else { fatalError("Failed to retrieve audio file URL.") }
                
        do {
            audioFile = try AVAudioFile(forReading: fileURL)
        } catch {
            fatalError("Failed to create audio file: \(error.localizedDescription)")
        }
    }
    
    static override func tearDown() {
        audioFile = nil
    }
    
    // MARK: - Test Load
    
    func testLoadFile_WithURL() throws {
        let player = BAPlayer()
        try player.load(url: Self.audioFile.url)
        try checksForLoad(player: player)
        
        player.play()
        try player.load(url: Self.audioFile.url)
        try checksForLoad(player: player)
        
        player.play()
        player.pause()
        try player.load(url: Self.audioFile.url)
        try checksForLoad(player: player)
    }
    
    func testLoadFile_WithAudioFile() throws {
        let player = BAPlayer()
        player.load(file: Self.audioFile)
        try checksForLoad(player: player)
        
        player.play()
        player.load(file: Self.audioFile)
        try checksForLoad(player: player)
        
        player.play()
        player.pause()
        player.load(file: Self.audioFile)
        try checksForLoad(player: player)
    }
    
    private func checksForLoad(player: BAPlayer) throws {
        let file = try XCTUnwrap(player.file)
        XCTAssertEqual(player.currentTime, 0)
        XCTAssertEqual(player.duration, file.duration)
        XCTAssertEqual(player.status, .ready)
        XCTAssertFalse(player.engine.isRunning)
    }
    
    // MARK: - Test Audio Units
    
    func testAddAudioUnit_beforeLoad() {
        let player = BAPlayer()
        XCTAssert(player.audioUnits.isEmpty)
        
        // Check if unit is added to the array
        let timePitchUnit = AVAudioUnitTimePitch()
        player.addAudioUnit(timePitchUnit)
        XCTAssert(player.audioUnits.count == 1)
        XCTAssert(player.audioUnits[0] === timePitchUnit)
        
        // Check if node are connected
        let engine = player.engine
        guard engine.inputConnectionPoint(for: timePitchUnit, inputBus: 0) == nil else {
            return XCTFail("Node should not be connected until a file is loaded.")
        }
    }
    
    func testAddAudioUnit_afterLoad() {
        let player = BAPlayer()
        player.load(file: Self.audioFile)
        XCTAssert(player.audioUnits.isEmpty)
        
        // Check if unit is added to the array
        let timePitchUnit = AVAudioUnitTimePitch()
        player.addAudioUnit(timePitchUnit)
        XCTAssert(player.audioUnits.count == 1)
        XCTAssert(player.audioUnits[0] === timePitchUnit)
        
        // Check input node
        let engine = player.engine
        guard let inputPoint = engine.inputConnectionPoint(for: timePitchUnit, inputBus: 0) else {
            return XCTFail("Node should be connected.")
        }
        
        guard let inputNode = inputPoint.node else {
            return XCTFail()
        }
        
        XCTAssert(inputNode === player.playerNode.node)
        
        // Check output node
        let outputPoint = engine.outputConnectionPoints(for: timePitchUnit, outputBus: 0)
        guard !outputPoint.isEmpty else {
            return XCTFail("Node should be connected.")
        }
        
        guard let outputNode = outputPoint[0].node else {
            return XCTFail()
        }
        
        XCTAssert(outputNode === engine.mainMixerNode)
    }
    
    // MARK: - Test Graph Reconfiguration
    
    /// The engine may be started before any file is loaded. Loading a file must
    /// stop it before reconfiguring the graph, or AVAudioEngine raises an exception.
    func testLoadFile_WhileEngineIsRunningWithoutSource() throws {
        let player = BAPlayer()
        player.addAudioUnit(AVAudioUnitTimePitch())
        
        XCTAssertEqual(player.status, .noSource)
        try startEngineWithoutSource(of: player)
        
        player.load(file: Self.audioFile)
        try checksForLoad(player: player)
    }
    
    /// Stopping the player must stop the engine even when it has no source,
    /// otherwise the engine is left running with no way to stop it.
    func testStop_WithoutSource_StopsEngine() throws {
        let player = BAPlayer()
        try startEngineWithoutSource(of: player)
        
        player.stop()
        XCTAssertFalse(player.engine.isRunning)
    }
    
    /// Starts the engine of a player that has no audio file loaded, the way a
    /// client would when a play request arrives before a source is available.
    private func startEngineWithoutSource(of player: BAPlayer) throws {
        let engine = player.engine
        
        // A connected mixer is needed for the engine to have a renderable chain.
        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: nil)
        
        engine.prepare()
        try engine.start()
        XCTAssertTrue(engine.isRunning)
    }
    
    // MARK: - Test onStatusChange
    
    func testOnStatusChange() {
        let player = BAPlayer()
        var closureWasExecuted: Bool = false
        
        player.onStatusChange { newStatus in
            XCTAssertEqual(newStatus, player.status)
            closureWasExecuted = true
        }
        
        player.load(file: Self.audioFile)
        XCTAssert(closureWasExecuted)
         
        closureWasExecuted = false
        player.play()
        XCTAssert(closureWasExecuted)
        
        closureWasExecuted = false
        player.pause()
        XCTAssert(closureWasExecuted)
        
        closureWasExecuted = false
        player.stop()
        XCTAssert(closureWasExecuted)
    }
}

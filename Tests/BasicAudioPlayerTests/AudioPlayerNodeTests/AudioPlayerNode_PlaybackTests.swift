//
//  BasicAudioPlayer
//  AudioPlayerNode_PlaybackTests.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import XCTest
import AVFoundation
@testable import BasicAudioPlayer

class AudioPlayerNode_PlaybackTests: XCTestCase {
    
    private var playerNode: AudioPlayerNode!
    private var engine: AVAudioEngine!
    private var audioFile: AVAudioFile!
    
    override func setUpWithError() throws {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac")
        else { fatalError("Failed to retrieve audio file URL.") }
        
        audioFile = try AVAudioFile(forReading: fileURL)
        
        playerNode = AudioPlayerNode()
        
        engine = AVAudioEngine()
        engine.attach(playerNode.node)
        engine.connect(playerNode.node, to: engine.mainMixerNode, format: audioFile.processingFormat)
        try engine.start()
    }
    
    override func tearDownWithError() throws {
        playerNode = nil
        engine = nil
        audioFile = nil
    }
    
    // MARK: - Play Tests
    
    func testPlay_WhenNoFileHasBeenLoaded() {
        playerNode.play()
        XCTAssertEqual(playerNode.status, .noSource)
        XCTAssertFalse(playerNode.node.isPlaying)
    }
    
    func testPlay_WhenFileIsLoadedAndSchedulingIsNeeded() throws {
        playerNode.load(file: audioFile)
        playerNode.play()
        
        XCTAssertFalse(playerNode.needsScheduling)
        XCTAssertEqual(playerNode.status, .playing)
        XCTAssert(playerNode.node.isPlaying)
    }
    
    // MARK: - Pause Tests
    
    func testPause_WhenStopped() {
        playerNode.load(file: audioFile)
        XCTAssertEqual(playerNode.status, .ready)
        XCTAssertFalse(playerNode.node.isPlaying)
        runStopAssertions()
    }
    
    func testPause_WhenPlaying() throws {
        playerNode.load(file: audioFile)
        playerNode.play()
        playerNode.pause()
        XCTAssertEqual(playerNode.status, .paused)
        XCTAssertFalse(playerNode.node.isPlaying)
    }
    
    // MARK: - Stop Tests
    
    func testStop_WhenPlaying() {
        playerNode.load(file: audioFile)
        playerNode.play()
        playerNode.stop()
        runStopAssertions()
    }
    
    func testStop_WhenPaused() {
        playerNode.load(file: audioFile)
        playerNode.play()
        playerNode.pause()
        playerNode.stop()
        runStopAssertions()
    }
    
    private func runStopAssertions() {
        XCTAssertEqual(playerNode.status, .ready)
        XCTAssertFalse(playerNode.node.isPlaying)
    }
}

//
//  BasicAudioPlayer
//  AudioPlayerNodeTests.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import XCTest
import AVFAudio
@testable import BasicAudioPlayer

class AudioPlayerNodeTests: XCTestCase {
    
    // MARK: - Test Case Setup
    
    private static var audioFile: AVAudioFile!
    
    override class func setUp() {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac")
        else { fatalError("Failed to retrieve audio file URL.") }
                
        do {
            audioFile = try AVAudioFile(forReading: fileURL)
        } catch {
            fatalError("Failed to create audio file: \(error.localizedDescription)")
        }
    }
    
    override class func tearDown() {
        audioFile = nil
    }
    
    // MARK: - Single Test Setup
    
    private var playerNode: AudioPlayerNode!
    
    override func setUpWithError() throws {
        playerNode = AudioPlayerNode()
    }

    override func tearDownWithError() throws {
        playerNode = nil
    }
    
    // MARK: - Test Init
    
    func testInit() {
        let node = AudioPlayerNode()
        XCTAssertEqual(node.status, .noSource)
        XCTAssertNil(node.file)
        XCTAssertEqual(node.duration, 0)
        XCTAssertFalse(node.doesLoop)
        XCTAssertEqual(node.playbackSegment, 0...0)
        XCTAssert(node.needsScheduling)
        
        let engine = AVAudioEngine()
        engine.attach(node.node)
        XCTAssertEqual(node.currentTime, 0)
    }
    
    // MARK: - Audio Loading Tests
    
    func testLoadFile_WithURL() throws {
        try playerNode.load(url: Self.audioFile.url)
        runLoadFileAssertions()
    }
    
    func testLoadFile_WithAudioFile() {
        playerNode.load(file: Self.audioFile)
        runLoadFileAssertions()
    }
    
    private func runLoadFileAssertions() {
        XCTAssertNotNil(playerNode.file)
        XCTAssert(playerNode.status == .ready)
        XCTAssert(playerNode.duration == Self.audioFile.duration)
        XCTAssert(playerNode.playbackSegment == 0...Self.audioFile.duration)
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduling_WithoutSegment() throws {
        playerNode.load(file: Self.audioFile)
        
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        playerNode.schedule()
        runSchedulingAssertions(node: playerNode, segment: 0...Self.audioFile.duration)
    }
    
    func testScheduling_WithSegment() throws {
        playerNode.load(file: Self.audioFile)
        
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        playerNode.schedule(segment: 2...3)
        
        runSchedulingAssertions(node: playerNode, segment: 2...3)
    }
    
    private func runSchedulingAssertions(node: AudioPlayerNode, segment: ClosedRange<TimeInterval>) {
        XCTAssertEqual(playerNode.segmentStart, segment.lowerBound)
        XCTAssertEqual(playerNode.segmentEnd, segment.upperBound)
        XCTAssertFalse(playerNode.needsScheduling)
    }
}

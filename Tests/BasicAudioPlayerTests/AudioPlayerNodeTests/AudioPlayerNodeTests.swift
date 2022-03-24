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
    
    private static var audioFileURL: URL!
    private static var audioFile: AVAudioFile!
    
    override class func setUp() {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac")
        else { fatalError("Failed to retrieve audio file URL.") }
        
        audioFileURL = fileURL
        
        do {
            audioFile = try AVAudioFile(forReading: fileURL)
        } catch {
            fatalError("Failed to create audio file: \(error.localizedDescription)")
        }
    }
    
    override class func tearDown() {
        audioFileURL = nil
    }
    
    // MARK: - Single Test Setup
    
    private var playerNode: AudioPlayerNode!
    
    override func setUpWithError() throws {
        playerNode = AudioPlayerNode()
    }

    override func tearDownWithError() throws {
        playerNode = nil
    }
    
    // MARK: - Audio Loading Tests
    
    func testLoadURL() {
        do {
            try playerNode.load(url: Self.audioFileURL)
            postLoadChecks()
        } catch {
            XCTFail("Failed to load audio file from URL: \(error.localizedDescription)")
        }
    }
    
    func testLoadFile() {
        playerNode.load(file: Self.audioFile)
        postLoadChecks()
    }
    
    private func postLoadChecks() {
        XCTAssertNotNil(playerNode.file, "File is nil after a URL load.")
        XCTAssert(playerNode.status == .ready)
        XCTAssert(playerNode.duration == Self.audioFile.duration)
        XCTAssert(playerNode.playbackSegment == 0...Self.audioFile.duration)
    }
    
    // MARK: - Status Tests
    
    func testStatus() {
        XCTAssertTrue(playerNode.status == .noSource,
                      "Status is \(playerNode.status) when it should be \"noSource\".")
        
        playerNode.load(file: Self.audioFile)
        XCTAssertTrue(playerNode.status == .ready,
                      "Status is \(playerNode.status) when it should be \"ready\".")
        
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        engine.connect(playerNode.node, to: engine.mainMixerNode, format: Self.audioFile.processingFormat)
        
        do { try engine.start() }
        catch { XCTFail("Failed to start the engine: \(error.localizedDescription)") }
        
        playerNode.play(at: nil)
        XCTAssertTrue(playerNode.status == .playing,
                      "Status is \(playerNode.status) when it should be \"playing\".")
        
        playerNode.pause()
        XCTAssertTrue(playerNode.status == .paused,
                      "Status is \(playerNode.status) when it should be \"paused\".")
        
        playerNode.stop()
        XCTAssertTrue(playerNode.status == .ready,
                      "Status is \(playerNode.status) when it should be \"ready\".")
    }
    
    // MARK: - CurrentTime Tests
    
    func testCurrentTime() {
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        
        XCTAssert(playerNode.currentTime == 0, "Current time must be 0 when status == .noSource")
        
        playerNode.load(file: Self.audioFile)
        XCTAssert(playerNode.currentTime == 0, "Current time must be 0 after a file has been loaded.")
    }
    
    // MARK: - Scheduling Tests
    
    func testScheduling() {
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        engine.connect(playerNode.node, to: engine.mainMixerNode, format: Self.audioFile.processingFormat)
        
        playerNode.load(file: Self.audioFile)
        playerNode.schedule(segment: nil, at: nil)
        
        var start = playerNode.segmentStart
        var end = playerNode.segmentEnd
        XCTAssertTrue(start == 0 && end == Self.audioFile.duration)
        
        playerNode.schedule(segment: 1...5, at: nil)
        start = playerNode.segmentStart
        end = playerNode.segmentEnd
        XCTAssertTrue(start == 1 && end == 5)
    }
}

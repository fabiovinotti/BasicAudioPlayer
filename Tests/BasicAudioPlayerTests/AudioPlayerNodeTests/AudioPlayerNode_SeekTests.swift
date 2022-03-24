//
//  BasicAudioPlayer
//  AudioPlayerNode_SeekTests.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import XCTest
import AVFAudio
@testable import BasicAudioPlayer

class AudioPlayerNode_SeekTests: XCTestCase {
    
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
    
    private var engine: AVAudioEngine!
    private var playerNode: AudioPlayerNode!
    
    override func setUpWithError() throws {
        engine = AVAudioEngine()
        playerNode = AudioPlayerNode()
        engine.attach(playerNode.node)
        engine.connect(playerNode.node, to: engine.mainMixerNode, format: Self.audioFile.processingFormat)
    }

    override func tearDownWithError() throws {
        engine.detach(playerNode.node)
        playerNode = nil
        engine = nil
    }
    
    // MARK: - Tests
    
    func testSeek_statusNoSource() {
        playerNode.seek(to: 5)
        XCTAssert(playerNode.currentTime == 0, "Current time must be 0 when status == .noSource")
    }
    
    func testSeek_statusReady() {
        playerNode.load(file: Self.audioFile)
        playerNode.seek(to: 5)
        XCTAssert(playerNode.currentTime == 5)
    }
    
    func testSeek_statusPause() {
        do {
            try engine.start()
        } catch {
            XCTFail("Failed to start audio engine: \(error.localizedDescription)")
        }
        
        playerNode.load(file: Self.audioFile)
        playerNode.play(at: nil)
        playerNode.pause()
        XCTAssert(playerNode.status == .paused, "Status is \(playerNode.status) when it should be paused.")
        
        playerNode.seek(to: 5)
        XCTAssert(playerNode.currentTime == 5)
    }
    
    func testSeek_statusPlaying() {
        playerNode.load(file: Self.audioFile)
        
        do {
            try engine.start()
        } catch {
            return XCTFail("Failed to start the audio engine: \(error.localizedDescription)")
        }
        
        playerNode.play(at: nil)
        XCTAssert(playerNode.status == .playing, "Status is \(playerNode.status) when it should be \"playing\".")
        playerNode.seek(to: 5)
        XCTAssert(playerNode.currentTime == 5)
    }
    
    func testSeek_negativeTimeInterval() {
        playerNode.load(file: Self.audioFile)
        playerNode.seek(to: -10)
        XCTAssertTrue(playerNode.currentTime == 0, "Current time must be >= 0.")
        
        do {
            try engine.start()
        } catch {
            return XCTFail("Failed to start the audio engine: \(error.localizedDescription)")
        }
        
        playerNode.play(at: nil)
        playerNode.seek(to: -10)
        XCTAssertTrue(playerNode.currentTime == 0, "Current time must be >= 0.")
        
        playerNode.pause()
        playerNode.seek(to: -10)
        XCTAssertTrue(playerNode.currentTime == 0, "Current time must >= 0.")
        
        playerNode.stop()
        playerNode.seek(to: -10)
        XCTAssertTrue(playerNode.currentTime == 0, "Current time must >= 0.")
    }
}

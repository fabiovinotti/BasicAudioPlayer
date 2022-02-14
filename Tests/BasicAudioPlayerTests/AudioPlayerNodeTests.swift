//
//  AudioPlayerNodeTests.swift
//  BasicAudioPlayerTests
//
//  Created by Fabio Vinotti on 12/02/22.
//

import XCTest
import AVFAudio
@testable import BasicAudioPlayer

class AudioPlayerNodeTests: XCTestCase {

    var playerNode: AudioPlayerNode!
    
    override func setUpWithError() throws {
        playerNode = AudioPlayerNode()
    }

    override func tearDownWithError() throws {
        playerNode = nil
    }

    func testFileLoading() {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac")
        else {
            XCTFail("Failed to retrieve audio file URL.")
            return
        }
        
        do {
            try playerNode.load(url: fileURL)
            XCTAssertNotNil(playerNode.file, "File is nil after a URL load.")
        } catch {
            XCTFail("Failed to load audio file from URL.")
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            playerNode.load(file: audioFile)
            XCTAssertNotNil(playerNode.file, "File is nil after an audio file load.")
        } catch {
            XCTFail("Audio file creation from URL failed.")
            return
        }
    }
    
    func testStatusCorrectness() {
        XCTAssertTrue(playerNode.status == .noSource, "Status should be \"noSource\".")
        
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac")
        else {
            XCTFail("Failed to retrieve audio file URL.")
            return
        }
        
        do {
            try playerNode.load(url: fileURL)
            XCTAssertTrue(playerNode.status == .ready, "Status should be \"ready\".")
        } catch {
            XCTFail("Loading audio from URL failed.")
        }
        
        
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        engine.connect(
            playerNode.node,
            to: engine.mainMixerNode,
            format: playerNode.file!.processingFormat
        )
        
        do {
            try engine.start()
            playerNode.play(at: nil)
            XCTAssertTrue(playerNode.status == .playing, "Status should be \"playing\".")
        } catch {
            XCTFail("Failed to start the engine.")
        }
        
        playerNode.pause()
        XCTAssertTrue(playerNode.status == .paused, "Status should be \"paused\".")
        
        playerNode.stop()
        XCTAssertTrue(playerNode.status == .ready, "Status should be \"ready\".")
    }
    
    func testSeek() {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac"),
              let audioFile = try? AVAudioFile(forReading: fileURL)
        else {
            XCTFail("Failed to create audio file for testing.")
            return
        }
        
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        
        XCTAssertTrue(playerNode.currentTime == 0, "Current time must be 0 when no audio file is available.")
        
        playerNode.load(file: audioFile)
        XCTAssertTrue(playerNode.currentTime == 0, "Current time must be 0 after a file load.")
        
        playerNode.seek(to: 5)
        XCTAssertTrue(playerNode.currentTime == 5, "Current time is not correct.")
        
        playerNode.seek(to: -10)
        XCTAssertTrue(playerNode.currentTime == 0, "Current time must be positive.")
    }
    
    func testScheduling() {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac"),
              let audioFile = try? AVAudioFile(forReading: fileURL)
        else {
            XCTFail("Failed to create audio file for testing.")
            return
        }
        
        do {
            try playerNode.load(url: fileURL)
        } catch {
            XCTFail("Failed to load audio file from URL.")
        }
        
        let engine = AVAudioEngine()
        engine.attach(playerNode.node)
        
        playerNode.schedule(segment: nil, at: nil)
        XCTAssertTrue(playerNode.segmentStart == 0 && playerNode.segmentEnd == audioFile.duration,
                      "The segment is incoherent.")
        
        playerNode.schedule(segment: 1...5, at: nil)
        XCTAssertTrue(playerNode.segmentStart == 1 && playerNode.segmentEnd == 5,
                      "The segment is incoherent.")
    }
}

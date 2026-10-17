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

    // MARK: - Delayed Start Tests

    func testCurrentTime_BeforeDelayedStart_StaysAtSegmentStart() {
        playerNode.load(file: audioFile)
        playerNode.play(at: hostTime(secondsFromNow: 1))
        wait(seconds: 0.5)
        XCTAssertEqual(playerNode.currentTime, 0)
    }

    func testCurrentTime_AfterDelayedStart_CountsFromTheStartOfPlayback() {
        playerNode.load(file: audioFile)
        playerNode.play(at: hostTime(secondsFromNow: 0.5))
        wait(seconds: 1)
        XCTAssertEqual(playerNode.currentTime, 0.5, accuracy: 0.15)
    }

    func testCurrentTime_DelayedStartNearTheEnd_DoesNotReachTheEndEarly() {
        // currentTime used to run ahead by the delay, so it reached the end
        // of the file, and stopped there, while audio was still playing.
        playerNode.load(file: audioFile)
        playerNode.seek(to: audioFile.duration - 2)
        playerNode.play(at: hostTime(secondsFromNow: 1))
        wait(seconds: 2)
        XCTAssertEqual(playerNode.currentTime, audioFile.duration - 1, accuracy: 0.15)
    }

    private func hostTime(secondsFromNow seconds: TimeInterval) -> AVAudioTime {
        AVAudioTime(hostTime: mach_absolute_time() + AVAudioTime.hostTime(forSeconds: seconds))
    }

    /// Waits while letting the engine render in real time.
    private func wait(seconds: TimeInterval) {
        RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
    }
}

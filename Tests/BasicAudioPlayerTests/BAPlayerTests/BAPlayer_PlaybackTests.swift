//
//  BasicAudioPlayer
//  BAPlayer_PlaybackTests.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import XCTest
import AVFoundation
@testable import BasicAudioPlayer

class BAPlayer_PlaybackTests: XCTestCase {
    
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
    
    // MARK: - Single Test Setup
    
    private var player: BAPlayer!

    override func setUpWithError() throws {
        player = BAPlayer()
    }

    override func tearDownWithError() throws {
        player = nil
    }
    
    // MARK: - Test Play
    
    func testPlayBeforeLoading() {
        player.play()
        
        XCTAssertEqual(player.status, .noSource)
        XCTAssertFalse(player.engine.isRunning)
    }
    
    func testPlayWhenStopped() {
        player.load(file: Self.audioFile)
        player.play()
        checksForPlay()
    }
    
    func testPlayWhenPaused() {
        player.load(file: Self.audioFile)
        player.play()
        player.pause()
        player.play()
        checksForPlay()
    }
    
    private func checksForPlay() {
        XCTAssertEqual(player.status, .playing)
        XCTAssert(player.engine.isRunning)
    }
    
    // MARK: - Test Pause
    
    func testPauseBeforeLoading() {
        player.pause()
        XCTAssertFalse(player.engine.isRunning)
        XCTAssertEqual(player.status, .noSource)
    }
    
    func testPauseOnPlaying() {
        player.load(file: Self.audioFile)
        player.play()
        player.pause()
        
        XCTAssertFalse(player.engine.isRunning)
        XCTAssertEqual(player.status, .paused)
    }
    
    func testPauseWhenStopped() {
        player.load(file: Self.audioFile)
        player.pause()
        
        XCTAssertFalse(player.engine.isRunning)
        XCTAssertEqual(player.status, .ready)
    }
    
    // MARK: - Test Stop
    
    func testStopBeforeLoading() {
        player.stop()
        XCTAssertEqual(player.status, .noSource)
        XCTAssertFalse(player.engine.isRunning)
    }
    
    func testStopOnPlaying() {
        player.load(file: Self.audioFile)
        player.play()
        player.stop()
        checksForStop()
    }
    
    func testStopWhenPaused() {
        player.load(file: Self.audioFile)
        player.play()
        player.pause()
        player.stop()
        checksForStop()
    }
    
    private func checksForStop() {
        XCTAssertEqual(player.status, .ready)
        XCTAssertFalse(player.engine.isRunning)
    }
}

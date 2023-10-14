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
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac") else { fatalError("Failed to retrieve audio file URL.")
        }

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

    func testPlay_BeforeLoading() {
        player.play()

        XCTAssertEqual(player.status, .noSource)
        XCTAssertFalse(player.engine.isRunning)
    }

    func testPlay_WhenStopped() {
        player.load(file: Self.audioFile)
        player.play()
        runPlayAssertions()
    }

    func testPlay_WhenPaused() {
        player.load(file: Self.audioFile)
        player.play()
        player.pause()
        player.play()
        runPlayAssertions()
    }

    private func runPlayAssertions() {
        XCTAssertEqual(player.status, .playing)
        XCTAssert(player.engine.isRunning)
    }

    // MARK: - Test Pause

    func testPause_BeforeLoading() {
        player.pause()
        XCTAssertFalse(player.engine.isRunning)
        XCTAssertEqual(player.status, .noSource)
    }

    func testPause_WhenPlaying() {
        player.load(file: Self.audioFile)
        player.play()
        player.pause()

        XCTAssertFalse(player.engine.isRunning)
        XCTAssertEqual(player.status, .paused)
    }

    func testPause_WhenStopped() {
        player.load(file: Self.audioFile)
        player.pause()

        XCTAssertFalse(player.engine.isRunning)
        XCTAssertEqual(player.status, .ready)
    }

    // MARK: - Test Stop

    func testStop_BeforeLoading() {
        player.stop()
        XCTAssertEqual(player.status, .noSource)
        XCTAssertFalse(player.engine.isRunning)
    }

    func testStop_AfterLoading() {
        player.load(file: Self.audioFile)
        player.stop()
        checksForStop()
    }

    func testStop_WhenPlaying() {
        player.load(file: Self.audioFile)
        player.play()
        player.stop()
        checksForStop()
    }

    func testStop_WhenPaused() {
        player.load(file: Self.audioFile)
        player.play()
        player.pause()
        player.stop()
        checksForStop()
    }

    private func checksForStop() {
        XCTAssertEqual(player.status, .ready)
        XCTAssertFalse(player.engine.isRunning)
        XCTAssertNotNil(player.file)
    }
}

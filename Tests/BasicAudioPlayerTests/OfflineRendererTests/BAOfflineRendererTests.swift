//
//  BasicAudioPlayer
//  BAOfflineRendererTests.swift
//
//  Copyright © 2026 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import XCTest
import AVFoundation
@testable import BasicAudioPlayer

class BAOfflineRendererTests: XCTestCase {

    // MARK: - Test Case Setup

    private static var sourceURL: URL!

    private var destinationURL: URL!

    static override func setUp() {
        guard let fileURL = Bundle.module.url(forResource: "audio-sample", withExtension: "aac")
        else { fatalError("Failed to retrieve audio file URL.") }

        sourceURL = fileURL
    }

    static override func tearDown() {
        sourceURL = nil
    }

    override func setUp() {
        destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("caf")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: destinationURL)
        destinationURL = nil
    }

    // MARK: - Tests

    func testRender_atDoubleRate_consumesTheSourceTwiceAsFast() throws {
        // Starting 12 s before the end of the fixture, which is loud up to there,
        // leaves 6 s of output at 2×. Rendering 9 s must give audio up to there
        // and silence after it; at 1× the whole 9 s would be audio.
        let source = try AVAudioFile(forReading: Self.sourceURL)
        let sourceDuration = Double(source.length) / source.processingFormat.sampleRate

        let configuration = BAOfflineRenderer.Configuration(
            sourceURL: Self.sourceURL,
            sourceStartTime: sourceDuration - 12,
            outputDuration: 9,
            makeAudioUnits: {
                let timePitch = AVAudioUnitTimePitch()
                timePitch.rate = 2
                return [timePitch]
            }
        )

        let sampleRate = try render(configuration)

        let output = try AVAudioFile(forReading: destinationURL)
        XCTAssertEqual(output.length, AVAudioFramePosition(9 * sampleRate))
        XCTAssertGreaterThan(try peak(of: output, in: 5..<5.5), 0.01, "The source ran out too early.")
        XCTAssertLessThan(try peak(of: output, in: 7.5..<9), 0.0001, "The source wasn't consumed at 2×.")
    }

    func testRender_withoutAudioUnits_producesTheRequestedLength() throws {
        let configuration = BAOfflineRenderer.Configuration(
            sourceURL: Self.sourceURL,
            outputDuration: 3
        )

        let sampleRate = try render(configuration)

        let output = try AVAudioFile(forReading: destinationURL)
        XCTAssertEqual(output.length, AVAudioFramePosition(3 * sampleRate))
        XCTAssertGreaterThan(try peak(of: output), 0.01, "The rendered audio is silent.")
    }

    func testRender_reportsIncreasingProgressEndingAtOne() throws {
        let configuration = BAOfflineRenderer.Configuration(
            sourceURL: Self.sourceURL,
            outputDuration: 2
        )

        var progressValues: [Double] = []
        try render(configuration) { progressValues.append($0) }

        XCTAssertFalse(progressValues.isEmpty)
        XCTAssertEqual(progressValues, progressValues.sorted())
        XCTAssertEqual(try XCTUnwrap(progressValues.last), 1, accuracy: 0.0001)
    }

    func testRender_inCancelledTask_throwsCancellationError() async throws {
        let configuration = BAOfflineRenderer.Configuration(
            sourceURL: Self.sourceURL,
            outputDuration: 10
        )
        let destination = try makeDestination()

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try BAOfflineRenderer(configuration: configuration).render(to: destination)
        }

        do {
            try await task.value
            XCTFail("Rendering should have been cancelled.")
        } catch {
            XCTAssertTrue(error is CancellationError, "Unexpected error: \(error)")
        }
    }

    func testRender_startTimePastTheEnd_throwsInvalidRegionBounds() throws {
        let configuration = BAOfflineRenderer.Configuration(
            sourceURL: Self.sourceURL,
            sourceStartTime: 10_000,
            outputDuration: 1
        )

        XCTAssertThrowsError(try render(configuration)) { error in
            guard case BAPError.renderingInvalidRegionBounds = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testRender_nonPositiveDuration_throwsInvalidRegionBounds() throws {
        let configuration = BAOfflineRenderer.Configuration(
            sourceURL: Self.sourceURL,
            outputDuration: 0
        )

        XCTAssertThrowsError(try render(configuration)) { error in
            guard case BAPError.renderingInvalidRegionBounds = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testRender_nonFiniteStartTime_throwsInvalidRegionBounds() throws {
        for startTime in [TimeInterval.nan, .infinity, -.infinity, 1e300] {
            let configuration = BAOfflineRenderer.Configuration(
                sourceURL: Self.sourceURL,
                sourceStartTime: startTime,
                outputDuration: 1
            )

            XCTAssertThrowsError(try render(configuration), "Start time: \(startTime)") { error in
                guard case BAPError.renderingInvalidRegionBounds = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }

    func testRender_nonFiniteDuration_throwsInvalidRegionBounds() throws {
        for duration in [TimeInterval.nan, .infinity, 1e300] {
            let configuration = BAOfflineRenderer.Configuration(
                sourceURL: Self.sourceURL,
                outputDuration: duration
            )

            XCTAssertThrowsError(try render(configuration), "Duration: \(duration)") { error in
                guard case BAPError.renderingInvalidRegionBounds = error else {
                    return XCTFail("Unexpected error: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    /// Renders to ``destinationURL`` and closes the file.
    ///
    /// - Returns: The sample rate of the rendered output.
    @discardableResult
    private func render(_ configuration: BAOfflineRenderer.Configuration,
                        progressHandler: BAOfflineRenderer.ProgressHandler? = nil) throws -> Double {

        // The destination is closed when it goes out of scope, which flushes it to disk.
        let destination = try makeDestination()
        try BAOfflineRenderer(configuration: configuration).render(to: destination, progressHandler: progressHandler)
        return destination.processingFormat.sampleRate
    }

    private func makeDestination() throws -> AVAudioFile {
        let source = try AVAudioFile(forReading: Self.sourceURL)
        return try AVAudioFile(forWriting: destinationURL, settings: source.processingFormat.settings)
    }

    /// The largest absolute sample value in the file, optionally within a time range in seconds.
    private func peak(of file: AVAudioFile, in range: Range<TimeInterval>? = nil) throws -> Float {
        let sampleRate = file.processingFormat.sampleRate
        let start = range.map { AVAudioFramePosition($0.lowerBound * sampleRate) } ?? 0
        let end = range.map { min(AVAudioFramePosition($0.upperBound * sampleRate), file.length) } ?? file.length

        let buffer = try XCTUnwrap(AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(end - start)
        ))
        file.framePosition = start
        try file.read(into: buffer, frameCount: AVAudioFrameCount(end - start))

        let channels = try XCTUnwrap(buffer.floatChannelData)
        var peak: Float = 0

        for channel in 0..<Int(buffer.format.channelCount) {
            for frame in 0..<Int(buffer.frameLength) {
                peak = max(peak, abs(channels[channel][frame]))
            }
        }

        return peak
    }

}

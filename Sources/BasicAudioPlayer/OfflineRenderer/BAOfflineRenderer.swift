//
//  BasicAudioPlayer
//  BAOfflineRenderer.swift
//
//  Copyright © 2026 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFoundation

/// Renders an audio file through a chain of audio units, on an audio engine of its own.
///
/// Unlike ``BAPlayer/render(to:startTime:duration:progressHandler:)``, the renderer
/// never touches a player's engine: every call to ``render(to:progressHandler:)``
/// builds a fresh `AVAudioEngine`, so playback can carry on while a file is rendered.
///
/// Rendering is synchronous and runs on the caller's thread. Call it from a
/// background task to keep the main thread free. It doesn't need an active
/// `AVAudioSession`.
public struct BAOfflineRenderer: Sendable {

    /// What to render, and how.
    public struct Configuration: Sendable {

        /// The URL of the audio file to render.
        public var sourceURL: URL

        /// The point of the source file where rendering starts, in seconds.
        public var sourceStartTime: TimeInterval

        /// The length of the rendered output, in seconds.
        ///
        /// When an audio unit changes the playback rate, this differs from the
        /// length of source audio consumed: rendering 10 seconds of source through
        /// a 2× time-pitch unit produces 5 seconds of output.
        public var outputDuration: TimeInterval

        /// The pan of the player node, from -1 (left) to 1 (right).
        public var pan: Float

        /// The maximum number of frames rendered in one chunk.
        public var maximumFrameCount: AVAudioFrameCount

        /// Creates the audio units the source passes through, in signal-chain order.
        ///
        /// Called once per render, so each render gets units of its own. Capture
        /// plain values in the closure and configure the units from those.
        public var makeAudioUnits: @Sendable () -> [AVAudioUnit]

        /// Creates a render configuration.
        ///
        /// - Parameters:
        ///   - sourceURL: The URL of the audio file to render.
        ///   - sourceStartTime: The point of the source file where rendering starts, in seconds.
        ///   - outputDuration: The length of the rendered output, in seconds.
        ///   - pan: The pan of the player node, from -1 (left) to 1 (right).
        ///   - maximumFrameCount: The maximum number of frames rendered in one chunk.
        ///   - makeAudioUnits: Creates the audio units the source passes through.
        public init(sourceURL: URL,
                    sourceStartTime: TimeInterval = 0,
                    outputDuration: TimeInterval,
                    pan: Float = 0,
                    maximumFrameCount: AVAudioFrameCount = 4096,
                    makeAudioUnits: @escaping @Sendable () -> [AVAudioUnit] = { [] }) {

            self.sourceURL = sourceURL
            self.sourceStartTime = sourceStartTime
            self.outputDuration = outputDuration
            self.pan = pan
            self.maximumFrameCount = maximumFrameCount
            self.makeAudioUnits = makeAudioUnits
        }
    }

    /// The handler called as rendering progresses, with a value in `0.0...1.0`.
    public typealias ProgressHandler = (Double) -> Void

    /// What to render, and how.
    public let configuration: Configuration

    /// Creates a renderer.
    ///
    /// - Parameter configuration: What to render, and how.
    public init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Rendering

    /// Renders the configured audio to a file.
    ///
    /// The output is rendered in the destination file's processing format.
    /// If the source runs out before ``Configuration/outputDuration`` is reached,
    /// the rest of the output is silence.
    ///
    /// When called from a task, cancellation is checked between chunks.
    ///
    /// If rendering is cancelled or fails partway through, the chunks already
    /// written stay in `destinationFile`. Delete the file if a truncated render
    /// is of no use.
    ///
    /// - Parameters:
    ///   - destinationFile: The output file, initialized for writing.
    ///   - progressHandler: Called on the caller's thread after each chunk.
    /// - Throws: `CancellationError` if the current task is cancelled;
    ///   ``BAPError`` if the region is invalid or rendering fails; any error
    ///   thrown while reading the source or writing the destination.
    public func render(to destinationFile: AVAudioFile,
                       progressHandler: ProgressHandler? = nil) throws {

        let source = try AVAudioFile(forReading: configuration.sourceURL)
        let engine = AVAudioEngine()

        try engine.enableManualRenderingMode(
            .offline,
            format: destinationFile.processingFormat,
            maximumFrameCount: configuration.maximumFrameCount
        )

        let startFrames = (configuration.sourceStartTime * source.processingFormat.sampleRate).rounded()
        let outputFrames = (configuration.outputDuration * engine.manualRenderingFormat.sampleRate).rounded()

        // Checked before converting to frame positions: converting NaN, an
        // infinity or an out-of-range value to an integer would crash.
        guard startFrames >= 0,
              startFrames < Double(source.length),
              configuration.outputDuration > 0,
              outputFrames < Double(AVAudioFramePosition.max)
        else {
            throw BAPError.renderingInvalidRegionBounds
        }

        let startFrame = AVAudioFramePosition(startFrames)
        let totalFrames = AVAudioFramePosition(outputFrames)

        let playerNode = AVAudioPlayerNode()
        playerNode.pan = configuration.pan
        connect(playerNode, through: configuration.makeAudioUnits(), in: engine, format: source.processingFormat)

        playerNode.scheduleSegment(
            source,
            startingFrame: startFrame,
            frameCount: AVAudioFrameCount(source.length - startFrame),
            at: nil
        )

        try engine.start()
        defer { engine.stop() }

        playerNode.play()

        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: engine.manualRenderingFormat,
            frameCapacity: engine.manualRenderingMaximumFrameCount
        ) else {
            throw BAPError.renderingBufferCreationFailed
        }

        while engine.manualRenderingSampleTime < totalFrames {
            try Task.checkCancellation()

            let remainingFrames = totalFrames - engine.manualRenderingSampleTime
            let framesToRender = AVAudioFrameCount(min(remainingFrames, AVAudioFramePosition(buffer.frameCapacity)))

            switch try engine.renderOffline(framesToRender, to: buffer) {
            case .success:
                try destinationFile.write(from: buffer)
                progressHandler?(Double(engine.manualRenderingSampleTime) / Double(totalFrames))

            case .error, .insufficientDataFromInputNode, .cannotDoInCurrentContext:
                // The last two can't happen in offline mode without an input
                // node. Retrying would loop forever, so treat them as failures.
                throw BAPError.renderingUnknownError

            @unknown default:
                throw BAPError.renderingUnknownError
            }
        }
    }

    // MARK: - Private

    /// Attaches the nodes and connects them: player → units → main mixer.
    private func connect(_ playerNode: AVAudioPlayerNode,
                         through audioUnits: [AVAudioUnit],
                         in engine: AVAudioEngine,
                         format: AVAudioFormat) {

        let chain: [AVAudioNode] = [playerNode] + audioUnits

        for node in chain {
            engine.attach(node)
        }

        for (upstream, downstream) in zip(chain, chain.dropFirst()) {
            engine.connect(upstream, to: downstream, format: format)
        }

        engine.connect(chain[chain.count - 1], to: engine.mainMixerNode, format: format)
    }

}

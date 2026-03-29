//
//  BasicAudioPlayer
//  BAPlayer+Rendering.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFoundation

extension BAPlayer {
    
    /// The handler called when the rendering progresses.
    ///
    /// The progress handler receives a value representing the progress of the rendering operation.
    /// This value can range from a minimum of 0.0 to a maximum of 1.0.
    /// A value of 1.0 indicates that the rendering is complete.
    public typealias ProgressHandler = (Double) -> Void
    
    /// Renders the specified portion of the player's audio to an AVAudioFile.
    ///
    /// - Parameters:
    ///   - destinationFile: The output file, initialized for writing.
    ///   - region: The closed time range (in seconds) to render.
    ///   - progressHandler: A closure called with a value in `0.0...1.0` as rendering progresses.
    /// - Throws: ``BAPError`` if no source is loaded, region is invalid, or rendering fails.
    ///
    public func render(to destinationFile: AVAudioFile,
                       region: ClosedRange<TimeInterval>,
                       progressHandler: ProgressHandler? = nil) throws {
        
        try render(
            to: destinationFile,
            startTime: region.lowerBound,
            duration: region.upperBound - region.lowerBound,
            progressHandler: progressHandler
        )
    }
    
    /// Renders the player's audio to an AVAudioFile.
    ///
    /// Stops any current playback and puts the engine into offline manual-rendering
    /// mode for the duration of the operation. After rendering, the engine is stopped
    /// and returned to normal mode.
    ///
    /// - Parameters:
    ///   - destinationFile: The output file, initialized for writing.
    ///   - startTime: The starting point of the rendering, in seconds. Defaults to `0`.
    ///   - duration: The number of seconds to render. Pass `nil` to render to the end of the file.
    ///   - progressHandler: A closure called with a value in `0.0...1.0` as rendering progresses.
    /// - Throws: ``BAPError`` if no source is loaded, region is invalid, or rendering fails.
    ///
    public func render(to destinationFile: AVAudioFile,
                       startTime: TimeInterval = 0,
                       duration: TimeInterval? = nil,
                       progressHandler: ProgressHandler? = nil) throws {
        
        guard status != .noSource else {
            throw BAPError.renderingNoSourceLoaded
        }
        
        let duration = duration ?? self.duration - startTime
        
        guard startTime >= 0 && duration > 0 else {
            throw BAPError.renderingInvalidRegionBounds
        }
        
        playerNode.stop()
        engine.stop()
        
        try engine.enableManualRenderingMode(
            .offline,
            format: destinationFile.processingFormat,
            maximumFrameCount: 4096
        )
        
        playerNode.seek(to: startTime)
        playerNode.schedule()
        try engine.start()
        playerNode.play()
        
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: engine.manualRenderingFormat,
            frameCapacity: engine.manualRenderingMaximumFrameCount
        ) else {
            throw BAPError.renderingBufferCreationFailed
        }
        
        let renderingSampleRate = engine.manualRenderingFormat.sampleRate
        let totalFrames = AVAudioFramePosition(duration * renderingSampleRate)
        
        while engine.manualRenderingSampleTime < totalFrames {
            let remainingFrames = UInt32(totalFrames - engine.manualRenderingSampleTime)
            let framesToRender = min(remainingFrames, buffer.frameCapacity)
            let status = try engine.renderOffline(framesToRender, to: buffer)
            
            switch status {
            case .error:
                throw BAPError.renderingUnknownError
                
            case .success:
                try destinationFile.write(from: buffer)
                let progress = Double(engine.manualRenderingSampleTime) / Double(totalFrames)
                progressHandler?(progress)
                
            case .insufficientDataFromInputNode:
                throw BAPError.renderingUnknownError
                
            case .cannotDoInCurrentContext:
                log.error("System can’t perform in current context")
                
            @unknown default:
                fatalError("Unknown manual rendering status returned")
            }
        }
        
        playerNode.stop()
        engine.stop()
        engine.disableManualRenderingMode()
    }
    
}

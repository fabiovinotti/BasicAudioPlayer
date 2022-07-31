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
    /// - parameter destinationFile: The rendering operation output file. Initialize it for writing.
    /// - parameter region: The audio region to render.
    /// - parameter progressHandler: A closure called every time the rendering progresses.
    ///
    public func render(to destinationFile: AVAudioFile,
                       region: ClosedRange<TimeInterval>,
                       progressHandler: @escaping ProgressHandler) throws {
        
        let renderingDuration = region.upperBound - region.lowerBound
        
        guard region.lowerBound >= 0 && renderingDuration > 0 else {
            throw BAPError.renderingInvalidRegion
        }
        
        guard status != .noSource else {
            throw BAPError.renderingNoSourceLoaded
        }
        
        playerNode.stop()
        engine.stop()
        
        try engine.enableManualRenderingMode(
            .offline,
            format: destinationFile.processingFormat,
            maximumFrameCount: 4096
        )
        
        playerNode.seek(to: region.lowerBound)
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
        let totalSamples = AVAudioFramePosition(renderingDuration * renderingSampleRate)
        
        while engine.manualRenderingSampleTime < totalSamples {
            let remainingFrames = UInt32(totalSamples - engine.manualRenderingSampleTime)
            let framesToRender = min(remainingFrames, buffer.frameCapacity)
            let status = try engine.renderOffline(framesToRender, to: buffer)
            
            switch status {
            case .error:
                throw BAPError.renderingUnknownError
                
            case .success:
                try destinationFile.write(from: buffer)
                let progress = Double(engine.manualRenderingSampleTime) / Double(totalSamples)
                progressHandler(progress)
                
            case .insufficientDataFromInputNode:
                throw BAPError.renderingUnknownError
                
            case .cannotDoInCurrentContext:
                log(level: .error, "System can’t perform in current context")
                
            @unknown default:
                fatalError("Unknown manual rendering status returned")
            }
        }
        
        playerNode.stop()
        engine.stop()
        engine.disableManualRenderingMode()
    }
    
}

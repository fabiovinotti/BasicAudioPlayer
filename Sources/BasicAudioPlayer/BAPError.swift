//
//  BasicAudioPlayer
//  BAPError.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

public enum BAPError: Error {
/// Errors that can occur during BAPlayer operations.
    
    /// The rendering region has invalid start time or duration.
    case renderingInvalidRegionBounds
    
    /// No audio file is loaded to render.
    case renderingNoSourceLoaded
    
    /// The PCM buffer for offline rendering could not be allocated.
    case renderingBufferCreationFailed
    
    /// An unspecified error occurred during offline rendering.
    case renderingUnknownError
    
    public var description: String {
        switch self {
        case .renderingInvalidRegionBounds:
            return "The rendering region bounds are invalid"
            
        case .renderingNoSourceLoaded:
            return "No audio file is loaded"
            
        case .renderingBufferCreationFailed:
            return "Buffer creation failed"
            
        case .renderingUnknownError:
            return "A problem occurred during rendering and resulted in no data being returned"
        }
    }
    
}

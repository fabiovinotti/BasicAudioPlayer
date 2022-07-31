//
//  BasicAudioPlayer
//  BAPError.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

public enum BAPError: Error {
    
    case renderingInvalidRegion
    case renderingNoSourceLoaded
    case renderingBufferCreationFailed
    case renderingUnknownError
    
    public var description: String {
        switch self {
        case .renderingInvalidRegion:
            return "The rendering region is invalid."
            
        case .renderingNoSourceLoaded:
            return "No audio file is loaded"
            
        case .renderingBufferCreationFailed:
            return "Buffer creation failed"
            
        case .renderingUnknownError:
            return "A problem occurred during rendering and resulted in no data being returned"
        }
    }
    
}

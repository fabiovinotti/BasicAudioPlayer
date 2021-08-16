//
//  BAPlayer+Status.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import Foundation

extension BAPlayer {
    
    /// The operations a player might undertake.
    public enum Status {
        
        /// The player is stopped.
        case ready
        
        /// The player is playing.
        case playing
        
        /// The player is paused.
        case paused
    }
    
}

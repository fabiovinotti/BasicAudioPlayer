//
//  AudioPlayer+Status.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import Foundation

extension AudioPlayer {
    
    public enum Status {
        
        /// Ready to start playing.
        case ready
        
        /// The player is playing.
        case playing
        
        /// The player is paused.
        case paused
    }
    
}

//
//  AudioPlayerNode+Status.swift
//  
//
//  Created by Fabio Vinotti on 26/11/21.
//

import Foundation

extension AudioPlayerNode {
    
    /// The operations that a player node might undertake.
    public enum Status {
        
        /// The player has no audio source to play.
        case noSource
        
        /// The player is stopped and ready to play.
        case ready
        
        /// The player is playing.
        case playing
        
        /// The player is paused.
        case paused
    }
    
}

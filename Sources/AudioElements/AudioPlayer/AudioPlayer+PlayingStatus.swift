//
//  AudioPlayer+PlaybackStatus.swift
//  
//
//  Created by Fabio Vinotti on 9/18/20.
//

import Foundation

extension AudioPlayer {
    
    public enum PlaybackStatus {
        
        /// Ready to start playing.
        case ready
        
        /// The player is playing.
        case playing
        
        /// The player is paused.
        case paused
    }
    
}

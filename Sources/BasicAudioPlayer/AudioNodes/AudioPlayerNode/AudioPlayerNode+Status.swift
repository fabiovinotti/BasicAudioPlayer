//
//  BasicAudioPlayer
//  AudioPlayerNode+Status.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

extension AudioPlayerNode {
    
    /// The playback state of an ``AudioPlayerNode``.
    public enum Status: Sendable, Hashable {
        
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

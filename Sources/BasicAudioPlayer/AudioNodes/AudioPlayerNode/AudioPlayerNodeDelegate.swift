//
//  BasicAudioPlayer
//  AudioPlayerNodeDelegate.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// A protocol that describes the methods to responds to playback events.
public protocol AudioPlayerNodeDelegate: AnyObject {
        
    func playerNodeStatusDidChange(_ node: AudioPlayerNode, from oldStatus: AudioPlayerNode.Status, to newStatus: AudioPlayerNode.Status)
    
    func playerNodePlaybackDidComplete(_ node: AudioPlayerNode)
}

//
//  AudioPlayerNodeDelegate.swift
//  
//
//  Created by Fabio Vinotti on 01/01/22.
//

import Foundation

/// A protocol that describes the methods to responds to playback events.
public protocol AudioPlayerNodeDelegate: AnyObject {
        
    func playerNodeStatusDidChange(_ node: AudioPlayerNode, from oldStatus: AudioPlayerNode.Status, to newStatus: AudioPlayerNode.Status)
    
    func playerNodePlaybackDidComplete(_ node: AudioPlayerNode)
}

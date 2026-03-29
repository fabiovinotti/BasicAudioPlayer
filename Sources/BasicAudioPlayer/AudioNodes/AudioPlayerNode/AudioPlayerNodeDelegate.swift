//
//  BasicAudioPlayer
//  AudioPlayerNodeDelegate.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

/// A protocol for responding to ``AudioPlayerNode`` playback events.
public protocol AudioPlayerNodeDelegate: AnyObject {
    
    /// Called when the player node's status changes.
    ///
    /// - Parameters:
    ///   - node: The player node whose status changed.
    ///   - oldStatus: The status before the change.
    ///   - newStatus: The current status.
    func playerNodeStatusDidChange(_ node: AudioPlayerNode,
                                   from oldStatus: AudioPlayerNode.Status,
                                   to newStatus: AudioPlayerNode.Status)
    
    /// Called when the scheduled audio has been completely played back.
    ///
    /// - Parameter node: The player node that completed playback.
    func playerNodePlaybackDidComplete(_ node: AudioPlayerNode)
}

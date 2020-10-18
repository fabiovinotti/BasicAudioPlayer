//
//  AudioPlayerDelegate.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import Foundation

public protocol AudioPlayerDelegate {
    
    func audioPlayer(_ player: AudioPlayer, statusChangedFrom oldStatus: AudioPlayer.Status, to newStatus: AudioPlayer.Status)
    
}

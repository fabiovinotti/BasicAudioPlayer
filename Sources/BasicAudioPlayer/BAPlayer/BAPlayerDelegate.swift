//
//  BAPlayerDelegate.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import Foundation

public protocol BAPlayerDelegate {
    
    func audioPlayer(_ player: BAPlayer, statusChangedFrom oldStatus: BAPlayer.Status, to newStatus: BAPlayer.Status)
    
}

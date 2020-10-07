//
//  NowPlayableItem.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import Foundation
import MediaPlayer

public protocol NowPlayableItem {
    
    var assetURL: URL { get }
    
    var mediaType: MPNowPlayingInfoMediaType { get }
    
    var isLiveStream: Bool { get }
    
    var title: String? { get }
    
    var artist: String? { get }
    
    var albumTitle: String? { get }
    
    var albumArtist: String? { get }
    
    var artwork: MPMediaItemArtwork? { get }
    
    var duration: TimeInterval? { get }
    
}

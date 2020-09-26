//
//  NowPlayable.swift
//
//
//  Created by Fabio Vinotti on 8/18/20.
//

import Foundation
import MediaPlayer
import Combine

public protocol NowPlayable: class {
    
    var enabledRemoteCommands: [RemoteCommand: RemoteCommand.CommandHandler] { get }
    
    var disabledRemoteCommands: [RemoteCommand] { get }
    
    func activateAudioSession() throws
    
    func deactivateAudioSession() throws

}

// MARK: - Remote Commands Management
extension NowPlayable {
    
    public func enableRemoteCommands() {
        
        for var command in RemoteCommand.allCases {
            
            command.removeHandler()
            
            if let handler = enabledRemoteCommands[command] {
                command.addHandler(handler)
            }
            else if disabledRemoteCommands.contains(command) {
                command.isEnabled = false
            }
            
        }
        
    }
    
}

//MARK: - Now Playing Info Management
extension NowPlayable {
        
    /// Sets the now playing info extracted from a NowPlayableItem.
    public func setNowPlayingInfo(from item: NowPlayableItem) {
        
        var info: [String: Any] = .init()
        
        info[MPMediaItemPropertyAssetURL] = item.assetURL
        info[MPMediaItemPropertyMediaType] = item.mediaType.rawValue
        info [MPNowPlayingInfoPropertyIsLiveStream] = item.isLiveStream
                
        if let title = item.title {
            info[MPMediaItemPropertyTitle] = title
        }
        
        if let artist = item.artist {
            info[MPMediaItemPropertyArtist] = artist
        }
        
        if let albumTitle = item.albumTitle {
            info[MPMediaItemPropertyAlbumTitle] = albumTitle
        }
        
        if let albumArtist = item.albumArtist {
            info[MPMediaItemPropertyAlbumArtist] = albumArtist
        }
        
        if let artwork = item.artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        if let duration = item.duration {
            info[MPMediaItemPropertyPlaybackDuration] = NSNumber(floatLiteral: duration)
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    public func setPlaybackInfo(playbackRate: Float, playbackTime: Float) {
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var info = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackTime
        
        nowPlayingInfoCenter.nowPlayingInfo = info
    }
    
    public func updateNowPlayingInfo(playbackTime: Float) {
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        if var info = nowPlayingInfoCenter.nowPlayingInfo {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playbackTime
            nowPlayingInfoCenter.nowPlayingInfo = info
        }
        
    }
    
    public func updateNowPlayingInfo(playbackRate: Float) {
        
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        
        if var info = nowPlayingInfoCenter.nowPlayingInfo {
            info[MPNowPlayingInfoPropertyPlaybackRate] = playbackRate
            nowPlayingInfoCenter.nowPlayingInfo = info
        }
        
    }
    
}

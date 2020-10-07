//
//  RemoteCommand.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import Foundation
import MediaPlayer

public enum RemoteCommand: CaseIterable {
    
    case play, pause, stop, togglePlayPause
    case previousTrack, nextTrack
    case skipBackward, skipForward
    case changePlaybackPosition
    
    public var isEnabled: Bool {
        get { remoteCommand.isEnabled }
        set { remoteCommand.isEnabled = newValue }
    }
    
    public var remoteCommand: MPRemoteCommand {
        
        let rcc = MPRemoteCommandCenter.shared()
        
        switch self {
        
        case .play:
            return rcc.playCommand
            
        case .pause:
            return rcc.pauseCommand
            
        case .stop:
            return rcc.stopCommand
            
        case .togglePlayPause:
            return rcc.togglePlayPauseCommand
            
        case .previousTrack:
            return rcc.previousTrackCommand
            
        case .nextTrack:
            return rcc.nextTrackCommand
            
        case .changePlaybackPosition:
            return rcc.changePlaybackPositionCommand
            
        case .skipBackward:
            return rcc.skipBackwardCommand
            
        case .skipForward:
            return rcc.skipForwardCommand
            
        }
    }
    
    public typealias CommandHandler = (MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    
    public func addHandler(_ handler: @escaping CommandHandler) {
        
        remoteCommand.addTarget(handler: handler)
        
    }
    
    public func removeHandler() {
        remoteCommand.removeTarget(nil)
    }

}

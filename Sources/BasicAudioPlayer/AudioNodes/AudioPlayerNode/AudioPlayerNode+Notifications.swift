//
//  AudioPlayerNode+Notifications.swift
//  
//
//  Created by Fabio Vinotti on 01/01/22.
//

import Foundation

extension AudioPlayerNode {
    
    static let playbackCompletionNotification = Notification.Name("playerNodePlaybackCompletion")
    
    static let statusDidChangeNotification = Notification.Name("playerNodeStatusDidChange")
    
}

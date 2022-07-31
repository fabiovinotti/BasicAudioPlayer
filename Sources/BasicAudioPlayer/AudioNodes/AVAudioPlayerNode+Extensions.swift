//
//  BasicAudioPlayer
//  AVAudioPlayerNode+Extensions.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFoundation
import Combine

extension AVAudioPlayerNode {
    
    public var playerTime: AVAudioTime? {
        var playerTime: AVAudioTime? = nil
        
        if let nodeTime = lastRenderTime, nodeTime.isSampleTimeValid {
            playerTime = self.playerTime(forNodeTime: nodeTime)
        }
        
        return playerTime
    }
    
}

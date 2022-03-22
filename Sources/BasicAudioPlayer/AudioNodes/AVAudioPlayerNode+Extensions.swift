//
//  AVAudioPlayerNode+Extensions.swift
//  
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import AVFoundation
import Combine

extension AVAudioPlayerNode {
    
    public var playerTime: AVAudioTime? {
        var playerTime: AVAudioTime? = nil
        
        if let nodeTime = lastRenderTime {
            playerTime = self.playerTime(forNodeTime: nodeTime)
        }
        
        return playerTime
    }
    
}

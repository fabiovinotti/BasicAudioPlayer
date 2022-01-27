//
//  AVAudioEngine+Extensions.swift
//  
//
//  Created by Fabio Vinotti on 04/01/22.
//

import AVFAudio

extension AVAudioEngine {
    
    public func attach(_ nodes: Set<AVAudioNode>) {
        for n in nodes { attach(n) }
    }
    
    public func detachAll() {
        for n in attachedNodes {
            detach(n)
        }
    }
}

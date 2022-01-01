//
//  AVAudioNode+Extensions.swift
//  
//
//  Created by Fabio Vinotti on 23/12/21.
//

import AVFAudio

extension AVAudioNode {
    
    /// Detaches the audio node from its audio engine.
    public func detach() {
        if let e = engine {
            e.detach(self)
        }
    }
    
}

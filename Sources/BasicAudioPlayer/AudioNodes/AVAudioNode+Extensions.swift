//
//  BasicAudioPlayer
//  AVAudioNode+Extensions.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFAudio

extension AVAudioNode {
    
    /// Detaches the audio node from its audio engine.
    public func detach() {
        guard let engine = engine else {
            log(level: .error, "The source audio node is not attached to an engine.")
            return
        }
        
        engine.detach(self)
    }
    
}

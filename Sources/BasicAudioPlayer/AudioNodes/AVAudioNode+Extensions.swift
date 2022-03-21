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
        if let e = engine {
            e.detach(self)
        }
    }
    
}

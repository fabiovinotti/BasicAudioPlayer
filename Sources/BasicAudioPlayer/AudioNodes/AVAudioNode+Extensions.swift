//
//  BasicAudioPlayer
//  AVAudioNode+Extensions.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFAudio

extension AVAudioNode {
    
    // MARK: - Detaching Nodes
    
    /// Detaches the audio node from its audio engine.
    public func detach() {
        guard let engine = engine else { return }
        engine.detach(self)
    }
    
}

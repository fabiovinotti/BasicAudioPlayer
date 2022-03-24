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
    
    // MARK: - Connecting Nodes
    
    public func connect(to node: AVAudioNode,
                        fromBus bus1: AVAudioNodeBus = 0,
                        toBus bus2: AVAudioNodeBus = 0,
                        format: AVAudioFormat?) {
        
        guard let engine = engine else {
            log(level: .error, "The source audio node is not attached to an engine.")
            return
        }
        
        engine.connect(self, to: node, fromBus: bus1, toBus: bus2, format: format)
    }
    
    // MARK: - Disconnecting Nodes
    
    public func disconnectNodeInput() {
        guard let engine = engine else {
            log(level: .error, "The audio node is not attached to an engine.")
            return
        }
        
        engine.disconnectNodeInput(self)
    }
    
    public func disconnectNodeInput(bus: AVAudioNodeBus) {
        guard let engine = engine else {
            log(level: .error, "The audio node is not attached to an engine.")
            return
        }
        
        engine.disconnectNodeInput(self, bus: bus)
    }
    
    public func disconnectNodeOutput() {
        guard let engine = engine else {
            log(level: .error, "The audio node is not attached to an engine.")
            return
        }
        
        engine.disconnectNodeOutput(self)
    }
    
    public func disconnectNodeOutput(bus: AVAudioNodeBus) {
        guard let engine = engine else {
            log(level: .error, "The audio node is not attached to an engine.")
            return
        }
        
        engine.disconnectNodeOutput(self, bus: bus)
    }
}

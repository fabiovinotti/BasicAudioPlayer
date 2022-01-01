//
//  AVAudioPlayerNode+Extensions.swift
//  
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import AVFoundation
import Combine

extension AVAudioPlayerNode {
    
    public func scheduleFile(_ file: AVAudioFile, at when: AVAudioTime?) -> AnyPublisher<Void, Never> {
        Future<Void, Never> { promise in
            self.scheduleFile(file, at: when) {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func scheduleSegment(_ file: AVAudioFile, startingFrame startFrame: AVAudioFramePosition, frameCount numberFrames: AVAudioFrameCount, at when: AVAudioTime?) -> AnyPublisher<Void, Never> {
        
        Future<Void, Never> { promise in
            self.scheduleSegment(file, startingFrame: startFrame, frameCount: numberFrames, at: when) {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func scheduleBuffer(_ buffer: AVAudioPCMBuffer, at when: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions = []) -> AnyPublisher<Void, Never> {
        
        Future<Void, Never> { promise in
            self.scheduleBuffer(buffer, at: when, options: options) {
                promise(.success(()))
            }
        }
        .eraseToAnyPublisher()
    }
    
}

//
//  AVAudioPlayerNode+Extensions.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import AVFoundation
import Combine

extension AVAudioPlayerNode {
    
    /// The player time as a number of audio samples.
    public var sampleTime: AVAudioFramePosition? {
        
        guard let nodeTime = lastRenderTime,
              let playerTime = playerTime(forNodeTime: nodeTime)
        else { return nil }
        
        return playerTime.sampleTime
    }
    
    public func scheduleFilePublisher(_ file: AVAudioFile, at when: AVAudioTime?) -> AnyPublisher<Void, Never> {
        
        Future<Void, Never>({ promise in
            self.scheduleFile(file, at: when, completionHandler: {
                promise(.success(()))
            })
        })
        .eraseToAnyPublisher()
        
    }
    
    public func scheduleSegmentPublisher(_ file: AVAudioFile, startingFrame startFrame: AVAudioFramePosition, frameCount numberFrames: AVAudioFrameCount, at when: AVAudioTime?) -> AnyPublisher<Void, Never> {
        
        Future<Void, Never>({ promise in
            self.scheduleSegment(file, startingFrame: startFrame, frameCount: numberFrames, at: when) {
                promise(.success(()))
            }
        })
        .eraseToAnyPublisher()
        
    }
    
    public func scheduleBufferPublisher(_ buffer: AVAudioPCMBuffer, at when: AVAudioTime?, options: AVAudioPlayerNodeBufferOptions = []) -> AnyPublisher<Void, Never> {
        
        Future<Void, Never>({ promise in
            self.scheduleBuffer(buffer, at: when, options: options, completionHandler: {
                promise(.success(()))
            })
        })
        .eraseToAnyPublisher()
        
    }
    
}

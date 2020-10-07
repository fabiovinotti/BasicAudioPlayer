//
//  AudioPlayerNode.swift
//  AudioElements
//
//  Copyright © 2020 Fabio Vinotti. All rights reserved.
//

import AVFoundation

public class AudioPlayerNode: AVAudioPlayerNode {
    
    /// A Boolean value that indicates wether or not the node has been stopped programmatically
    private var hasBeenStopped: Bool = false
    
    /// The number of sample elapsed before pausing the audio player node.
    private var lastFrameBeforePause: AVAudioFramePosition = 0
    
    public var currentFrame: AVAudioFramePosition {
        guard
            self.isPlaying,
            
            /// Time in reference to engine start time. If engine is not running, returns nil.
            let nodeTime = self.lastRenderTime,
            
            /// Converts nodeTime to time relative to the player start time. If player is not playing,  returns nil.
            let playerTime = self.playerTime(forNodeTime: nodeTime)
        
        else { return lastFrameBeforePause }
        
        return playerTime.sampleTime
    }
    
    public override func pause() {
        lastFrameBeforePause = currentFrame
        super.pause()
    }
    
    public override func stop() {
        hasBeenStopped = true
        super.stop()
        if isPlaying { pause() }
        lastFrameBeforePause = 0
    }
    
    public override func scheduleFile(_ file: AVAudioFile, at when: AVAudioTime?, completionHandler: AVAudioNodeCompletionHandler? = nil) {
        
        super.scheduleFile(file, at: when) { [unowned self] in
            if hasBeenStopped { hasBeenStopped = false }
            else {
                self.completionHandler()
                completionHandler?()
            }
        }
        
    }
    
    public override func scheduleSegment(_ file: AVAudioFile, startingFrame startFrame: AVAudioFramePosition, frameCount numberFrames: AVAudioFrameCount, at when: AVAudioTime?, completionHandler: AVAudioNodeCompletionHandler? = nil) {
        
        super.scheduleSegment(file, startingFrame: startFrame, frameCount: numberFrames, at: when) { [unowned self] in
            if hasBeenStopped { hasBeenStopped = false }
            else {
                self.completionHandler()
                completionHandler?()
            }
        }
    }
    
    private func completionHandler() {
        DispatchQueue.main.async { [unowned self] in
            if isPlaying { pause() }
            lastFrameBeforePause = 0
        }
    }
    
}

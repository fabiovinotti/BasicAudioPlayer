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
    
    /// The playback time elapsed before pausing the audio player node, as a number of audio samples.
    private var sampleTimeBeforePause: AVAudioFramePosition = 0
    
    /// The elapsed playback time as a number of audio samples.
    public var sampleTime: AVAudioFramePosition {
        guard
            self.isPlaying,
            
            /// Time in reference to engine start time.
            let nodeTime = self.lastRenderTime,
            
            /// Converts nodeTime to time relative to the player start time.
            let playerTime = self.playerTime(forNodeTime: nodeTime)
        
        else { return sampleTimeBeforePause }
        
        return playerTime.sampleTime
    }
    
    public override func pause() {
        sampleTimeBeforePause = sampleTime
        super.pause()
    }
    
    public override func stop() {
        hasBeenStopped = true
        super.stop()
        if isPlaying { pause() }
        sampleTimeBeforePause = 0
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
            sampleTimeBeforePause = 0
        }
    }
    
}

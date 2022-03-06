//
//  AudioPlayerNode.swift
//  
//
//  Created by Fabio Vinotti on 25/11/21.
//

import AVFoundation

/// An AVAudioPlayerNode wrapper that encapsulates all basic playback control functionality.
public class AudioPlayerNode {
    
    /// Whether the playback should restart once completed.
    public var doesLoop: Bool = false
    
    /// The time nedeed to play the entire audio source measured in seconds.
    ///
    /// - returns: The playback duration of the loaded audio or 0 if no audio is loaded.
    public var duration: TimeInterval {
        file?.duration ?? 0
    }
    
    public weak var delegate: AudioPlayerNodeDelegate? = nil
    
    /// The underlying AVAudioPlayerNode.
    ///
    /// Interacting with it directly could cause the wrapper to behave unpredictably.
    public private(set) var node = AVAudioPlayerNode()
    
    private var _playbackSegment: ClosedRange<TimeInterval> = 0...0
    /// The portion of the audio source that will be scheduled.
    public var playbackSegment: ClosedRange<TimeInterval> {
        get { _playbackSegment }
        set {
            let start = max(0, min(newValue.lowerBound, duration))
            let end = max(0, min(newValue.upperBound, duration))
            
            guard start < end else {
                log("An error occurred while setting the playback segment: segment start >= segment end.", level: .error)
                return
            }
            
            _playbackSegment = start...end
        }
    }
    
    /// The playback segment's lower bound.
    public var segmentStart: TimeInterval {
        get { _playbackSegment.lowerBound }
        set { playbackSegment = newValue...segmentEnd }
    }
    
    /// The playback segment's upper bound.
    public var segmentEnd: TimeInterval {
        get { _playbackSegment.upperBound }
        set { playbackSegment = segmentStart...newValue }
    }
    
    /// The playback point within the timeline of the track associated with the player measured in seconds.
    ///
    /// Calling this function when the underlying AVAudioPlayerNode is not attached to an engine will raise errors.
    public var currentTime: TimeInterval {
        let currentTime: TimeInterval
        
        if let nodeTime = node.lastRenderTime, let playerTime = node.playerTime(forNodeTime: nodeTime) {
            let playerTimeInterval = Double(playerTime.sampleTime) / playerTime.sampleRate
            currentTime = segmentStart + playerTimeInterval
        } else if status == .paused {
            currentTime = timeElapsedBeforeStop
        } else {
            currentTime = segmentStart
        }
        
        return min(currentTime, duration)
    }
    
    public private(set) var status: Status = .noSource {
        didSet {
            delegate?.playerNodeStatusDidChange(self, from: oldValue, to: status)
        }
    }
    
    /// The loaded audio file.
    public private(set) var file: AVAudioFile? = nil
    
    /// The playback time elapsed before pausing or stopping the node.
    private var timeElapsedBeforeStop: TimeInterval = 0
    
    /// Indicates whether the playerNode needs to schedule before playing.
    private var needsScheduling: Bool = true
    
    public init() {}
    
    deinit {
        completionObserverTimer?.invalidate()
    }
    
    public func load(url fileURL: URL) throws {
        let f = try AVAudioFile(forReading: fileURL)
        load(file: f)
    }
    
    public func load(file: AVAudioFile) {
        if status == .playing || status == .paused {
            stop()
        }
        
        self.file = file
        needsScheduling = true
        playbackSegment = 0...duration
        status = .ready
    }
    
    public func play(at when: AVAudioTime? = nil) {
        guard file != nil else {
            log("An error occurred on play: no audio source to play.", level: .error)
            return
        }
        
        guard node.engine != nil else {
            log("An error occurred on play: the node is not attached to an engine.", level: .error)
            return
        }
        
        guard node.engine?.isRunning ?? false else {
            log("An error occurred on play: the engine is not running.", level: .error)
            return
        }
        
        if status == .playing {
            stop()
        }
        
        if needsScheduling {
            if segmentStart == duration {
                segmentStart = 0
            }
            
            schedule(at: when)
        }
        
        node.play()
        startCompletionObserver()
        status = .playing
    }
    
    public func pause() {
        guard status == .playing else { return }
        timeElapsedBeforeStop = currentTime
        node.pause()
        status = .paused
    }
    
    /// Stops playback and removes any scheduled events.
    public func stop() {
        guard status == .playing || status == .paused else { return }
        timeElapsedBeforeStop = currentTime
        status = .ready
        node.stop()
        needsScheduling = true
    }
    
    /// Schedules the playing of an audio file segment.
    ///
    /// The node's file will be used as an audio source. If no segment is provided when this class is called,
    /// the segmentStart and segmentEnd properties of the node will be used instead.
    ///
    /// - parameter segment: A range indicating the segment starting and ending time.
    /// - parameter time: The time the segment plays.
    public func schedule(segment: ClosedRange<TimeInterval>? = nil, at time: AVAudioTime? = nil) {
        guard let file = file else {
            log("An error occurred while scheduling: no audio source to play.", level: .error)
            return
        }
        
        if let newSegment = segment {
            playbackSegment = newSegment
        }
        
        let startFrame = AVAudioFramePosition(segmentStart * file.fileFormat.sampleRate)
        let endFrame = AVAudioFramePosition(segmentEnd * file.fileFormat.sampleRate)
        let frameCount = AVAudioFrameCount(endFrame - startFrame)
        
        guard frameCount > 0 else {
            log("An error occurred while scheduling: frame count < 0.", level: .error)
            return
        }
        
        node.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: time,
            completionCallbackType: .dataPlayedBack,
            completionHandler: nil)
        
        node.prepare(withFrameCount: frameCount)
        needsScheduling = false
    }
    
    /// Sets the current playback time.
    ///
    /// The scheduled segment is modified when this function is called. It's new value will be time...duration.
    ///
    /// - parameter time: The time to which to seek.
    public func seek(to time: TimeInterval) {
        guard let f = file else {
            log("""
            An error occurred while setting the current time: No audio source has been provided. You need to provide an audio source (file) before setting the current time.
            """, level: .error)
            return
        }
        
        segmentStart = max(0, min(time, f.duration))
        segmentEnd = f.duration
        
        if status == .playing {
            !doesLoop && segmentStart == duration ? stop() : play()
        } else if status == .paused {
            stop()
        } else if status == .ready {
            node.stop()
            needsScheduling = true
        }
    }
    
    private var completionObserverTimer: Timer?
    /// Calls the playback completion handler when the scheduled audio has been completely played.
    ///
    /// It automatically stops checking when the playback stops.
    private func startCompletionObserver() {
        
        func timerBlock(_ timer: Timer) {
            guard status == .playing else {
                timer.invalidate()
                return
            }
            
            if (currentTime >= segmentEnd) {
                playbackCompletionHandler()
            }
        }
        
        completionObserverTimer?.invalidate()
        
        completionObserverTimer = Timer.scheduledTimer(
            withTimeInterval: 0.2,
            repeats: true,
            block: timerBlock)
        
        completionObserverTimer?.tolerance = 0.2
    }
    
    /// Called when the scheduled audio has been completely played.
    private func playbackCompletionHandler() {
        stop()
        delegate?.playerNodePlaybackDidComplete(self)
        if doesLoop { play() }
    }
}

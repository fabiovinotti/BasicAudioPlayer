//
//  BasicAudioPlayer
//  AudioPlayerNode.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import AVFoundation

/// An AVAudioPlayerNode wrapper that encapsulates all basic playback control functionality.
public class AudioPlayerNode {
    
    // MARK: - Properties
    
    /// Whether the playback should restart once completed.
    public var doesLoop: Bool = false
    
    /// The total playback duration of the loaded audio file, in seconds.
    ///
    /// Returns `0` if no file has been loaded.
    public var duration: TimeInterval {
        file?.duration ?? 0
    }
    
    /// The delegate that receives playback events.
    public weak var delegate: AudioPlayerNodeDelegate?
    
    /// The underlying AVAudioPlayerNode.
    ///
    /// Interacting with it directly could cause the wrapper to behave unpredictably.
    public private(set) var node = AVAudioPlayerNode()
    
    /// The bus's input volume.
    ///
    /// The range of valid values is 0.0 to 1.0.
    public var volume: Float {
        get { node.volume }
        set { node.volume = newValue }
    }
    
    /// The playback segment's lower bound, in seconds.
    ///
    /// The value is clamped to `0...duration`. Setting a value greater than
    /// ``segmentEnd`` is ignored.
    public var segmentStart: TimeInterval {
        get { _playbackSegment.lowerBound }
        set {
            let clamped = max(0, min(newValue, duration))
            guard clamped <= segmentEnd else {
                log.error("Failed to set segment start: \(clamped) exceeds segment end (\(segmentEnd)).")
                return
            }
            _playbackSegment = clamped...segmentEnd
        }
    }
    
    /// The playback segment's upper bound, in seconds.
    ///
    /// The value is clamped to `0...duration`. Setting a value less than
    /// ``segmentStart`` is ignored.
    public var segmentEnd: TimeInterval {
        get { _playbackSegment.upperBound }
        set {
            let clamped = max(0, min(newValue, duration))
            guard clamped >= segmentStart else {
                log.error("Failed to set segment end: \(clamped) is below segment start (\(segmentStart)).")
                return
            }
            _playbackSegment = segmentStart...clamped
        }
    }
    
    private var _playbackSegment: ClosedRange<TimeInterval> = 0...0
    
    /// The portion of the audio source that will be scheduled for playback.
    ///
    /// Both bounds are clamped to `0...duration`. Setting a range where
    /// `lowerBound > upperBound` is ignored.
    public var playbackSegment: ClosedRange<TimeInterval> {
        get { _playbackSegment }
        set {
            let start = max(0, min(newValue.lowerBound, duration))
            let end = max(0, min(newValue.upperBound, duration))

            guard start <= end else {
                log.error("Failed to set playback region: duration < 0.")
                return
            }

            _playbackSegment = start...end
        }
    }
    
    /// The playback point within the timeline of the loaded audio file, in seconds.
    ///
    /// - Important: The underlying AVAudioPlayerNode must be attached to an engine
    ///   for this property to return meaningful values during playback.
    public var currentTime: TimeInterval {
        let currentTime: TimeInterval
        
        if let pt = node.playerTime {
            let sampleTime = pt.sampleTime - (sampleTimeOffset ?? 0)
            let playerTimeInterval = Double(sampleTime) / pt.sampleRate
            currentTime = segmentStart + playerTimeInterval
        } else if status == .paused {
            currentTime = timeElapsedBeforeStop
        } else {
            currentTime = segmentStart
        }
        
        return min(currentTime, duration)
    }
    
    /// The current playback status.
    public private(set) var status: Status = .noSource {
        didSet {
            delegate?.playerNodeStatusDidChange(self, from: oldValue, to: status)
        }
    }
    
    /// The loaded audio file.
    public private(set) var file: AVAudioFile?
    
    /// When AVAudioPlayerNode starts playing after a scheduling event its sample time
    /// is not 0 as expected. This offset is subtracted when computing ``currentTime``.
    private var sampleTimeOffset: AVAudioFramePosition?
    
    /// The playback time elapsed before pausing or stopping the node.
    private var timeElapsedBeforeStop: TimeInterval = 0
    
    /// Whether the scheduling of an audio file segment is required.
    ///
    /// If an audio file is loaded and the conditions for playback are met,
    /// the scheduling is performed automatically before starting playback.
    public private(set) var needsScheduling: Bool = true
    
    /// Whether to block the next execution of the internal completion handler.
    ///
    /// This function is reset to false when a completion handler is actually blocked.
    private var blocksNextCompletionHandler: Bool = false
    
    // MARK: - Creating a Player Node
    
    public init() {}
    
    // MARK: - Loading Audio Files
    
    /// Loads an audio file from the given URL.
    ///
    /// If the player is currently playing or paused, it is stopped first.
    ///
    /// - Parameter fileURL: The URL of the audio file to load.
    /// - Throws: An error if the file cannot be read.
    public func load(url fileURL: URL) throws {
        let f = try AVAudioFile(forReading: fileURL)
        load(file: f)
    }
    
    /// Loads an audio file for playback.
    ///
    /// If the player is currently playing or paused, it is stopped first.
    /// The playback segment is reset to cover the full duration of the file.
    ///
    /// - Parameter file: The audio file to load.
    public func load(file: AVAudioFile) {
        if status == .playing || status == .paused {
            stop()
        }
        
        self.file = file
        needsScheduling = true
        playbackSegment = 0...duration
        status = .ready
    }
    
    // MARK: - Scheduling
    
    /// Schedules the playing of a segment of the loaded audio file.
    ///
    /// If an audio file is loaded and the conditions for playback are met,
    /// the scheduling is performed automatically before starting playback.
    /// However, you can schedule a segment manually using this function.
    ///
    /// When no segment is specified, the current ``segmentStart`` and
    /// ``segmentEnd`` properties are used.
    ///
    /// - Parameters:
    ///   - segment: A range indicating the segment start and end times.
    ///   - time: The `AVAudioTime` at which the segment should play.
    public func schedule(segment: ClosedRange<TimeInterval>? = nil, at time: AVAudioTime? = nil) {
        guard let file else {
            log.error("Scheduling failed: no audio file to schedule.")
            return
        }

        if let segment {
            playbackSegment = segment
        }

        let startFrame = AVAudioFramePosition(segmentStart * file.fileFormat.sampleRate)
        let endFrame = AVAudioFramePosition(segmentEnd * file.fileFormat.sampleRate)
        let frameCount = AVAudioFrameCount(endFrame - startFrame)
        
        guard frameCount > 0 else {
            log.error("Scheduling failed: number of frames to schedule is <= 0.")
            return
        }
        
        node.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: time,
            completionCallbackType: .dataPlayedBack) { [weak self] _ in
                Task { [weak self] in
                    await self?.playbackCompletionHandler()
                }
            }
        
        node.prepare(withFrameCount: frameCount)
        needsScheduling = false
        sampleTimeOffset = nil
    }
    
    // MARK: - Controlling Playback
    
    /// Starts or resumes playback.
    ///
    /// If scheduling is needed, it is performed automatically. If the playback
    /// position is at the end of the track, the segment resets to the beginning.
    ///
    /// Playback requires that:
    /// - An audio file is loaded.
    /// - The node is attached to an engine.
    /// - The engine is running.
    ///
    /// - Parameter when: The `AVAudioTime` at which to start playback, or `nil` for immediately.
    public func play(at when: AVAudioTime? = nil) {
        guard file != nil else {
            log.error("Failed to play. No audio file is loaded.")
            return
        }
        
        guard let e = node.engine else {
            log.error("Failed to play: the node must be attached to an engine.")
            return
        }
        
        guard e.isRunning else {
            log.error("Failed to play: audio engine is stopped.")
            return
        }
        
        guard status != .playing else {
            log.debug("The player is already playing.")
            return
        }
        
        if needsScheduling {
            // If the position is at the end, reset to the beginning of the track.
            if segmentStart == segmentEnd {
                playbackSegment = 0...duration
            }
            schedule()
        }
        
        node.play(at: when)
        
        // Collect the offset of the sample time if it is nil.
        if sampleTimeOffset == nil, let pt = node.playerTime {
            sampleTimeOffset = pt.sampleTime
        }
        
        status = .playing
    }
    
    /// Pauses playback without removing scheduled events.
    ///
    /// Does nothing if the player is not currently playing.
    public func pause() {
        guard status == .playing else { return }
        timeElapsedBeforeStop = currentTime
        node.pause()
        status = .paused
    }
    
    /// Stops playback and removes any scheduled events.
    ///
    /// Does nothing when no audio file is loaded.
    public func stop() {
        guard status != .noSource else { return }
        
        if status == .ready && needsScheduling {
            log.debug("Couldn't stop the node: it is already stopped and there are no scheduled events.")
            return
        }
        
        blocksNextCompletionHandler = true
        node.stop()
        status = .ready
        needsScheduling = true
    }
    
    /// Seeks to the specified playback time.
    ///
    /// The playback segment is updated to `time...duration`. If the player is
    /// playing, playback restarts from the new position. If paused, the player
    /// transitions to the stopped (ready) state.
    ///
    /// - Parameter time: The time to seek to, clamped to `0...duration`.
    public func seek(to time: TimeInterval) {
        guard let f = file else {
            log.error("Failed to seek: no audio file is loaded.")
            return
        }
        
        segmentStart = max(0, min(time, f.duration))
        segmentEnd = f.duration
        
        if status == .playing {
            stop()
            
            if segmentStart != duration || doesLoop {
                play(at: nil)
            }
        } else if status == .paused {
            stop()
        } else if status == .ready && !needsScheduling {
            blocksNextCompletionHandler = true
            node.stop()
            needsScheduling = true
        }
    }
    
    /// Executed when the scheduled audio has been completely played.
    @MainActor
    private func playbackCompletionHandler() {
        guard !blocksNextCompletionHandler else {
            blocksNextCompletionHandler = false
            return
        }
        
        node.stop()
        needsScheduling = true
        status = .ready
        delegate?.playerNodePlaybackDidComplete(self)
        
        if doesLoop { play() }
    }
}

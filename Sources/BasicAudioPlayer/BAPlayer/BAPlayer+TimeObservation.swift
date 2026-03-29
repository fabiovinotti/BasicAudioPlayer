//
//  BasicAudioPlayer
//  BAPlayer+TimeObservation.swift
//
//  Copyright © 2022 Fabio Vinotti. All rights reserved.
//  Licensed under MIT License.
//

import Foundation

extension BAPlayer {

    // TODO: Observers should stop when the playback is stopped or paused, and resumed on play.
    
    /// Adds a periodic time observer that fires at the given interval.
    ///
    /// - Parameters:
    ///   - interval: The time between observer invocations, in seconds.
    ///   - queue: The dispatch queue on which the block is called.
    ///     Pass `nil` to use an internal serial queue.
    ///   - block: The closure to invoke on each tick.
    /// - Returns: An opaque observer token. Pass it to ``removeTimeObserver(_:)``
    ///   when you no longer need the observer.
    public func addTimeObserver(interval: TimeInterval, queue: DispatchQueue?, block: @escaping () -> Void) -> Any {
        let t = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        t.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        t.setEventHandler(handler: block)
        t.activate()
        return t
    }
    
    /// Removes a previously added time observer.
    ///
    /// - Parameter observer: The opaque token returned by ``addTimeObserver(interval:queue:block:)``.
    public func removeTimeObserver(_ observer: Any) {
        guard let o = observer as? DispatchSourceTimer else {
            log.info("Failed to remove observer: invalid parameter.")
            return
        }

        o.cancel()
    }
    
    /// Registers a one-shot observer that fires when the specified playback time is reached.
    ///
    /// The observer automatically cancels itself after the block executes.
    ///
    /// - Parameters:
    ///   - time: The playback time to observe, in seconds.
    ///   - queue: The dispatch queue on which the block is called.
    ///     Pass `nil` to use an internal serial queue.
    ///   - block: The closure to execute when the playback time is reached.
    /// - Returns: An opaque observer token. Pass it to ``removeTimeObserver(_:)``
    ///   to cancel before it fires.
    public func onPlaybackTime(_ time: TimeInterval, queue: DispatchQueue?, execute block: @escaping () -> Void) -> Any {
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer.schedule(deadline: .now(), repeating: 0.01, leeway: .milliseconds(1))

        timer.setEventHandler { [weak self] in
            guard let self else {
                timer.cancel()
                return
            }

            let ct = self.currentTime
            if ct >= time && ct <= time + 0.1 { block() }
        }

        timer.activate()
        return timer
    }
    
}

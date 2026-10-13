import AVFoundation
import BasicAudioPlayer
import Observation

/// Drives a `BAPlayer` with a time-pitch unit in its chain.
@Observable
final class PlayerModel {

    @ObservationIgnored let player = BAPlayer()
    @ObservationIgnored private let timePitch = AVAudioUnitTimePitch()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var securityScopedURL: URL?

    private(set) var status: BAPlayer.Status = .noSource
    private(set) var fileURL: URL?
    private(set) var duration: TimeInterval = 0
    private(set) var currentTime: TimeInterval = 0
    var errorMessage: String?

    /// While scrubbing, the slider owns `currentTime` and the time observer leaves it alone.
    var isScrubbing = false

    var doesLoop = false {
        didSet { player.doesLoop = doesLoop }
    }

    var rate: Float = 1 {
        didSet { timePitch.rate = rate }
    }

    /// Pitch shift, in cents.
    var pitch: Float = 0 {
        didSet { timePitch.pitch = pitch }
    }

    init() {
        // Units added before a file is loaded are connected on load.
        player.addAudioUnit(timePitch)

        player.onStatusChange { [weak self] status in
            Task { @MainActor in self?.status = status }
        }

        timeObserver = player.addTimeObserver(interval: 0.1, queue: .main) { [weak self] in
            MainActor.assumeIsolated { self?.refreshTime() }
        }
    }

    // MARK: - Loading

    func loadBundledSample() {
        guard let url = Bundle.main.url(forResource: "audio-sample", withExtension: "aac") else {
            errorMessage = "audio-sample.aac is missing from the app bundle."
            return
        }
        load(url: url)
    }

    /// Loads a file, keeping security-scoped access to it until the next load,
    /// since the offline renderer reopens the file by URL.
    func load(url: URL) {
        securityScopedURL?.stopAccessingSecurityScopedResource()
        securityScopedURL = url.startAccessingSecurityScopedResource() ? url : nil

        do {
            try player.load(url: url)
            fileURL = url
            duration = player.duration
            currentTime = 0
            status = player.status
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Playback

    func togglePlayback() {
        if player.status == .playing {
            player.pause()
        } else {
            player.play()
        }
    }

    func stop() {
        player.stop()
        refreshTime()
    }

    func seek(to time: TimeInterval) {
        player.currentTime = time
        currentTime = time
    }

    /// Updates the displayed time while the slider is dragged, without seeking.
    func scrub(to time: TimeInterval) {
        currentTime = time
    }

    private func refreshTime() {
        status = player.status
        guard !isScrubbing else { return }
        currentTime = player.currentTime
    }

}

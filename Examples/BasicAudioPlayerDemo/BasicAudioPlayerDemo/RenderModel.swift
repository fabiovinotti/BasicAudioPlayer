import AVFoundation
import BasicAudioPlayer
import Observation

/// Renders a region of a file through a time-pitch unit with `BAOfflineRenderer`.
@Observable
final class RenderModel {

    @ObservationIgnored private var renderTask: Task<Void, Never>?
    /// Identifies the running render, so late progress updates from an earlier one are ignored.
    @ObservationIgnored private var renderID = UUID()

    var rate: Float = 2
    var sourceStartTime: TimeInterval = 0
    var outputDuration: TimeInterval = 10

    /// The progress of the running render, or `nil` when idle.
    private(set) var progress: Double?
    private(set) var outputURL: URL?
    private(set) var renderDuration: Duration?
    var errorMessage: String?

    var isRendering: Bool { progress != nil }

    /// Renders from `sourceURL`, which is expected to be the file the player has loaded.
    func render(sourceURL: URL) {
        guard !isRendering else { return }

        // Drop the previous output, unless it's the source and so loaded in the player.
        if let previousURL = outputURL, previousURL != sourceURL {
            try? FileManager.default.removeItem(at: previousURL)
        }
        outputURL = nil
        renderDuration = nil

        let rate = rate
        let configuration = BAOfflineRenderer.Configuration(
            sourceURL: sourceURL,
            sourceStartTime: sourceStartTime,
            outputDuration: outputDuration,
            makeAudioUnits: {
                let timePitch = AVAudioUnitTimePitch()
                timePitch.rate = rate
                return [timePitch]
            }
        )

        let destinationURL = URL.temporaryDirectory
            .appending(path: "render-\(UUID().uuidString).caf")

        let id = UUID()
        renderID = id
        progress = 0
        errorMessage = nil

        renderTask = Task.detached { [self] in
            let clock = ContinuousClock()
            let start = clock.now

            do {
                let source = try AVAudioFile(forReading: sourceURL)
                let destination = try AVAudioFile(
                    forWriting: destinationURL,
                    settings: source.processingFormat.settings
                )

                var reported = 0.0
                try BAOfflineRenderer(configuration: configuration).render(to: destination) { progress in
                    // The handler runs once per chunk; only hop to the main actor for visible changes.
                    guard progress - reported >= 0.01 || progress == 1 else { return }
                    reported = progress
                    Task { @MainActor in self.updateProgress(progress, renderID: id) }
                }

                let elapsed = clock.now - start
                await finish(outputURL: destinationURL, elapsed: elapsed)
            } catch is CancellationError {
                try? FileManager.default.removeItem(at: destinationURL)
                await finish(error: nil)
            } catch {
                try? FileManager.default.removeItem(at: destinationURL)
                await finish(error: error)
            }
        }
    }

    func cancel() {
        renderTask?.cancel()
    }

    private func updateProgress(_ value: Double, renderID id: UUID) {
        guard isRendering, id == renderID else { return }
        progress = value
    }

    private func finish(outputURL: URL, elapsed: Duration) {
        self.outputURL = outputURL
        renderDuration = elapsed
        progress = nil
    }

    private func finish(error: Error?) {
        errorMessage = error?.localizedDescription
        progress = nil
    }

}

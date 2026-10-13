import AVFoundation
import BasicAudioPlayer
import Observation

/// Renders a region of a file through a time-pitch unit with `BAOfflineRenderer`.
@Observable
final class RenderModel {

    @ObservationIgnored private var renderTask: Task<Void, Never>?

    var rate: Float = 2
    var sourceStartTime: TimeInterval = 0
    var outputDuration: TimeInterval = 10

    /// The progress of the running render, or `nil` when idle.
    private(set) var progress: Double?
    private(set) var outputURL: URL?
    private(set) var renderDuration: Duration?
    var errorMessage: String?

    var isRendering: Bool { progress != nil }

    func render(sourceURL: URL) {
        renderTask?.cancel()

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
                    Task { @MainActor in self.updateProgress(progress) }
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

    private func updateProgress(_ value: Double) {
        guard isRendering else { return }
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

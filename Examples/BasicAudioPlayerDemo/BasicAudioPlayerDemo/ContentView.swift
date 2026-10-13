import BasicAudioPlayer
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var player = PlayerModel()
    @State private var renderer = RenderModel()
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            Form {
                sourceSection
                playerSection
                renderSection
            }
            .formStyle(.grouped)
            .navigationTitle("BasicAudioPlayer")
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let url): player.load(url: url)
                case .failure(let error): player.errorMessage = error.localizedDescription
                }
            }
        }
        .onAppear {
            if player.fileURL == nil {
                player.loadBundledSample()
            }
        }
    }

    // MARK: - Source

    private var sourceSection: some View {
        Section("Source") {
            LabeledContent("File", value: player.fileURL?.lastPathComponent ?? "None")
            LabeledContent("Status", value: String(describing: player.status))

            HStack {
                Button("Bundled Sample") { player.loadBundledSample() }
                Spacer()
                Button("Choose File…") { isImporting = true }
            }

            if let message = player.errorMessage {
                Text(message).foregroundStyle(.red)
            }
        }
    }

    // MARK: - Player

    private var playerSection: some View {
        Section("Player") {
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.scrub(to: $0) }
                    ),
                    in: 0...max(player.duration, 0.1),
                    onEditingChanged: { editing in
                        player.isScrubbing = editing
                        if !editing {
                            player.seek(to: player.currentTime)
                        }
                    }
                )

                HStack {
                    Text(formatted(player.currentTime))
                    Spacer()
                    Text(formatted(player.duration))
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }

            HStack(spacing: 32) {
                Spacer()
                Button("Back 10 Seconds", systemImage: "gobackward.10") {
                    player.seek(to: max(player.currentTime - 10, 0))
                }
                Button(
                    player.status == .playing ? "Pause" : "Play",
                    systemImage: player.status == .playing ? "pause.fill" : "play.fill"
                ) {
                    player.togglePlayback()
                }
                .font(.title)
                Button("Forward 10 Seconds", systemImage: "goforward.10") {
                    player.seek(to: min(player.currentTime + 10, player.duration))
                }
                Button("Stop", systemImage: "stop.fill") {
                    player.stop()
                }
                Spacer()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .disabled(player.status == .noSource)

            Toggle("Loop", isOn: $player.doesLoop)

            LabeledContent("Rate \(player.rate, format: .number.precision(.fractionLength(2)))×") {
                Slider(value: $player.rate, in: 0.25...4)
            }
            LabeledContent("Pitch \(Int(player.pitch)) ct") {
                Slider(value: $player.pitch, in: -1200...1200, step: 100)
            }
        }
    }

    // MARK: - Offline Rendering

    private var renderSection: some View {
        Section {
            LabeledContent("Start \(formatted(renderer.sourceStartTime))") {
                Slider(value: $renderer.sourceStartTime, in: 0...max(player.duration, 0.1))
            }
            Stepper(
                "Output length \(Int(renderer.outputDuration)) s",
                value: $renderer.outputDuration,
                in: 1...600,
                step: 5
            )
            LabeledContent("Rate \(renderer.rate, format: .number.precision(.fractionLength(2)))×") {
                Slider(value: $renderer.rate, in: 0.25...4)
            }

            if let progress = renderer.progress {
                HStack {
                    ProgressView(value: progress)
                    Button("Cancel", role: .cancel) { renderer.cancel() }
                }
            } else {
                Button("Render") {
                    if let url = player.fileURL {
                        renderer.render(sourceURL: url)
                    }
                }
                .disabled(player.fileURL == nil)
            }

            if let message = renderer.errorMessage {
                Text(message).foregroundStyle(.red)
            }

            if let outputURL = renderer.outputURL, !renderer.isRendering {
                if let elapsed = renderer.renderDuration {
                    LabeledContent("Rendered in", value: elapsed.formatted(.units(allowed: [.seconds, .milliseconds])))
                }
                HStack {
                    Button("Open in Player") { player.load(url: outputURL) }
                    Spacer()
                    ShareLink(item: outputURL)
                }
            }
        } header: {
            Text("Offline Rendering")
        } footer: {
            Text("Renders with BAOfflineRenderer on its own engine, so playback above keeps going.")
        }
    }

    private func formatted(_ time: TimeInterval) -> String {
        Duration.seconds(time).formatted(.time(pattern: .minuteSecond))
    }
}

#Preview {
    ContentView()
}

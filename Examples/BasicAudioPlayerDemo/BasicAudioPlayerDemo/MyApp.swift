import SwiftUI
#if os(iOS)
import AVFoundation
#endif

@main struct MyApp: App {

    init() {
        #if os(iOS)
        // Play through the silent switch, like a media app.
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

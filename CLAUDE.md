@CONTRIBUTING.md

## Notes for Claude

### Verifying changes

- Run `swift test` and the iOS simulator tests before calling a change done. Pick a simulator from `xcodebuild -showdestinations -scheme BasicAudioPlayer`; names change between Xcode versions.
- When public API or behavior changes, also build the demo app for both platforms:

  ```sh
  xcodebuild build -project Examples/BasicAudioPlayerDemo/BasicAudioPlayerDemo.xcodeproj -scheme BasicAudioPlayerDemo -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
  xcodebuild build -project Examples/BasicAudioPlayerDemo/BasicAudioPlayerDemo.xcodeproj -scheme BasicAudioPlayerDemo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
  ```

- The demo target builds with Swift's `MemberImportVisibility`, so files that use package types or enum cases need `import BasicAudioPlayer` themselves.

### AVAudioEngine pitfalls

- Reconfiguring the graph (connect, disconnect, attach) while the engine is running raises an Objective-C exception that Swift can't catch. Stop the engine first, as `BAPlayer.redoConnections()` does.
- Connecting to `mainMixerNode` logs error -10878. It's harmless; don't chase it.
- `BAPlayer` rendering takes over the player's own engine and stops playback. `BAOfflineRenderer` builds a separate engine per render, so it's safe to use while a player is playing. Keep that separation when changing either one.

### Releases

- Don't create or push tags, or publish GitHub releases, unless asked. Tags are the release mechanism (see "Branches and Releases" above).
- Keep minor and patch releases additive: no breaking public API changes.

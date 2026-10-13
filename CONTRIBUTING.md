# Contributing

Thanks for helping improve BasicAudioPlayer. This guide covers how to build and test the package, try changes in the demo app, and how branches and releases work.

## Building and Testing

The package supports iOS 14+ and macOS 11+, and builds with Swift 5.9 or later.

Run the tests on macOS:

```sh
swift test
```

Run them on an iOS simulator (pick any simulator `xcodebuild -showdestinations -scheme BasicAudioPlayer` lists):

```sh
xcodebuild test -scheme BasicAudioPlayer -destination 'platform=iOS Simulator,name=iPhone 17'
```

The tests use `Tests/BasicAudioPlayerTests/Resources/audio-sample.aac`.

## Demo App

`Examples/BasicAudioPlayerDemo` is an iOS and macOS app for trying changes by ear: playback, seeking, looping, audio units, and offline rendering. It references the package locally, so it always builds against your working copy of `Sources/`. It requires Xcode 27 or later.

Open `Examples/BasicAudioPlayerDemo/BasicAudioPlayerDemo.xcodeproj` and run. To run on a device, choose your development team in the target's Signing & Capabilities first.

When you change behavior that's audible or interactive, check it in the demo app as well as in the tests.

## Branches and Releases

- `main` is the integration branch. It can contain changes that haven't been released yet.
- Work happens on short-lived branches off `main` (`feature/…`, `fix/…`, `docs/…`) and lands through pull requests.
- Releases are tags on `main` following [Semantic Versioning](https://semver.org), written without a `v` prefix: `3.2.0`, not `v3.2.0`. Swift Package Manager resolves versions from tags only, so unreleased work on `main` doesn't reach users.
- Minor and patch releases don't break the public API. Deprecate first; remove in the next major.

### Hotfixes

Because `main` may be ahead of the latest release, hotfixes start from the release tag, not from `main`:

```sh
git switch -c hotfix/3.1.7 3.1.6
```

Commit the fix, tag the patch version on that branch, then merge the hotfix branch into `main` so the next release includes it.

## Code Style

- Match the surrounding code: naming, structure, and comment density.
- Document public API with `///` comments, linking symbols with DocC syntax (``` ``BAPlayer`` ```).
- New files start with the standard header:

  ```swift
  //
  //  BasicAudioPlayer
  //  FileName.swift
  //
  //  Copyright © 2026 Fabio Vinotti. All rights reserved.
  //  Licensed under MIT License.
  //
  ```

- When public API changes, update the README.

## Commits

Write commit subjects as an imperative sentence in sentence case, without a trailing period: `Fix crash when reconfiguring the graph of a running engine`. Keep each commit to one logical change, and use the body to explain why when it isn't obvious.

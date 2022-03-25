# BasicAudioPlayer

BasicAudioPlayer is a library that makes it easier to create AVAudioEngine-based audio players.

## Installation

BasicAudioPlayer is a Swift package. To add it to your Xcode project:
<ol>
  <li>Go to File -> Add Packages...</li>
  <li>Enter <code>https://github.com/fabiovinotti/BasicAudioPlayer</code> in the search bar.</li>
  <li>Choose a dependency rule. "Up to Next Major Version" is the suggested setting.</li>
</ol>

## Getting Started

### BAPlayer

BAPlayer is an object that plays audio from a file. It features all the basic playback control methods an audio player should have, and lets you modulate its audio output by adding audio units to its effects chain. BAPlayer manages all of its audio nodes behind the hood, so you don't have to deal with that.

#### Creating a BAPlayer

Creating a new BAPlayer is straightforward. If you already know which audio file the player will play, you can load it at creation time using the appropriate initializer.

```Swift
// Create a player without loading an audio file
let p = BAPlayer()

// Create a player and load an audio file at a certain URL
let audioFileURL = URL(fileURLWithPath: "/Some/Audio/file.m4a")
let p1 = try BAPlayer(url: audioFileURL)

// Create a player and load an audio file
let audioFile = try AVAudioFile(forReading: audioFileURL)
let p2 = BAPlayer(file: audioFile)
```

#### Loading an Audio File

You can load an audio file after creating the player. A BAPlayer instance can handle the playback of only one audio file at a time. Therefore, if another file has already been loaded, it will be replaced with the new one.

```Swift
let player = BAPlayer()

// Load an audio file at a certain URL
let audioFileURL = URL(fileURLWithPath: "/Path/To/Audio/file.m4a")
try player.load(url: audioFileURL)

// Load an audio file
let audioFile = try AVAudioFile(forReading: audioFileURL)
player.load(file: audioFile)

// Get the loaded audio file, if any
let loadedFile: AVAudioFile? = player.file
```

#### Controlling Playback

BAPlayer makes it easy to control audio playback. Here are the basic methods available.

```Swift
let player = BAPlayer(url: URL(fileURLWithPath: "/Some/Audio/file.m4a"))

// Play audio
player.play()

// Pause audio
player.pause()

// Stop the playback and reset the elapsed time back to 0
player.stop()
```

#### Handling Status Changes

BAPlayer features a property named <code>status</code> that can be used to check what the player is doing. You can also provide a closure to execute when the player's status changes.

```Swift
let player = BAPlayer()

// Get the status of the player
let status = player.status

// Add a closure to run when the player's status changes.
player.onStatusChange { newStatus in
    if newStatus == .playing {
        print("The player is now playing")
    }
}
```

#### Adding Audio Units

You can add audio units (<code>AVAudioUnit</code>) to a BAPlayer to manipulate its audio output. They will be connected in the order they were added.

```Swift
let player = BAPlayer()

// Add a time pitch unit to the player's audio unit chain.
let timePitchUnit = AVAudioUnitTimePitch()
player.addAudioUnit(timePitchUnit)
```

## License

BasicAudioPlayer is available under the MIT license. See the LICENSE file for more info.

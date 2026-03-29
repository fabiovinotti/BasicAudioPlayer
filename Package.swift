// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "BasicAudioPlayer",
    platforms: [
        .iOS(.v14), .macOS(.v11)
    ],
    products: [
        .library(
            name: "BasicAudioPlayer",
            targets: ["BasicAudioPlayer"]),
    ],
    targets: [
        .target(
            name: "BasicAudioPlayer"),
        .testTarget(
            name: "BasicAudioPlayerTests",
            dependencies: ["BasicAudioPlayer"],
            resources: [.process("Resources")])
    ]
)

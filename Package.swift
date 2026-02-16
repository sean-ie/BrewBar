// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BrewBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "BrewBar",
            path: "Sources/BrewBar"
        )
    ]
)

// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Rogue",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Rogue", path: "src")
    ]
)

// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Rogue",
    platforms: [.macOS(.v14)],
    targets: [
        .systemLibrary(name: "SDL", path: "sys"),
        .executableTarget(name: "Rogue", dependencies: ["SDL"], path: "src")
    ]
)

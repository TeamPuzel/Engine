// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Rogue",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "Assets", path: "assets/module"),
        .systemLibrary(name: "SDL", path: "sys", pkgConfig: "sdl2"),
        .executableTarget(name: "Rogue", dependencies: ["SDL", "Assets"], path: "src")
    ]
)

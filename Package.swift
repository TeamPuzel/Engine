// swift-tools-version: 5.10

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency"),
    .enableExperimentalFeature("BuiltinModule")
]

let package = Package(
    name: "Minecraft",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Minecraft", targets: ["Minecraft"]),
    ],
    targets: [
        .target(name: "Assets", path: "assets/module"),
        .executableTarget(name: "Minecraft", dependencies: ["Assets"], path: "src", swiftSettings: swiftSettings)
    ]
)

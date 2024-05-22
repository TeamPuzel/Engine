// swift-tools-version: 5.10

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency"),
    .enableExperimentalFeature("BuiltinModule")
//    .unsafeFlags([
//        "-Xfrontend",
//        "-warn-long-function-bodies=100",
//        "-Xfrontend",
//        "-warn-long-expression-type-checking=100"
//    ])
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

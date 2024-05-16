// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "Minecraft",
    platforms: [.macOS(.v14)],
    targets: [
//        .systemLibrary(name: "SDL", path: "sys", pkgConfig: "sdl2"),
//        .target(name: "GLAD", path: "lib/glad"),
        .target(name: "Assets", path: "assets/module"),
        .executableTarget(
            name: "Minecraft",
            dependencies: ["Assets"],
            path: "src",
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableExperimentalFeature("StrictConcurrency"),
                .enableExperimentalFeature("BuiltinModule")
            ]
        )
    ]
)

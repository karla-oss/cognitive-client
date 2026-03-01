// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CognitiveOverlay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CognitiveOverlayClient", targets: ["CognitiveOverlay"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "CognitiveOverlay",
            dependencies: [],
            path: "Sources"
        )
    ]
)

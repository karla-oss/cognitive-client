// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CognitiveOverlay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CognitiveOverlay", targets: ["CognitiveOverlay"])
    ],
    dependencies: [
        .package(url: "https://github.com/nicklama/swift-webrtc", from: "1.0.0"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "CognitiveOverlay",
            dependencies: [
                .product(name: "Starscream", package: "Starscream"),
            ],
            path: "Sources"
        )
    ]
)

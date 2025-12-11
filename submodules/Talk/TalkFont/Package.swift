// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "TalkFont",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkFont",
            targets: ["TalkFont"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TalkFont",
            dependencies: []
        ),
        .testTarget(
            name: "TalkFontTests",
            dependencies: [
                "TalkFont",
            ]
        ),
    ]
)

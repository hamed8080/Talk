// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "TalkExtensions",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkExtensions",
            targets: ["TalkExtensions"]),
    ],
    dependencies: [
        .package(path: "../TalkModels"),
        .package(path: "../TalkFont")
    ],
    targets: [
        .target(
            name: "TalkExtensions",
            dependencies: [
                "TalkModels",
                "TalkFont"
            ]
        ),
        .testTarget(
            name: "TalkExtensionsTests",
            dependencies: ["TalkExtensions"]
        ),
    ]
)

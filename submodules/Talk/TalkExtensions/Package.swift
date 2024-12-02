// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
        .package(path: "../TalkModels")
    ],
    targets: [
        .target(
            name: "TalkExtensions",
            dependencies: [
                "TalkModels"
            ]
        ),
        .testTarget(
            name: "TalkExtensionsTests",
            dependencies: ["TalkExtensions"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

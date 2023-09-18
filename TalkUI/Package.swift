// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TalkUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkUI",
            targets: ["TalkUI"]),
    ],
    dependencies: [
        .package(path: "../../AdditiveUI"),
        .package(path: "../TalkModels"),
        .package(path: "../TalkExtensions"),
        .package(path: "../TalkViewModels"),
    ],
    targets: [
        .target(
            name: "TalkUI",
            dependencies: [
                "AdditiveUI",
                "TalkModels",
                "TalkExtensions",
                "TalkViewModels"
            ],
            resources: [.process("Resources/Fonts/")]
        ),
        .testTarget(
            name: "TalkUITests",
            dependencies: ["TalkUI"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "TalkViewModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkViewModels",
            targets: ["TalkViewModels"]),
    ],
    dependencies: [
        .package(path: "../TalkModels"),
        .package(path: "../TalkExtensions"),
    ],
    targets: [
        .target(
            name: "TalkViewModels",
            dependencies: [
                "TalkModels",
                "TalkExtensions"
            ]
        ),
        .testTarget(
            name: "TalkViewModelsTests",
            dependencies: ["TalkViewModels"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

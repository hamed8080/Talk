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
        .package(url: "https://github.com/ZipArchive/ZipArchive", exact: "2.5.5")
    ],
    targets: [
        .target(
            name: "TalkViewModels",
            dependencies: [
                "TalkModels",
                "TalkExtensions",
                .product(name: "ZipArchive", package: "ZipArchive")
            ]
        ),
        .testTarget(
            name: "TalkViewModelsTests",
            dependencies: [
                "TalkViewModels",
                .product(name: "ZipArchive", package: "ZipArchive")
            ],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

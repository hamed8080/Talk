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
        .package(path: "../../FFMpegKitContainer"),
        .package(url: "https://github.com/ZipArchive/ZipArchive", exact: "2.5.5"),
        .package(url: "https://github.com/dmrschmidt/DSWaveformImage", exact: "14.2.1"),
        .package(url: "https://github.com/airbnb/lottie-ios", exact: "4.5.2")
    ],
    targets: [
        .target(
            name: "TalkViewModels",
            dependencies: [
                "TalkModels",
                "TalkExtensions",
                .product(name: "ZipArchive", package: "ZipArchive"),
                .product(name: "DSWaveformImage", package: "DSWaveformImage"),
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "FFMpegKitContainer", package: "FFMpegKitContainer")
            ]
        ),
        .testTarget(
            name: "TalkViewModelsTests",
            dependencies: [
                "TalkViewModels",
                .product(name: "ZipArchive", package: "ZipArchive")
            ]
        )
    ]
)

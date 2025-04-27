// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "ImageEditor",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "ImageEditor",
            targets: ["ImageEditor"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ImageEditor"
        ),
        .testTarget(
            name: "ImageEditorTests",
            dependencies: [
                "ImageEditor",
            ]
        )
    ]
)

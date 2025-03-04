// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "ActionableContextMenu",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "ActionableContextMenu",
            targets: ["ActionableContextMenu"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ActionableContextMenu",
            dependencies: []
        ),
        .testTarget(
            name: "ActionableContextMenuTests",
            dependencies: ["ActionableContextMenu"]
        ),
    ]
)

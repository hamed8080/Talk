// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
            dependencies: ["ActionableContextMenu"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

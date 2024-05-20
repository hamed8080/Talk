// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TalkModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "TalkModels",
            targets: ["TalkModels"]),
    ],
    dependencies: [
        .package(path: "../../Chat"),
    ],
    targets: [
        .target(
            name: "TalkModels",
            dependencies: [
                .product(name: "Chat", package: "Chat"),
            ]
        ),
        .testTarget(
            name: "TalkModelsTests",
            dependencies: [
                "TalkModels",
                .product(name: "Chat", package: "Chat"),
            ],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

// swift-tools-version:6.0

import PackageDescription
import Foundation

let package = Package(
    name: "TalkModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkModels",
            targets: ["TalkModels"]),
    ],
    dependencies: [
        .package(path: "../../SDK/Chat"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
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
            ]
        ),
    ]
)

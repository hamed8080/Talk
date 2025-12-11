// swift-tools-version:6.0

import PackageDescription
import Foundation

let package = Package(
    name: "Dependencies",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "Dependencies",
            targets: ["Dependencies"]),
    ],
    dependencies: [
        .package(path: "../../SDK/Chat"),
        .package(path: "../TalkFont"),
        .package(path: "../AdditiveUI"),
        .package(path: "../TalkModels"),
        .package(path: "../TalkExtensions"),
        .package(path: "../TalkUI"),
        .package(path: "../TalkViewModels"),
        .package(path: "../ActionableContextMenu"),
    ],
    targets: [
        .target(
            name: "Dependencies",
            dependencies: [
                .product(name: "Chat", package: "Chat"),
                .product(name: "TalkFont", package: "TalkFont"),
                .product(name: "AdditiveUI", package: "AdditiveUI"),
                .product(name: "TalkModels", package: "TalkModels"),
                .product(name: "TalkExtensions", package: "TalkExtensions"),
                .product(name: "TalkUI", package: "TalkUI"),
                .product(name: "TalkViewModels", package: "TalkViewModels"),
                .product(name: "ActionableContextMenu", package: "ActionableContextMenu"),
            ]
        ),
        .testTarget(
            name: "DependenciesTests",
            dependencies: [
                "Dependencies",
                .product(name: "Chat", package: "Chat"),
            ]
        ),
    ]
)

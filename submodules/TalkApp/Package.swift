// swift-tools-version:6.0

import PackageDescription
import Foundation

let package = Package(
    name: "TalkApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkApp",
            targets: ["TalkApp"]),
    ],
    dependencies: [
        .package(path: "../Talk/Dependencies"),
    ],
    targets: [
        .target(
            name: "TalkApp",
            dependencies: [
                .product(name: "Dependencies", package: "Dependencies"),
            ],
            exclude: ["Exclude"]
        ),
        .testTarget(
            name: "TalkAppTests",
            dependencies: [
                "TalkApp"
            ]
        ),
    ]
)

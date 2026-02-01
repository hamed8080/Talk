// swift-tools-version:6.0

import PackageDescription
import Foundation

let package = Package(
    name: "LeitnerBoxApp",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "LeitnerBoxApp",
            targets: ["LeitnerBoxApp"]),
    ],
    dependencies: [
        .package(path: "../FFMpegKitContainer"),
        .package(path: "../SDK/Chat/submodules/Additive"),
    ],
    targets: [
        .target(
            name: "LeitnerBoxApp",
            dependencies: [
                .product(name: "Additive", package: "Additive"),
                .product(name: "FFMpegKitContainer", package: "FFMpegKitContainer")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LeitnerBoxAppTests",
            dependencies: [
                "LeitnerBoxApp",
            ]
        ),
    ]
)

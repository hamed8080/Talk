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
//        .package(url: "https://pubgi.sandpod.ir/chat/ios/chat.git", from: "2.1.2"),
        .package(path: "../../Chat"),
        .package(url: "https://github.com/ZipArchive/ZipArchive", exact: "2.5.5")
    ],
    targets: [
        .target(
            name: "TalkModels",
            dependencies: [
//                .product(name: "Chat", package: "chat"),
                .product(name: "Chat", package: "Chat"),
                .product(name: "ZipArchive", package: "ZipArchive"),
            ]
        ),
        .testTarget(
            name: "TalkModelsTests",
            dependencies: [
                "TalkModels",
//                .product(name: "Chat", package: "chat"),
                .product(name: "Chat", package: "Chat"),
            ],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

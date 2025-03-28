// swift-tools-version:6.0

import PackageDescription
import Foundation

let useLocalDependency = true

let local: [Package.Dependency] = [
    .package(path: "../../SDK/Chat"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
]

let remote: [Package.Dependency] = [
    .package(url: "https://pubgi.sandpod.ir/chat/ios/chat.git", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
]

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
    dependencies: useLocalDependency ? local : remote,
    targets: [
        .target(
            name: "TalkModels",
            dependencies: [
                .product(name: "Chat", package: useLocalDependency ? "Chat" : "chat"),
            ]
        ),
        .testTarget(
            name: "TalkModelsTests",
            dependencies: [
                "TalkModels",
                .product(name: "Chat", package: useLocalDependency ? "Chat" : "chat"),
            ],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

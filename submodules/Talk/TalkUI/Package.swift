// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let useLocalDependency = true

let local: [Package.Dependency] = [
    .package(path: "../../SDK/AdditiveUI"),
    .package(path: "../TalkModels"),
    .package(path: "../TalkExtensions"),
    .package(path: "../TalkViewModels"),
]

let remote: [Package.Dependency] = [
    .package(url: "https://pubgi.sandpod.ir/chat/ios/additive-ui", from: "1.2.3"),
    .package(path: "../TalkModels"),
    .package(path: "../TalkExtensions"),
    .package(path: "../TalkViewModels"),
]

let package = Package(
    name: "TalkUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "TalkUI",
            targets: ["TalkUI"]),
    ],
    dependencies: useLocalDependency ? local : remote,
    targets: [
        .target(
            name: "TalkUI",
            dependencies: [
                .product(name: "AdditiveUI", package: useLocalDependency ? "AdditiveUI" : "additive-ui"),
                "TalkModels",
                "TalkExtensions",
                "TalkViewModels"
            ],
            resources: [.process("Resources/Fonts/")]
        ),
        .testTarget(
            name: "TalkUITests",
            dependencies: [
                "TalkUI",
                .product(name: "AdditiveUI", package: useLocalDependency ? "AdditiveUI" : "additive-ui"),
            ],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)

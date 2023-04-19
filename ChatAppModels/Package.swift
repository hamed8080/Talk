// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatAppModels",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ChatAppModels",
            targets: ["ChatAppModels"]),
    ],
    dependencies: [
        .package(path: "../AdditiveUI"),
        .package(path: "../Chat"),
        //        .package(url: "http://pubgi.fanapsoft.ir/chat/ios/chat.git", exact: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ChatAppModels",
            dependencies: ["Chat", "AdditiveUI"]
        ),
        .testTarget(
            name: "ChatAppModelsTests",
            dependencies: ["ChatAppModels"],
            resources: [
                .copy("Resources/icon.png")
            ]
        ),
    ]
)
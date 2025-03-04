// swift-tools-version:6.0

import PackageDescription
import Foundation

let package = Package(
    name: "FFMpegKitContainer",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        .macCatalyst(.v15),
    ],
    products: [
        .library(
            name: "FFMpegKitContainer",
            targets: ["FFMpegKitContainer"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "FFMpegKitContainer",
            dependencies: [
                "ffmpegkit",
                "libavcodec",
                "libavdevice",
                "libavfilter",
                "libavformat",
                "libavutil",
                "libswresample",
                "libswscale"
            ]
        ),
        .binaryTarget(name: "ffmpegkit", path: "Frameworks/ffmpegkit.xcframework"),
        .binaryTarget(name: "libavcodec", path: "Frameworks/libavcodec.xcframework"),
        .binaryTarget(name: "libavdevice", path: "Frameworks/libavdevice.xcframework"),
        .binaryTarget(name: "libavfilter", path: "Frameworks/libavfilter.xcframework"),
        .binaryTarget(name: "libavformat", path: "Frameworks/libavformat.xcframework"),
        .binaryTarget(name: "libavutil", path: "Frameworks/libavutil.xcframework"),
        .binaryTarget(name: "libswresample", path: "Frameworks/libswresample.xcframework"),
        .binaryTarget(name: "libswscale", path: "Frameworks/libswscale.xcframework"),
        .testTarget(
            name: "FFMpegKitContainerTests",
            dependencies: [
                "FFMpegKitContainer",
                "ffmpegkit",
                "libavcodec",
                "libavdevice",
                "libavfilter",
                "libavformat",
                "libavutil",
                "libswresample",
                "libswscale"
            ]
        ),
    ]
)

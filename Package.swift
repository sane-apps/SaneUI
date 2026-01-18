// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SaneUI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SaneUI",
            targets: ["SaneUI"]
        ),
    ],
    targets: [
        .target(
            name: "SaneUI",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SaneUITests",
            dependencies: ["SaneUI"]
        ),
    ]
)

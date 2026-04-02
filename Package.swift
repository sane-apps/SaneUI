// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SaneUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "SaneUI",
            targets: ["SaneUI"]
        ),
        .executable(
            name: "SaneUICatalog",
            targets: ["SaneUICatalog"]
        ),
    ],
    targets: [
        .target(
            name: "SaneUI",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "SaneUICatalog",
            dependencies: ["SaneUI"],
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

// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacModelDB",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "MacModelDB",
            targets: ["MacModelDB"]
        ),
    ],
    targets: [
        .target(
            name: "MacModelDB"
        ),
        .testTarget(
            name: "MacModelDBTests",
            dependencies: ["MacModelDB"]
        ),
    ]
)

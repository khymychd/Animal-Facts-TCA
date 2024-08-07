// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NetworkClient",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(
            name: "NetworkClient",
            targets: ["NetworkClient"]),
    ],
    targets: [
        .target(
            name: "NetworkClient"),
        .testTarget(
            name: "NetworkClientTests",
            dependencies: ["NetworkClient"]),
    ]
)

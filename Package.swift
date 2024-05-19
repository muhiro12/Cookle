// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cookle",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "Cookle",
            targets: ["Library"]
        )
    ],
    targets: [
        .target(
            name: "Library",
            path: "Cookle.swiftpm/Sources"
        )
    ]
)

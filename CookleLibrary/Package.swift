// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CookleLibrary",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "CookleLibrary",
            targets: [
                "CookleLibrary"
            ]
        )
    ],
    targets: [
        .target(
            name: "CookleLibrary"
        ),
        .testTarget(
            name: "CookleLibraryTests",
            dependencies: [
                "CookleLibrary"
            ]
        )
    ]
)

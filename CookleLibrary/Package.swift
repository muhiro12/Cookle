// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let kPackage = Package(
    name: "CookleLibrary",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "CookleLibrary",
            targets: [
                "CookleLibrary"
            ]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/muhiro12/MHPlatform.git",
            "1.0.0"..<"2.0.0"
        )
    ],
    targets: [
        .target(
            name: "CookleLibrary",
            dependencies: [
                .product(
                    name: "MHPlatformCore",
                    package: "MHPlatform"
                )
            ]
        ),
        .testTarget(
            name: "CookleLibraryTests",
            dependencies: [
                "CookleLibrary"
            ],
            path: "Tests/Default"
        )
    ]
)

var package: Package {
    kPackage
}

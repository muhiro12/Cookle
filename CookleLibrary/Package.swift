// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let kPackage = Package(
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
    dependencies: [
        .package(
            url: "https://github.com/muhiro12/SwiftUtilities",
            "1.0.0"..<"2.0.0"
        ),
        .package(
            url: "https://github.com/muhiro12/MHPlatform.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "CookleLibrary",
            dependencies: [
                .product(
                    name: "SwiftUtilities",
                    package: "SwiftUtilities"
                ),
                .product(
                    name: "MHDeepLinking",
                    package: "MHPlatform"
                ),
                .product(
                    name: "MHPreferences",
                    package: "MHPlatform"
                ),
                .product(
                    name: "MHPersistenceMaintenance",
                    package: "MHPlatform"
                )
            ]
        ),
        .testTarget(
            name: "CookleLibraryTests",
            dependencies: [
                "CookleLibrary"
            ]
        )
    ]
)

var package: Package {
    kPackage
}

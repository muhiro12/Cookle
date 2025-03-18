// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cookle",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Cookle",
            targets: [
                "CooklePlaygrounds"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/muhiro12/GoogleMobileAdsWrapper.git", branch: "main"),
        .package(url: "https://github.com/muhiro12/LicenseListWrapper.git", branch: "main"),
        .package(url: "https://github.com/muhiro12/StoreKitWrapper.git", branch: "main"),
        .package(url: "https://github.com/muhiro12/SwiftUtilities.git", "1.0.0"..<"2.0.0")
    ],
    targets: [
        .target(
            name: "CooklePlaygrounds",
            dependencies: [
                .product(name: "GoogleMobileAdsWrapper", package: "GoogleMobileAdsWrapper"),
                .product(name: "LicenseListWrapper", package: "LicenseListWrapper"),
                .product(name: "StoreKitWrapper", package: "StoreKitWrapper"),
                .product(name: "SwiftUtilities", package: "SwiftUtilities")
            ],
            path: ".",
            exclude: [
                "Cookle/Xcode"
            ],
            sources: [
                "Cookle/Sources",
                "Cookle.swiftpm/Sources"
            ],
            resources: [
                .process("Cookle/Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .define("XCODE")
            ]
        )
    ]
)

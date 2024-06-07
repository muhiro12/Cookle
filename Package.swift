// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cookle",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Cookle",
            targets: [
                "CooklePlaygrounds",
                "CooklePackages"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/muhiro12/GoogleMobileAdsWrapper.git", branch: "main"),
        .package(url: "https://github.com/muhiro12/LicenseListWrapper", branch: "main")
    ],
    targets: [
        .target(
            name: "CooklePlaygrounds",
            path: "Cookle.swiftpm",
            exclude: [
                "CookleApp.swift",
                "Package.swift"
            ]
        ),
        .target(
            name: "CooklePackages",
            dependencies: [
                .product(name: "GoogleMobileAdsWrapper", package: "GoogleMobileAdsWrapper"),
                .product(name: "LicenseListWrapper", package: "LicenseListWrapper")
            ],
            path: "Cookle/Packages"
        )
    ]
)

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
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "11.0.0")
    ],
    targets: [
        .target(
            name: "CooklePlaygrounds",
            path: "Cookle.swiftpm/Sources"
        ),
        .target(
            name: "CooklePackages",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: "Cookle/Packages"
        )
    ]
)

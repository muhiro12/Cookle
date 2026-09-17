// swift-tools-version: 6.4

import PackageDescription

let package = Package( // swiftlint:disable:this prefixed_toplevel_constant
    name: "CookleReleaseTools",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/muhiro12/Apogee.git", exact: "1.2.0")
    ]
)

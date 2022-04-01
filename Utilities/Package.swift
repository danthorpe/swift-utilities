// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
        .tvOS("13.0"),
        .watchOS("6.0")
    ],
    products: [
        .library(name: "Concurrency", targets: ["Concurrency"]),
        .library(name: "Utilities", targets: ["Concurrency"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "Concurrency", dependencies: []),
        .testTarget(name: "ConcurrencyTests", dependencies: ["Concurrency"]),
    ]
)

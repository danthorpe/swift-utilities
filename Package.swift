// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
        .tvOS("13.0"),
        .watchOS("7.0")
    ],
    products: [
        .library(name: "Cache", targets: ["Cache"]),
        .library(name: "Concurrency", targets: ["Concurrency"]),
        .library(name: "EnvironmentProviders", targets: ["EnvironmentProviders"]),
        .library(name: "Reachability", targets: ["ReachabilityLive"]),
        .library(name: "ReachabilityMocks", targets: ["ReachabilityMocks"]),
        .library(name: "ShortID", targets: ["ShortID"]),
        .library(name: "Utilities", targets: ["Cache", "Concurrency", "ReachabilityLive", "ShortID"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.2")
    ],
    targets: [
        .target(name: "Cache", dependencies: [
            "EnvironmentProviders",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            .product(name: "OrderedCollections", package: "swift-collections"),
            .product(name: "DequeModule", package: "swift-collections"),
        ]),
        .target(name: "Concurrency", dependencies: []),
        .target(name: "EnvironmentProviders", dependencies: []),
        .target(name: "Reachability", dependencies: []),
        .target(name: "ReachabilityLive", dependencies: ["Reachability"]),
        .target(name: "ReachabilityMocks", dependencies: ["Reachability"]),
        .target(name: "ShortID", dependencies: ["Concurrency"]),
        .testTarget(name: "CacheTests", dependencies: ["Cache"]),
        .testTarget(name: "ConcurrencyTests", dependencies: ["Concurrency"]),
        .testTarget(name: "ShortIDTests", dependencies: ["ShortID"]),
    ]
)

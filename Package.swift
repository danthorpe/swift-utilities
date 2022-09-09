// swift-tools-version: 5.7
import PackageDescription

var package = Package(name: "danthorpe-utilities")

package.platforms = [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v8)
]

package.products = [
    .library(name: "Cache", targets: ["Cache"]),
    .library(name: "EnvironmentProviders", targets: ["EnvironmentProviders"]),
    .library(name: "FileManagerClient", targets: ["FileManagerClient"]),
    .library(name: "Reachability", targets: ["ReachabilityLive"]),
    .library(name: "ReachabilityMocks", targets: ["ReachabilityMocks"]),
    .library(name: "ShortID", targets: ["ShortID"]),
    .library(name: "Utilities", targets: ["Cache", "ReachabilityLive", "ShortID"]),
    .plugin(name: "SwiftFormatPlugin", targets: ["FormatCommand"])
]

package.dependencies = [
    .package(url: "https://github.com/apple/swift-argument-parser.git", branch: "main"),
    .package(url: "https://github.com/apple/swift-async-algorithms", branch: "main"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
    .package(url: "https://github.com/apple/swift-format", branch: "main"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.1"),
    .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.10.0"),
]

package.targets = [

    // MARK: - Cache
    .target(name: "Cache", dependencies: [
        "Extensions",
        "EnvironmentProviders",
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "DequeModule", package: "swift-collections"),
    ]),

    // MARK: - Extensions
    .target(name: "Extensions"),

    // MARK: - Environment Providers
    .target(name: "EnvironmentProviders"),

    // MARK: - File Manager Client
    .target(name: "FileManagerClient", dependencies: [
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
    ]),

    // MARK: - Reachability
    .target(name: "Reachability"),
    .target(name: "ReachabilityLive", dependencies: ["Reachability"]),
    .target(name: "ReachabilityMocks", dependencies: ["Reachability"]),

    // MARK: - ShortID
    .target(name: "ShortID", dependencies: ["Concurrency"]),

    // MARK: - Plugins
    .plugin(
        name: "FormatCommand",
        capability: .command(
            intent: .sourceCodeFormatting(),
            permissions: [
                .writeToPackageDirectory(reason: "This command reformats source files"),
            ]
        ),
        dependencies: [
            .product(name: "swift-format", package: "swift-format")
        ]
    ),

    // MARK: - Deprecated
    .target(name: "Concurrency", dependencies: []),

    // MARK: - Tests
    .testTarget(name: "CacheTests", dependencies: ["Cache"]),
    .testTarget(name: "ConcurrencyTests", dependencies: ["Concurrency"]),
    .testTarget(name: "ShortIDTests", dependencies: ["ShortID"]),
]

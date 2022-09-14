// swift-tools-version: 5.7
import PackageDescription

var package = Package(name: "danthorpe-utilities")

// MARK: - Platforms

package.platforms = [
    .macOS(.v12),
    .iOS(.v15),
    .tvOS(.v15),
    .watchOS(.v8)
]

// MARK: - Products

package.products = [
    .library(name: "Cache", targets: ["Cache"]),
    .library(name: "EnvironmentProviders", targets: ["EnvironmentProviders"]),
    .library(name: "FileManagerClient", targets: ["FileManagerClient"]),
    .library(name: "Reachability", targets: ["ReachabilityLive"]),
    .library(name: "ReachabilityMocks", targets: ["ReachabilityMocks"]),
    .library(name: "ShortID", targets: ["ShortID"]),
    .library(name: "Utilities", targets: ["Cache", "ReachabilityLive", "ShortID"]),
]

// MARK: - Dependencies

package.dependencies = [
    .package(url: "https://github.com/apple/swift-argument-parser.git", branch: "main"),
    .package(url: "https://github.com/apple/swift-async-algorithms", branch: "main"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.1"),
    .package(url: "https://github.com/danthorpe/danthorpe-plugins", branch: "main"),
]

// MARK: - Targets

var targets: [Target] = [

    .target(
        name: "Cache",
        dependencies: [
            "Extensions",
            "EnvironmentProviders",
            .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
            .product(name: "OrderedCollections", package: "swift-collections"),
            .product(name: "DequeModule", package: "swift-collections"),
        ]
    ),

    .target(name: "Extensions"),

    .target(name: "EnvironmentProviders"),

    .target(name: "FileManagerClient", dependencies: [
        .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay")
    ]),

    .target(name: "Reachability"),
    .target(name: "ReachabilityLive", dependencies: ["Reachability"]),
    .target(name: "ReachabilityMocks", dependencies: ["Reachability"]),

    .target(name: "ShortID", dependencies: ["Concurrency"]),

    .target(name: "Concurrency", dependencies: []),

    .testTarget(name: "CacheTests", dependencies: ["Cache"]),
    .testTarget(name: "ConcurrencyTests", dependencies: ["Concurrency"]),
    .testTarget(name: "ShortIDTests", dependencies: ["ShortID"]),
]

// Set SwiftLint plugin
targets = targets.update(.regular, .test, plugins: [
    .plugin(name: "SwiftLintPlugin", package: "danthorpe-plugins"),
])

// Set the targets
package.targets = targets


// MARK: - Helpers

extension Array where Element == Target {
    func update(_ types: Target.TargetType..., plugins newPlugins: [Target.PluginUsage]) -> Self {
        guard !newPlugins.isEmpty else { return self }
        return map { target in
            if types.contains(target.type) {
                var plugins = target.plugins ?? []
                plugins.append(contentsOf: newPlugins)
                target.plugins = plugins
            }
            return target
        }
    }
}

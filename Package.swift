// swift-tools-version: 5.7
import PackageDescription

var package = Package(name: "danthorpe-utilities")

// MARK: - Platforms

package.platforms = [
    .macOS(.v12),
    .iOS(.v14),
    .tvOS(.v14),
    .watchOS(.v7)
]

// MARK: - External Dependencies

package.dependencies = [
    .package(url: "https://github.com/apple/swift-argument-parser.git", branch: "main"),
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.2"),
    .package(url: "https://github.com/danthorpe/danthorpe-plugins", branch: "main"),
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.44.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.5.0"),
]

// MARK: - Name
let Cache = "Cache"
let EnvironmentProviders = "EnvironmentProviders"
let Extensions = "Extensions"
let FileManagerClient = "FileManagerClient"
let Protected = "Protected"
let Reachability = "Reachability"
let ShortID = "ShortID"
let Utilities = "Utilities"

private extension String {
    var tests: String { "\(self)Tests" }
    var mocks: String { "\(self)Mocks" }
    var live: String { "\(self)Live" }
}

// MARK: - Products

package.products = [
    .library(name: Cache, targets: [Cache]),
    .library(name: EnvironmentProviders, targets: [EnvironmentProviders]),
    .library(name: FileManagerClient, targets: [FileManagerClient]),
    .library(name: Protected, targets: [Protected]),
    .library(name: Reachability, targets: [Reachability]),
    .library(name: ShortID, targets: [ShortID]),
]

// MARK: - Targets

extension Target {
    static let cache: Target = .target(
        name: Cache,
        dependencies: [
            .extensions,
            .environmentProviders,
            .orderedCollection,
            .deque
        ]
    )
    static let cacheTests: Target = .testTarget(
        name: Cache.tests,
        dependencies: [ .cache ]
    )
    static let protected: Target = .target(
        name: Protected
    )
    static let protectedTests: Target = .testTarget(
        name: Protected.tests,
        dependencies: [ .protected ]
    )
    static let extensions: Target = .target(
        name: Extensions
    )
    static let environmentProviders: Target = .target(
        name: EnvironmentProviders
    )
    static let fileManagerClient: Target = .target(
        name: FileManagerClient,
        dependencies: [ .xctestDynamicOverlay ]
    )
    static let reachability: Target = .target(
        name: Reachability,
        dependencies: [ .dependencies, .xctestDynamicOverlay ]
    )
    static let shortID: Target = .target(
        name: ShortID,
        dependencies: [ .dependencies, .protected ]
    )
    static let shortIDTests: Target = .testTarget(
        name: ShortID.tests,
        dependencies: [ .shortID ]
    )
}

package.targets = [
    .cache,
    .cacheTests,
    .protected,
    .protectedTests,
    .extensions,
    .environmentProviders,
    .fileManagerClient,
    .reachability,
    .shortID,
    .shortIDTests
].update(.regular, .test, plugins: [
    .swiftLint,
])

// MARK: - Internal Dependencies
extension Target.Dependency {
    static let cache: Target.Dependency = .target(
        name: Cache
    )
    static let protected: Target.Dependency = .target(
        name: Protected
    )
    static let extensions: Target.Dependency = .target(
        name: Extensions
    )
    static let environmentProviders: Target.Dependency = .target(
        name: EnvironmentProviders
    )
    static let shortID: Target.Dependency = .target(
        name: ShortID
    )
}

// MARK: - 3rd Party Dependencies
extension Target.Dependency {
    static let dependencies: Target.Dependency = .product(
        name: "Dependencies", package: "swift-composable-architecture"
    )
    static let orderedCollection: Target.Dependency = .product(
        name: "OrderedCollections", package: "swift-collections"
    )
    static let deque: Target.Dependency = .product(
        name: "DequeModule", package: "swift-collections"
    )
    static let xctestDynamicOverlay: Target.Dependency = .product(
        name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"
    )
}

// MARK: - Plugin Usages
extension Target.PluginUsage {
    static let swiftLint: Target.PluginUsage = .plugin(
        name: "SwiftLint", package: "danthorpe-plugins"
    )
}

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

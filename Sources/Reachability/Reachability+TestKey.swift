import AsyncAlgorithms
import Dependencies
import Foundation
import XCTestDynamicOverlay

@available(iOS 13.0, *)
@available(macOS 13, *)
extension Reachability {

  static public let previewValue: Reachability = .unsatisfied

  public static let satisfied = continuous(.satisfied)

  public static let unsatisfied = continuous(.unsatisfied)

  public static let intermittent = every(.seconds(2)) {
    Bool.random() ? .satisfied : .unsatisfied
  }

  internal static func continuous(_ status: Path.Status) -> Self {
    every(.seconds(5)) { status }
  }

  internal static func every(_ duration: Duration, status: @escaping @Sendable () -> Path.Status) -> Self {
    Reachability {
      AsyncStream { continuation in
        @Dependency(\.continuousClock) var clock
        Task {
          try await clock.sleep(for: duration)
          continuation.yield(Path(status: status()))
        }
      }
    }
  }
}

extension Reachability: TestDependencyKey {
  static public let testValue = Reachability(monitor: unimplemented("\(Self.self).monitor"))
}

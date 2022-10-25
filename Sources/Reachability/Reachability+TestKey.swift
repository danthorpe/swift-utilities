import Combine
import Dependencies
import Foundation
import XCTestDynamicOverlay

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Reachability {

    static let satisfied = always(.satisfied)

    static let unsatisfied = always(.unsatisfied)

    internal static func always(_ status: Path.Status) -> Self {
        let path = Path(status: status)
        let publisher = Just(path)
            .eraseToAnyPublisher()
        return Self(monitor: publisher)
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Reachability {

    static let intermittent = Self(
        monitor: Timer.publish(every: 2, on: .main, in: .default)
            .autoconnect()
            .scan(Path.Status.satisfied, { status, _ in
                status == .satisfied ? .unsatisfied : .satisfied
            })
            .map { Path(status: $0) }
            .eraseToAnyPublisher()
    )
}

extension Reachability: TestDependencyKey {
    static public let testValue: Reachability = .satisfied
    static public let previewValue: Reachability = .unsatisfied
}

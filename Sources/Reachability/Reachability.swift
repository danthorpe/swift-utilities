import Combine
import Foundation

// MARK: - Client Interface

public struct Reachability {
    public var monitor: AnyPublisher<Path, Never>

    public init(monitor: AnyPublisher<Path, Never>) {
        self.monitor = monitor
    }
}

// MARK: - Data Interface

extension Reachability {
    public struct Path: Hashable {
        public enum Status: Hashable {
            case satisfied
            case unsatisfied
            case requiresConnection
        }

        public let status: Status

        public init(status: Status) {
            self.status = status
        }
    }
}

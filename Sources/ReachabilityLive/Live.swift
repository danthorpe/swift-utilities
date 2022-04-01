import Combine
import Foundation
import Network
import Reachability

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public extension Reachability {

    static let live = live(queue: .main)

    static func live(queue: DispatchQueue) -> Self {
        let monitor = NWPathMonitor()
        let subject = PassthroughSubject<NWPath, Never>()
        monitor.pathUpdateHandler = subject.send

        return Self(
            monitor: subject
                .handleEvents(
                    receiveSubscription: { _ in monitor.start(queue: queue) },
                    receiveCancel: monitor.cancel
                )
                .map(Reachability.Path.init(rawValue:))
                .removeDuplicates()
                .eraseToAnyPublisher()
        )
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension Reachability.Path.Status {
    init(rawValue: NWPath.Status) {
        switch rawValue {
        case .satisfied:
            self = .satisfied
        case .unsatisfied:
            self = .unsatisfied
        case .requiresConnection:
            self = .requiresConnection
        @unknown default:
            fatalError()
        }
    }
}

@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension Reachability.Path {
    init(rawValue: NWPath) {
        self.init(status: .init(rawValue: rawValue.status))
    }
}

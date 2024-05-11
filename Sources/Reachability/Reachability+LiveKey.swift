#if canImport(Network)
import AsyncAlgorithms
import Dependencies
import Foundation
import Network

@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension Reachability {
  public static let live = Reachability {
    AsyncStream { continuation in
      Task { @MainActor in
        let monitor = NWPathMonitor()
        monitor.start(queue: .main)
        monitor.pathUpdateHandler = { path in
          continuation.yield(Path(status: .init(rawValue: path.status)))
        }
      }
    }
    .removeDuplicates()
    .eraseToStream()
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

extension Reachability: DependencyKey {
  static public let liveValue: Reachability = .live
}
#endif

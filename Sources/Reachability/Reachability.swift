// MARK: - Client Interface

@available(iOS 13.0, *)
@available(macOS 10.15, *)
public struct Reachability {
  public var monitor: () -> AsyncStream<Path>

  public init(monitor: @escaping () -> AsyncStream<Path>) {
    self.monitor = monitor
  }
}

// MARK: - Data Interface

@available(iOS 13.0, *)
@available(macOS 10.15, *)
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

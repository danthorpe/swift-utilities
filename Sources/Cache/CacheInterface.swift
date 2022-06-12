import Combine
import Foundation
import os.log

public protocol CacheInterface: Actor {
    associatedtype Key: Hashable
    associatedtype Value

    var count: Int { get }
    func value(forKey key: Key) -> Value?
    func insert(_ value: Value, duration: TimeInterval, forKey key: Key)
    func removeValue(forKey key: Key)
}


@available(iOS 14.0, *)
@available(macOS 11.0, *)
extension Logger {
    @TaskLocal
    static var cache: Logger? = Bundle.main.bundleIdentifier.map {
        Logger(subsystem: $0, category: "Cache")
    }
}

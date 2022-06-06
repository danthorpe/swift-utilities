import Combine
import Foundation

public protocol Cache: Actor {
    associatedtype Key: Hashable
    associatedtype Value

    var count: Int { get }
    func value(forKey key: Key) -> Value?
    func insert(_ value: Value, duration: TimeInterval, forKey key: Key)
    func removeValue(forKey key: Key)
}

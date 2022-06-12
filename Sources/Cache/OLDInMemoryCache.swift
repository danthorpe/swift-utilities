import Combine
import EnvironmentProviders
import Foundation

public final class OLDInMemoryCache<Key: Hashable, Value> {
    typealias Storage = OLDCacheStorage<Key, Value>
    typealias CachedValue = Storage.CachedValue

    private(set) var storage: Storage

    public var count: Int {
        storage.count
    }

    init(storage: Storage) {
        self.storage = storage
    }

    convenience init(size: Int, values: [CachedValue]) {
        self.init(storage: .init(size: size, values: values))
    }

    public convenience init(size: Int) {
        self.init(storage: .init(size: size, values: []))
    }

    public func value(forKey key: Key) -> Value? {
        storage.cachedValue(forKey: key)?.value
    }

    public func insert(_ value: Value, duration: TimeInterval, forKey key: Key) {
        let date = DateProvider.now().addingTimeInterval(duration)
        storage.insert(CachedValue(key: key, value: value, expires: date))
    }

    public func removeValue(forKey key: Key) {
        storage.removeCacheValue(forKey: key)
    }
}

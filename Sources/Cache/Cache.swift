import Calendaring
import Combine
import Foundation

@available(macOS 10.15, *)
public actor Cache<Key: Hashable, Value> {
    private let keyTracker: KeyTracker
    private let storage: NSCache<CacheKey, CachedValue>

    public convenience init(maximumCount: Int) {
        self.init(maximumCount: maximumCount, values: [])
    }

    private init(maximumCount: Int, values: [CachedValue]) {
        keyTracker = .init(keys: Set(values.map(\.key)))
        self.storage = {
            let storage = NSCache<CacheKey, CachedValue>()
            values.forEach { cachedValue in
                storage.setObject(cachedValue, forKey: CacheKey(cachedValue.key))
            }
            return storage
        }()
        self.storage.countLimit = maximumCount
        self.storage.delegate = keyTracker
    }

    public func value(forKey key: Key) -> Value? {
        cachedValue(forKey: key)?.value
    }

    public func insert(_ value: Value, duration: TimeInterval, forKey key: Key) {
        let date = DateProvider.now().addingTimeInterval(duration)
        insert(CachedValue(key: key, value: value, expires: date))
    }

    public func removeValue(forKey key: Key) {
        storage.removeObject(forKey: CacheKey(key))
        keyTracker.keys.remove(key)
    }
}

@available(macOS 10.15, *)
private extension Cache {

    nonisolated func cachedValue(forKey key: Key) -> CachedValue? {
        guard let cached = storage.object(forKey: CacheKey(key)) else {
            return nil
        }
        guard DateProvider.now() < cached.expirationDate else {
            removeCacheValue(forKey: key)
            return nil
        }
        return cached
    }

    nonisolated func removeCacheValue(forKey key: Key) {
        storage.removeObject(forKey: CacheKey(key))
        keyTracker.keys.remove(key)
    }

    func insert(_ cachedValue: CachedValue) {
        storage.setObject(cachedValue, forKey: CacheKey(cachedValue.key))
        keyTracker.keys.insert(cachedValue.key)
    }
}

@available(macOS 10.15, *)
private extension Cache {
    final class CacheKey: NSObject {
        let key: Key

        override var hash: Int {
            key.hashValue
        }

        init(_ key: Key) {
            self.key = key
        }

        override func isEqual(_ other: Any?) -> Bool {
            guard let value = other as? CacheKey else {
                return false
            }
            return value.key == key
        }
    }

    final class CachedValue {
        let key: Key
        let value: Value
        let expirationDate: Date

        init(key: Key, value: Value, expires: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expires
        }
    }
}

@available(macOS 10.15, *)
private extension Cache {
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys: Set<Key>

        init(keys: Set<Key>) {
            self.keys = keys
        }

        func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
            guard let cachedValue = obj as? CachedValue else { return }
            keys.remove(cachedValue.key)
        }
    }
}

@available(macOS 10.15, *)
extension Cache.CachedValue: Codable where Key: Codable, Value: Codable { }

@available(macOS 10.15, *)
extension Cache: Codable where Key: Codable, Value: Codable {
    enum CodingKeys: CodingKey {
        case duration, maximumCount, cachedValues
    }
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let maximumCount = try container.decode(Int.self, forKey: .maximumCount)
        let values = try container.decode([CachedValue].self, forKey: .cachedValues)
        self.init(maximumCount: maximumCount, values: values)
    }

    public nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(storage.countLimit, forKey: .maximumCount)
        try container.encode(keyTracker.keys.compactMap(cachedValue(forKey:)), forKey: .cachedValues)
    }
}

@available(macOS 10.15, *)
extension Cache where Key: Codable, Value: Codable {
    public func saveToDisk<Encoder: TopLevelEncoder>(
        withFileName name: String,
        encoder: Encoder,
        using fileManager: FileManager = .default
    ) throws where Encoder.Output == Data {
        guard let directoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return
        }
        let fileURL = directoryURL.appendingPathComponent(name + ".cache")
        let data = try encoder.encode(self)
        try data.write(to: fileURL)
    }
}

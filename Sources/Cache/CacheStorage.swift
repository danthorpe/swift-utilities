import Calendaring
import Foundation

struct CacheStorage<Key: Hashable, Value> {

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

    let keyTracker: KeyTracker
    let nscache: NSCache<CacheKey, CachedValue>

    init(size: Int, values: [CachedValue]) {
        keyTracker = .init(keys: Set(values.map(\.key)))
        self.nscache = {
            let storage = NSCache<CacheKey, CachedValue>()
            values.forEach { cachedValue in
                storage.setObject(cachedValue, forKey: CacheKey(cachedValue.key))
            }
            return storage
        }()
        self.nscache.countLimit = size
        self.nscache.delegate = keyTracker
    }

    mutating func set(size newSize: Int) {
        nscache.countLimit = newSize
    }
}

extension CacheStorage {

    var count: Int {
        keyTracker.keys.count
    }

    func contains(key: Key) -> Bool {
        keyTracker.keys.contains(key) && nscache.object(forKey: CacheKey(key)) != nil
    }

    func cachedValue(forKey key: Key) -> CachedValue? {
        guard let cached = nscache.object(forKey: CacheKey(key)) else {
            return nil
        }
        guard DateProvider.now() < cached.expirationDate else {
            removeCacheValue(forKey: key)
            return nil
        }
        return cached
    }

    func removeCacheValue(forKey key: Key) {
        nscache.removeObject(forKey: CacheKey(key))
        keyTracker.keys.remove(key)
    }

    func insert(_ cachedValue: CachedValue) {
        nscache.setObject(cachedValue, forKey: CacheKey(cachedValue.key))
        keyTracker.keys.insert(cachedValue.key)
    }

    func cachedValues() -> [CachedValue] {
        keyTracker.keys.compactMap(cachedValue(forKey:))
    }
}

// MARK: - Codable

extension CacheStorage.CachedValue: Codable where Key: Codable, Value: Codable { }

extension CacheStorage: Codable where Key: Codable, Value: Codable {
    enum CodingKeys: CodingKey {
        case size, cachedValues
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let size = try container.decode(Int.self, forKey: .size)
        let values = try container.decode([CachedValue].self, forKey: .cachedValues)
        self.init(size: size, values: values)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nscache.countLimit, forKey: .size)
        try container.encode(cachedValues(), forKey: .cachedValues)
    }
}

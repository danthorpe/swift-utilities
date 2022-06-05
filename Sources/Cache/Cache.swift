import Calendaring
import Combine
import Foundation

public actor Cache<Key: Hashable, Value> {
    private var storage: Storage
    private var subscriptions: Set<AnyCancellable> = []

    public var count: Int {
        storage.count
    }

    public convenience init(size: Int) {
        self.init(size: size, values: [])
    }

    private init(size: Int, values: [CachedValue]) {
        self.storage = .init(size: size, values: values)
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

extension Cache where Key: Codable, Value: Codable {
    private func fileURL(
        withFileName name: String,
        using fileManager: FileManager = .default
    ) -> URL? {
        fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(name + ".cache")
    }

    public func saveToDisk<Encoder: TopLevelEncoder>(
        withFileName name: String,
        encoder: Encoder,
        using fileManager: FileManager = .default
    ) throws where Encoder.Output == Data {
        guard let fileURL = fileURL(withFileName: name, using: fileManager) else { return }
        let data = try encoder.encode(storage)
        try data.write(to: fileURL)
    }

    public func restoreFromDisk<Decoder: TopLevelDecoder>(
        withFileName name: String,
        decoder: Decoder,
        using fileManager: FileManager = .default
    ) async throws where Decoder.Input == Data {
        guard let fileURL = fileURL(withFileName: name, using: fileManager) else { return }
        let data = try Data(contentsOf: fileURL)
        storage = try decoder.decode(Storage.self, from: data)
    }
}


// MARK: - Implementation Details

private extension Cache {

    typealias CacheKey = Storage.CacheKey
    typealias CachedValue = Storage.CachedValue

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

    struct Storage {

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
    }
}

private extension Cache.Storage {

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

private extension Cache {

    func merge(with other: Cache<Key, Value>.Storage) async {
        other.cachedValues()
            .filter { storage.contains(key: $0.key) }
            .forEach(storage.insert)
    }
}

// MARK: - Codable

extension Cache.Storage.CachedValue: Codable where Key: Codable, Value: Codable { }

extension Cache.Storage: Codable where Key: Codable, Value: Codable {
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

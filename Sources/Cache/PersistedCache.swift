import Calendaring
import Combine
import Foundation

#if canImport(UIKit) || canImport(AppKit)
public actor PersistedCache<Key: Hashable, Value>: Cache where Key: Codable, Value: Codable {
    typealias Storage = CacheStorage<Key, Value>
    public typealias ReadData = () -> Data?
    public typealias WriteData = (Data) throws -> Void

    public let cache: InMemoryCache<Key, Value>
    var subscription: AnyCancellable?

    public init<Encoder: TopLevelEncoder, Decoder: TopLevelDecoder, Upstream: Publisher>(
        size: Int,
        decoder: Decoder,
        read: @escaping ReadData,
        encoder: Encoder,
        write: @escaping WriteData,
        upstream: Upstream
    ) where Encoder.Output == Data, Decoder.Input == Data, Upstream.Output == Notification, Upstream.Failure == Never {
        if let data = read(), var storage = try? decoder.decode(Storage.self, from: data) {
            print("Read \(storage.count) items from disk cache")
            storage.set(size: size)
            self.cache = .init(storage: storage)
        }
        else {
            self.cache = .init(size: size)
        }

        self.subscription = upstream
            .sink { [weak self] _ in
                guard let this = self else { return }
                do {
                    let data = try encoder.encode(this.cache.storage)
                    try write(data)
                }
                catch {
                    print("Error saving cache to disk: \(error)")
                }
            }
    }

    public convenience init(
        size: Int,
        fileName: String,
        fileManager: FileManager = .default,
        notificationCenter: NotificationCenter = .default
    ) {
        let fileURL = fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName + ".cache")

        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary

        self.init(
            size: size,
            decoder: PropertyListDecoder(),
            read: {
                guard let fileURL = fileURL else { return nil }
                return try? Data(contentsOf: fileURL)
            },
            encoder: encoder,
            write: { data in
                if let fileURL = fileURL {
                    print("Writing to: \(fileURL)")
                    try data.write(to: fileURL)
                }
            },
            upstream: notificationCenter.publisher(for: .willResignActiveNotification)
        )
    }

    public var count: Int {
        cache.count
    }

    public func value(forKey key: Key) -> Value? {
        cache.value(forKey: key)
    }

    public func insert(_ value: Value, duration: TimeInterval, forKey key: Key) {
        cache.insert(value, duration: duration, forKey: key)
    }

    public func removeValue(forKey key: Key) {
        cache.removeValue(forKey: key)
    }
}

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

extension Notification.Name {
    static let willResignActiveNotification: Self = {
        #if canImport(AppKit)
        return NSApplication.willResignActiveNotification
        #elseif canImport(UIKit)
        return UIApplication.willResignActiveNotification
        #endif
    }()
}
#endif

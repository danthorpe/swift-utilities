import EnvironmentProviders
import Combine
import Foundation
import os.log

#if canImport(UIKit) || canImport(AppKit)
@available(iOS 14.0, *)
@available(macOS 11.0, *)
public actor OLDPersistedCache<Key: Hashable, Value>: CacheInterface where Key: Codable, Value: Codable {
    typealias Storage = OLDCacheStorage<Key, Value>
    public typealias ReadData = () -> Data?
    public typealias WriteData = (Data) throws -> Void

    public let cache: OLDInMemoryCache<Key, Value>
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
            Logger.cache?.info("🗃 Read \(storage.count) items from disk cache.")
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
                    Logger.cache?.info("⚠️ Error saving cache to disk: \(String(describing: error))")
                }
            }
    }

    public convenience init(
        size: Int,
        fileURL: URL,
        notificationCenter: NotificationCenter
    ) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary

        self.init(
            size: size,
            decoder: PropertyListDecoder(),
            read: {
                try? Data(contentsOf: fileURL)
            },
            encoder: encoder,
            write: { data in
                Logger.cache?.info("🗄 Writing items to disk cache: \(fileURL.absoluteString)")
                try data.write(to: fileURL)
            },
            upstream: notificationCenter
                .publisher(for: .willResignActiveNotification)
                .merge(with: notificationCenter.publisher(for: .willTerminateNotification))
        )
    }

    public convenience init?(
        size: Int,
        fileName: String,
        fileManager: FileManager = .default,
        notificationCenter: NotificationCenter = .default
    ) {
        guard let fileURL = fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(fileName + ".cache")
        else { return nil }
        self.init(size: size, fileURL: fileURL, notificationCenter: notificationCenter)
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
#endif

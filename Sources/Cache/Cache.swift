import AsyncAlgorithms
import Combine
import Extensions
import DequeModule
import Foundation
import OrderedCollections
import os.log
import EnvironmentProviders

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public actor Cache<Key: Hashable, Value> {
    public typealias Storage = Dictionary<Key, CachedValue>

    public enum EvictionEvent {
        case memoryPressure, countLimit, valueExpiry
    }

    public enum Event {
        case willEvictCachedValues(Storage, reason: EvictionEvent)
        case shouldPersistCachedValues(Storage)
    }

    enum SystemEvent {
        enum MemoryPressure {
            case warning, normal
        }
        case applicationWillSuspend
        case applicationDidReceiveMemoryPressure(MemoryPressure)
    }

    typealias Access = Deque<Key>

    public var limit: UInt

    var logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "works.dan.swift-utilities", category: "Cache")
    var absoluteUpperLimit: UInt {
        limit + max(10, UInt(Double(limit) * 0.1))
    }
    var data: Storage
    var access: Access
    var eventDelegate = PassthroughSubject<Event, Never>()
    var evictionsDelegate = PassthroughSubject<EvictionEvent, Never>()

    var evictions: some AsyncSequence {
        evictionsDelegate.values
    }

    init<SystemEvents: AsyncSequence>(limit: UInt, data: Storage, didReciveSystemEvents stream: SystemEvents) where SystemEvents.Element == SystemEvent {
        self.limit = limit
        self.data = data
        self.access = .init(data.keys)
        Task {
            await handleEvictionEvents()
            await startReceivingSystemEvents(from: stream)
        }
    }

    public init(limit: UInt, data: Storage) {
        self.init(limit: limit, data: data, didReciveSystemEvents: SystemEvent.publisher().values)
    }

    public init(limit: UInt, items: Dictionary<Key, Value>, duration: TimeInterval) {
        self.init(
            limit: limit,
            data: items.reduce(into: Storage()) { storage, element in
                storage[element.key] = CachedValue(value: element.value, duration: duration)
            },
            didReciveSystemEvents: SystemEvent.publisher().values
        )
    }

    @available(macOS 12.0, *)
    @available(iOS 15.0, *)
    public init(limit: UInt) {
        self.init(limit: limit, data: .init(), didReciveSystemEvents: SystemEvent.publisher().values)
    }

    func startReceivingSystemEvents<SystemEvents: AsyncSequence>(from stream: SystemEvents) async where SystemEvents.Element == SystemEvent {
        do {
            for try await event in stream {
                switch event {
                case .applicationWillSuspend:
                    eventDelegate.send(.shouldPersistCachedValues(data))
                case .applicationDidReceiveMemoryPressure(.warning):
                    evictionsDelegate.send(.memoryPressure)
                case .applicationDidReceiveMemoryPressure(.normal):
                    break
                }
            }
        } catch {
            logger.error("🗂 ⚠️ Caught error receiving system events: \(error)")
        }
    }

    func handleEvictionEvents() async {
        do {
            for try await eviction in evictions {
                if let eviction = eviction as? EvictionEvent {
                    let countToRemove = calculateEvictionCount(from: eviction)
                    let rangeToRemove = countToRemove..<access.endIndex
                    evictCachedValues(forKeys: access[rangeToRemove], reason: eviction)
                }
            }
        }
        catch {
            logger.error("🗂 ⚠️ Caught error handling eviction event: \(error)")
        }
    }

    func calculateEvictionCount(from event: EvictionEvent) -> Int {
        switch event {
        case .memoryPressure:
            return access.count / 2
        case .countLimit:
            return access.count - Int(limit)
        case .valueExpiry:
            return 1 // Not required to be calculated here, as eviction is key based.
        }
    }
}

// MARK: - Nested Types
extension Cache {
    public struct CachedValue {
        public let value: Value
        public let cost: UInt64
        public let expirationDate: Date

        init(value: Value, cost: UInt64 = 0, duration: TimeInterval) {
            self.value = value
            self.cost = cost
            self.expirationDate = DateProvider.now().addingTimeInterval(duration)
        }
    }
}

extension Cache.CachedValue: Codable where Value: Codable { }

// MARK: - Public API

public extension Cache {

    var events: some AsyncSequence {
        eventDelegate.values
    }

    var count: Int {
        data.count
    }

    func value(forKey key: Key) -> Value? {
        cachedValue(forKey: key)?.value
    }

    func insert(_ value: Value, forKey key: Key, cost: UInt64 = .zero, duration: TimeInterval) {
        let cachedValue = CachedValue(value: value, cost: cost, duration: duration)
        insertCachedValue(cachedValue, forKey: key, duration: duration)
    }

    func removeValue(forKey key: Key) {
        removeCachedValue(forKey: key)
    }
}

// MARK: - Private API

private extension Cache {

    func cachedValue(forKey key: Key) -> CachedValue? {
        guard let cached = data[key] else { return nil }
        guard DateProvider.now() < cached.expirationDate else {
            removeCachedValue(forKey: key)
            return nil
        }
        updateAccess(for: key)
        return cached
    }

    func insertCachedValue(_ cachedValue: CachedValue, forKey key: Key, duration: TimeInterval) {
        data[key] = cachedValue
        updateAccess(for: key)
        guard 0 < duration else { return }
        Task {
            try await Task.sleep(seconds: duration)
            evictCachedValues(forKeys: [key], reason: .valueExpiry)
        }
    }

    func removeCachedValue(forKey key: Key) {
        data[key] = nil
        removeAccess(for: key)
    }

    func evictCachedValues(forKeys keys: some Collection<Key>, reason event: EvictionEvent) {
        let slice = data.slice(keys)
        logger.info("🗂 Will evict \(keys.map(String.init(describing:))) due to: \(event.description)")
        eventDelegate.send(.willEvictCachedValues(slice, reason: event))
        slice.keys.forEach(removeCachedValue(forKey:))
    }

    func updateAccess(for key: Key) {
        removeAccess(for: key)
        access.insert(key, at: 0)
        if access.count >= absoluteUpperLimit {
            evictionsDelegate.send(.countLimit)
        }
    }

    func removeAccess(for key: Key) {
        if let index = access.firstIndex(of: key) {
            access.remove(at: index)
        }
    }
}


// MARK: - Other Implementation Details

extension Cache.SystemEvent {

    static func publisher(notificationCenter center: NotificationCenter = .default) -> AnyPublisher<Self, Never> {
        let subject = PassthroughSubject<Cache.SystemEvent, Never>()
        let queue = DispatchQueue(label: "dan.works.swift-utilities.cache.memory-pressure")
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: queue)
        source.setEventHandler {
            var event = source.data
            event.formIntersection([.critical, .warning, .normal])
            if event.contains([.warning, .critical]) {
                subject.send(.applicationDidReceiveMemoryPressure(.warning))
            }
            else {
                subject.send(.applicationDidReceiveMemoryPressure(.normal))
            }
        }

        return Publishers
            .Merge(
                center.publisher(for: .willResignActiveNotification),
                center.publisher(for: .willTerminateNotification)
            )
            .map { _ in Cache.SystemEvent.applicationWillSuspend }
        #if os(iOS)
            .merge(with: center.publisher(for: UIApplication.didReceiveMemoryWarningNotification).map { _ in Cache.SystemEvent.applicationDidReceiveMemoryPressure(.warning) })
        #endif
            .merge(with: subject.handleEvents(receiveSubscription: { _ in }))
            .eraseToAnyPublisher()
    }
}

extension Cache.EvictionEvent: CustomStringConvertible {

    public var description: String {
        switch self {
        case .memoryPressure:
            return "Memory Pressure"
        case .countLimit:
            return "Count Limit"
        case .valueExpiry:
            return "Value Expiry"
        }
    }
}

extension Notification.Name {
    static let willResignActiveNotification: Self = {
#if canImport(AppKit)
        return NSApplication.willResignActiveNotification
#elseif canImport(UIKit)
        return UIApplication.willResignActiveNotification
#endif
    }()

    static let willTerminateNotification: Self = {
#if canImport(AppKit)
        return NSApplication.willTerminateNotification
#elseif canImport(UIKit)
        return UIApplication.willTerminateNotification
#endif
    }()
}

extension Dictionary {
    func slice(_ keys: some Collection<Key>) -> Dictionary<Key, Value> {
        keys.reduce(into: Self()) { accumulator, key in
            if let value = self[key] {
                accumulator[key] = value
            }
        }
    }
}

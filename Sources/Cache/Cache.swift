import Foundation
import Combine
import DequeModule
import OrderedCollections
import EnvironmentProviders

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public actor Cache<Key: Hashable, Value> {
    public typealias Storage = Dictionary<Key, CachedValue>

    public enum Event {
        case willEvictCachedValues(Storage)
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

    var limit: UInt
    var data: Storage
    var access: Access
    var subject = PassthroughSubject<Event, Never>()

    @available(macOS 12.0, *)
    @available(iOS 15.0, *)
    public var events: some AsyncSequence {
        subject.values
    }

    init<SystemEvents: AsyncSequence>(limit: UInt, data: Storage, didReciveSystemEvents stream: SystemEvents) where SystemEvents.Element == SystemEvent {
        self.limit = limit
        self.data = data
        self.access = .init(data.keys)
        Task {
            await startReceivingSystemEvents(from: stream)
        }
    }

    @available(macOS 12.0, *)
    @available(iOS 15.0, *)
    public convenience init(limit: UInt, data: Storage) {
        self.init(
            limit: limit,
            data: data,
            didReciveSystemEvents: SystemEvent.publisher().values
        )
    }

    @available(macOS 12.0, *)
    @available(iOS 15.0, *)
    public convenience init(limit: UInt, items: Dictionary<Key, Value>, duration: TimeInterval) {
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
    public convenience init(limit: UInt) {
        self.init(limit: limit, data: .init(), didReciveSystemEvents: SystemEvent.publisher().values)
    }

    func startReceivingSystemEvents<SystemEvents: AsyncSequence>(from stream: SystemEvents) async where SystemEvents.Element == SystemEvent {
        do {
            for try await event in stream {
                switch event {
                case .applicationWillSuspend:
                    print("application will suspend")
                    subject.send(.shouldPersistCachedValues(data))
                case let .applicationDidReceiveMemoryPressure(memoryPressureEvent):
                    print("application did receive memory pressure: \(memoryPressureEvent)")
                }
            }
        } catch {
            print("TODO: Error receiving system events: \(error)")
        }
    }
}

// MARK: - Nested Types
extension Cache {
    public struct CachedValue {
        public let value: Value
        public let cost: UInt?
        public let expirationDate: Date

        init(value: Value, duration: TimeInterval, cost: UInt? = nil) {
            self.value = value
            self.cost = cost
            self.expirationDate = DateProvider.now().addingTimeInterval(duration)
        }
    }
}


// MARK: - Public API

public extension Cache {

    var count: Int {
        data.count
    }

    func value(forKey key: Key) -> Value? {
        cachedValue(forKey: key)?.value
    }

    func insert(_ value: Value, duration: TimeInterval, forKey key: Key) {
        insert(.init(value: value, duration: duration), forKey: key)
    }

    func removeValue(forKey key: Key) {
        data[key] = nil
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

    func insert(_ cachedValue: CachedValue, forKey key: Key) {
        data[key] = cachedValue
        updateAccess(for: key)
    }

    func removeCachedValue(forKey key: Key) {
        data[key] = nil
    }

    func updateAccess(for key: Key) {
        removeAccess(for: key)
        access.insert(key, at: 0)
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
            .merge(with: subject.handleEvents(receiveSubscription: { _ in }))
            .eraseToAnyPublisher()
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

import AsyncAlgorithms
import Dependencies
import DequeModule
import Extensions
import Foundation
import OrderedCollections

#if canImport(os.log)
import os.log
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@available(iOS 15.0, *)
public actor Cache<Key: Hashable, Value> {
  public typealias Storage = [Key: CachedValue]

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

  #if canImport(os.log)
  var logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "works.dan.swift-utilities", category: "Cache")
  #endif
  var absoluteUpperLimit: UInt {
    limit + max(10, UInt(Double(limit) * 0.1))
  }
  var data: Storage
  var access: Access
  var _evictions = AsyncStream<EvictionEvent>.makeStream()
  var _events = AsyncStream<Event>.makeStream()

  @Dependency(\.date) private var date

  init<SystemEvents: AsyncSequence>(
    limit: UInt,
    data: Storage,
    didReciveSystemEvents stream: SystemEvents
  )
  where SystemEvents.Element == SystemEvent {
    self.limit = limit
    self.data = data
    self.access = .init(data.keys)
    Task {
      await handleEvictionEvents()
      await startReceivingSystemEvents(from: stream)
    }
  }

  public init(limit: UInt, data: Storage) {
    self.init(
      limit: limit,
      data: data,
      didReciveSystemEvents: SystemEvent.stream()
    )
  }

  public init(limit: UInt, items: [Key: Value], duration: TimeInterval) {
    self.init(
      limit: limit,
      data: items.reduce(into: Storage()) { storage, element in
        storage[element.key] = CachedValue.with(value: element.value, duration: duration)
      },
      didReciveSystemEvents: SystemEvent.stream()
    )
  }

  @available(macOS 12.0, *)
  @available(iOS 15.0, *)
  public init(limit: UInt) {
    self.init(
      limit: limit,
      data: .init(),
      didReciveSystemEvents: SystemEvent.stream()
    )
  }

  func startReceivingSystemEvents<SystemEvents: AsyncSequence>(
    from stream: SystemEvents
  ) async
  where SystemEvents.Element == SystemEvent {
    do {
      for try await event in stream {
        switch event {
        case .applicationWillSuspend:
          _events.continuation.yield(.shouldPersistCachedValues(data))
        case .applicationDidReceiveMemoryPressure(.warning):
          _evictions.continuation.yield(.memoryPressure)
        case .applicationDidReceiveMemoryPressure(.normal):
          break
        }
      }
    } catch {
      #if canImport(os.log)
      logger.error("🗂 ⚠️ Caught error receiving system events: \(error)")
      #endif
    }
  }

  func handleEvictionEvents() async {
    for await eviction in _evictions.stream {
      let countToRemove = calculateEvictionCount(from: eviction)
      let rangeToRemove = countToRemove ..< access.endIndex
      evictCachedValues(forKeys: access[rangeToRemove], reason: eviction)
    }
  }

  func calculateEvictionCount(from event: EvictionEvent) -> Int {
    switch event {
    case .memoryPressure:
      return access.count / 2
    case .countLimit:
      return access.count - Int(limit)
    case .valueExpiry:
      return 1  // Not required to be calculated here, as eviction is key based.
    }
  }
}

// MARK: - Nested Types
@available(iOS 15.0, *)
extension Cache {
  public struct CachedValue {
    public let value: Value
    public let cost: UInt64
    public let expirationDate: Date

    static func with(value: Value, cost: UInt64 = 0, duration: TimeInterval) -> Self {
      @Dependency(\.date) var date
      return Self(
        value: value,
        cost: cost,
        expirationDate: date().addingTimeInterval(duration)
      )
    }
  }
}

@available(iOS 15.0, *)
extension Cache.CachedValue: Codable where Value: Codable {}

// MARK: - Public API

@available(iOS 15.0, *)
extension Cache {

  public var events: some AsyncSequence {
    _events.stream
  }

  public var count: Int {
    data.count
  }

  public func value(forKey key: Key) -> Value? {
    cachedValue(forKey: key)?.value
  }

  public func insert(_ value: Value, forKey key: Key, cost: UInt64 = .zero, duration: TimeInterval) {
    let cachedValue = CachedValue.with(value: value, cost: cost, duration: duration)
    insertCachedValue(cachedValue, forKey: key, duration: duration)
  }

  public func removeValue(forKey key: Key) {
    removeCachedValue(forKey: key)
  }
}

// MARK: - Private API

@available(iOS 15.0, *)
extension Cache {

  fileprivate func cachedValue(forKey key: Key) -> CachedValue? {
    guard let cached = data[key] else { return nil }
    guard date() < cached.expirationDate else {
      removeCachedValue(forKey: key)
      return nil
    }
    updateAccess(for: key)
    return cached
  }

  fileprivate func insertCachedValue(_ cachedValue: CachedValue, forKey key: Key, duration: TimeInterval) {
    data[key] = cachedValue
    updateAccess(for: key)
    guard 0 < duration else { return }
    Task {
      do {
        try await Task.sleep(seconds: duration)
      } catch { /* no-op */  }
      evictCachedValues(forKeys: [key], reason: .valueExpiry)
    }
  }

  fileprivate func removeCachedValue(forKey key: Key) {
    data[key] = nil
    removeAccess(for: key)
  }

  fileprivate func evictCachedValues(forKeys keys: some Collection<Key>, reason event: EvictionEvent) {
    let slice = data.slice(keys)
    #if canImport(os.log)
    logger.info("🗂 Will evict \(keys.map(String.init(describing:))) due to: \(event.description)")
    #endif
    _events.continuation.yield(.willEvictCachedValues(slice, reason: event))
    slice.keys.forEach(removeCachedValue(forKey:))
  }

  fileprivate func updateAccess(for key: Key) {
    removeAccess(for: key)
    access.insert(key, at: 0)
    if access.count >= absoluteUpperLimit {
      _evictions.continuation.yield(.countLimit)
    }
  }

  fileprivate func removeAccess(for key: Key) {
    if let index = access.firstIndex(of: key) {
      access.remove(at: index)
    }
  }
}

// MARK: - Other Implementation Details

@available(iOS 15.0, *)
extension Cache.SystemEvent {

  static func stream(notificationCenter center: NotificationCenter = .default) -> AsyncStream<Self> {
    let memoryPressure = AsyncStream { continuation in
      let queue = DispatchQueue(label: "dan.works.swift-utilities.cache.memory-pressure")
      let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: queue)
      source.setEventHandler {
        var event = source.data
        event.formIntersection([.critical, .warning, .normal])
        if event.contains([.warning, .critical]) {
          continuation.yield(Cache.SystemEvent.applicationDidReceiveMemoryPressure(.warning))
        } else {
          continuation.yield(.applicationDidReceiveMemoryPressure(.normal))
        }
      }
    }

    let willResign =
      center
      .notifications(named: .willResignActiveNotification)
      .map { _ in Cache.SystemEvent.applicationWillSuspend }
      .eraseToStream()

    let willTerminate =
      center
      .notifications(named: .willTerminateNotification)
      .map { _ in Cache.SystemEvent.applicationWillSuspend }
      .eraseToStream()

    let willSuspend = merge(willResign, willTerminate)

    #if os(iOS)
    let additionalMemoryWarning =
      center
      .notifications(named: UIApplication.didReceiveMemoryWarningNotification)
      .map { _ in Cache.SystemEvent.applicationDidReceiveMemoryPressure(.warning) }
      .eraseToStream()

    return merge(memoryPressure, willSuspend, additionalMemoryWarning).eraseToStream()
    #else
    return merge(memoryPressure, willSuspend).eraseToStream()
    #endif
  }
}

@available(iOS 15.0, *)
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
  func slice(_ keys: some Collection<Key>) -> [Key: Value] {
    keys.reduce(into: Self()) { accumulator, key in
      if let value = self[key] {
        accumulator[key] = value
      }
    }
  }
}

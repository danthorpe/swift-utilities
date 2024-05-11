//
//  Copyright © 2021 Daniel Thorpe. All rights reserved.
//

import Foundation

/// Copied from equivalent Protected class from ProcedureKit
/// which has since been adapted for property wrappers by Alamofire

private protocol Lock {
  func lock()
  func unlock()
}

private protocol Lockable {
  func access(_ block: () -> Void)
  func access<T>(_ block: () throws -> T) rethrows -> T
}

extension Lockable where Self: Lock {

  func access(_ block: () -> Void) {
    lock()
    defer { unlock() }
    return block()
  }

  func access<T>(_ block: () -> T) -> T {
    lock()
    defer { unlock() }
    return block()
  }

  func access<T>(_ block: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try block()
  }
}
#if os(iOS) || os(watchOS) || os(tvOS) || os(macOS)
final class UnfairLock: Lock, Lockable {
  private var unfairLock: os_unfair_lock_t

  init() {
    unfairLock = .allocate(capacity: 1)
    unfairLock.initialize(to: os_unfair_lock())
  }

  deinit {
    unfairLock.deinitialize(count: 1)
    unfairLock.deallocate()
  }

  fileprivate func lock() {
    os_unfair_lock_lock(unfairLock)
  }

  fileprivate func unlock() {
    os_unfair_lock_unlock(unfairLock)
  }
}
#else
final class UnfairLock: Lock, Lockable {
  fileprivate let mutex: UnsafeMutablePointer<pthread_mutex_t> = UnsafeMutablePointer.allocate(capacity: 1)
  init() {
    var attr: pthread_mutexattr_t = pthread_mutexattr_t()
    pthread_mutexattr_init(&attr)
    #if DEBUG
    pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
    #endif

    let err = pthread_mutex_init(self.mutex, &attr)
    precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
  }

  deinit {
    let err = pthread_mutex_destroy(self.mutex)
    precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
    mutex.deallocate()
  }

  fileprivate func lock() {
    let err = pthread_mutex_lock(self.mutex)
    precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
  }

  fileprivate func unlock() {
    let err = pthread_mutex_unlock(self.mutex)
    precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
  }
}
#endif

/// A property wrapper which provides thread-safety to
/// any "protected" value. Access is only thread
/// safe when directly accessing or mutating the whole
/// value.
///
/// To mutate part of the value, e.g. properties
/// within a struct, use the $ syntatic-sugar to access
/// the projected value, and then use the read or write
/// methods.
@propertyWrapper
@dynamicMemberLookup
public final class Protected<Value> {
  private let lock: Lockable = UnfairLock()
  private var value: Value

  /// Only thread-safe for direct read or write.
  public var wrappedValue: Value {
    get { lock.access { value } }
    set { lock.access { value = newValue } }
  }

  public var projectedValue: Protected<Value> { self }

  public init(_ value: Value) {
    self.value = value
  }

  public init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  /// Synchronously read or transform the contained value.
  public func read<Output>(_ block: (Value) -> Output) -> Output {
    lock.access { block(value) }
  }

  /// Throwing version for synchronously read or transform the contained value.
  public func read<Output>(_ block: (Value) throws -> Output) rethrows -> Output {
    try lock.access { try block(value) }
  }

  /// Synchronously mutate the contained value
  @discardableResult
  public func write<Output>(_ block: (inout Value) -> Output) -> Output {
    lock.access { block(&value) }
  }

  /// Throwing version for synchronously mutate the contained value
  @discardableResult
  public func write<Output>(_ block: (inout Value) throws -> Output) rethrows -> Output {
    try lock.access { try block(&value) }
  }

  public subscript<Property>(dynamicMember keyPath: WritableKeyPath<Value, Property>) -> Property {
    get { lock.access { value[keyPath: keyPath] } }
    set { lock.access { value[keyPath: keyPath] = newValue } }
  }
}

// MARK: - Conditional Extensions

extension Protected where Value: Collection {

  public func firstIndex(where predicate: (Value.Element) throws -> Bool) rethrows -> Value.Index? {
    try read { try $0.firstIndex(where: predicate) }
  }

  public func index(after idx: Value.Index) -> Value.Index {
    read { $0.index(after: idx) }
  }

  @inlinable public func randomElement() -> Value.Element? {
    read { $0.randomElement() }
  }

  @inlinable public func map<T>(_ transform: (Value.Element) throws -> T) rethrows -> [T] {
    try read { try $0.map(transform) }
  }
}

extension Protected where Value: RangeReplaceableCollection {

  public func append(_ newElement: Value.Element) {
    write { (ward: inout Value) in
      ward.append(newElement)
    }
  }

  public func append<S: Sequence>(contentsOf newElements: S) where S.Element == Value.Element {
    write { (ward: inout Value) in
      ward.append(contentsOf: newElements)
    }
  }

  public func append<C: Collection>(contentsOf newElements: C) where C.Element == Value.Element {
    write { (ward: inout Value) in
      ward.append(contentsOf: newElements)
    }
  }
}

extension Protected where Value == Data? {

  public func append(_ data: Data) {
    write { (ward: inout Value) in
      ward?.append(data)
    }
  }
}

import Dependencies
import Foundation
import OrderedCollections
import XCTest

@testable import Cache

@available(macOS 12.0, *)
@available(iOS 15.0, *)
final class CacheTests: XCTestCase {
  typealias Test = Cache<Int, String>
  var cache: Test!
  var makeValue: ((String) -> Test.CachedValue)!

  override func setUp() {
    super.setUp()
    cache = .init(limit: 10)
    makeValue = { .with(value: $0, duration: 300) }
  }

  override func tearDown() {
    cache = nil
    makeValue = nil
    super.tearDown()
  }

  // MARK: - Initialization

  func test__designated_empty() async {
    cache = .init(limit: 10, data: .init())
    let limit = await cache.limit
    XCTAssertEqual(limit, 10)
    let count = await cache.count
    XCTAssertEqual(count, 0)
  }

  func test__designated_some() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      cache = .init(limit: 10, data: .init(dictionaryLiteral: (0, makeValue("Hello")), (1, makeValue("World"))))
      let limit = await cache.limit
      XCTAssertEqual(limit, 10)
      let count = await cache.count
      XCTAssertEqual(count, 2)
    }
  }

  func test__convenience_empty() async {
    cache = .init(limit: 10)
    let limit = await cache.limit
    XCTAssertEqual(limit, 10)
    let count = await cache.count
    XCTAssertEqual(count, 0)
  }

  func test__convenience_some_dictionary() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      cache = .init(limit: 10, items: [0: "Hello", 1: "World"], duration: 300)
      let limit = await cache.limit
      XCTAssertEqual(limit, 10)
      let count = await cache.count
      XCTAssertEqual(count, 2)
    }
  }

  // MARK: - Insertion

  func test__associative_access_basics() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      await cache.insert("Hello", forKey: 0, duration: 3_600)
      await cache.insert("World", forKey: 1, duration: 3_600)
      var count = await cache.count
      XCTAssertEqual(count, 2)
      var value = await cache.value(forKey: 2)
      XCTAssertNil(value)
      value = await cache.value(forKey: 0)
      XCTAssertEqual(value, "Hello")
      value = await cache.value(forKey: 1)
      XCTAssertEqual(value, "World")
      await cache.removeValue(forKey: 0)
      count = await cache.count
      XCTAssertEqual(count, 1)
      value = await cache.value(forKey: 0)
      XCTAssertNil(value)
    }
  }

  // MARK: - Expiry

  func test__expired_values_are_removed_on_access() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      await cache.insert("Hello", forKey: 0, duration: -3_600)
      await cache.insert("World", forKey: 1, duration: 3_600)
      var count = await cache.count
      XCTAssertEqual(count, 2)
      let value = await cache.value(forKey: 0)
      XCTAssertNil(value)
      count = await cache.count
      XCTAssertEqual(count, 1)
    }
  }
}

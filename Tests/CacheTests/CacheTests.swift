import Dependencies
import Foundation
import OrderedCollections
import Testing

@testable import Cache

@Suite struct CacheTests {
  typealias Test = Cache<Int, String>
  var makeValue: ((String) -> Test.CachedValue) = { .with(value: $0, duration: 300) }

  // MARK: - Initialization

  @Test func test__designated_empty() async {
    let cache = Test(limit: 10, data: .init())
    #expect(await cache.limit == 10)
    #expect(await cache.count == 0)
  }

  @Test func test__designated_some() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      let cache = Test(limit: 10, data: .init(dictionaryLiteral: (0, makeValue("Hello")), (1, makeValue("World"))))
      #expect(await cache.limit == 10)
      #expect(await cache.count == 2)
    }
  }

  @Test func test__convenience_empty() async {
    let cache = Test(limit: 10)
    #expect(await cache.limit == 10)
    #expect(await cache.count == 0)
  }

  @Test func test__convenience_some_dictionary() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      let cache = Test(limit: 10, items: [0: "Hello", 1: "World"], duration: 300)
      #expect(await cache.limit == 10)
      #expect(await cache.count == 2)
    }
  }

  // MARK: - Insertion

  @Test func test__associative_access_basics() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      let cache = Test(limit: 10)
      await cache.insert("Hello", forKey: 0, duration: 3_600)
      await cache.insert("World", forKey: 1, duration: 3_600)
      #expect(await cache.count == 2)
      #expect(await cache.value(forKey: 2) == nil)
      #expect(await cache.value(forKey: 0) == "Hello")
      #expect(await cache.value(forKey: 1) == "World")
      await cache.removeValue(forKey: 0)
      #expect(await cache.count == 1)
      #expect(await cache.value(forKey: 0) == nil)
    }
  }

  // MARK: - Expiry

  @Test func test__expired_values_are_removed_on_access() async {
    await withDependencies {
      $0.date = .constant(Date(timeIntervalSinceNow: 0))
    } operation: {
      let cache = Test(limit: 10)
      await cache.insert("Hello", forKey: 0, duration: -3_600)
      await cache.insert("World", forKey: 1, duration: 3_600)
      #expect(await cache.count == 2)
      #expect(await cache.value(forKey: 0) == nil)
      #expect(await cache.count == 1)
    }
  }
}

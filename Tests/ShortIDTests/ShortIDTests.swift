import XCTest

@testable import ShortID

final class ShortIDTests: XCTestCase {

  func test__shortIDs() {
    measure {
      let count = 10_000
      let shortIDs: Set<ShortID> = (0 ..< count)
        .map { _ in ShortID() }
        .reduce(into: [], { $0.insert($1) })
      XCTAssertEqual(shortIDs.count, count)
    }
  }

  func test__incrementing_shortIDs() {
    let generator = ShortIDGenerator.incrementing
    let shortIDs: [String] = (0 ..< 100)
      .map { _ in generator().description }
    XCTAssertEqual(shortIDs[0], "000001")
    XCTAssertEqual(shortIDs[1], "000002")
    XCTAssertEqual(shortIDs[2], "000003")
    XCTAssertEqual(shortIDs[3], "000004")
    XCTAssertEqual(shortIDs[4], "000005")
    XCTAssertEqual(shortIDs[5], "000006")
  }
}

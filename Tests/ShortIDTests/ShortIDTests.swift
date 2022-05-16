@testable import ShortID
import XCTest

final class ShortIDTests: XCTestCase {

    func test__shortIDs() {
        measure {
            let count = 10_000
            let shortIDs: Set<ShortID> = (0..<count)
                .map { _ in ShortID() }
                .reduce(into: [], { $0.insert($1) })
            XCTAssertEqual(shortIDs.count, count)
        }
    }
}

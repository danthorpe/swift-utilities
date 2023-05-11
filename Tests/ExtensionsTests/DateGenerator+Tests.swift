import Dependencies
import Extensions
import Foundation
import XCTest

final class DateGeneratorTests: XCTestCase {

    func test__dayTimes() throws {
        let now = Date(timeIntervalSinceReferenceDate: 14_400)
        try withDependencies {
            $0.calendar = Calendar(identifier: .gregorian)
            $0.date = .constant(now)
        } operation: {
            @Dependency(\.date) var date
            let dayTimes = try XCTUnwrap(date.dayTimes)
            XCTAssertEqual(dayTimes.yesterday.start.timeIntervalSince1970, 978220800)
            XCTAssertEqual(dayTimes.yesterday.now.timeIntervalSince1970, 978235200)
            XCTAssertEqual(dayTimes.yesterday.end.timeIntervalSince1970, 978307199.999)
            XCTAssertEqual(dayTimes.today.start.timeIntervalSince1970, 978307200)
            XCTAssertEqual(dayTimes.today.now.timeIntervalSince1970, 978321600)
            XCTAssertEqual(dayTimes.today.end.timeIntervalSince1970, 978393599.999)
            XCTAssertEqual(dayTimes.tomorrow.start.timeIntervalSince1970, 978393600)
            XCTAssertEqual(dayTimes.tomorrow.now.timeIntervalSince1970, 978408000)
            XCTAssertEqual(dayTimes.tomorrow.end.timeIntervalSince1970, 978479999.999)
        }
    }
}

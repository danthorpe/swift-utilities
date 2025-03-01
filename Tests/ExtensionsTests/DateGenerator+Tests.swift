import Dependencies
import Extensions
import Foundation
import Testing

@Test func test__dayTimes() throws {
  let now = Date(timeIntervalSinceReferenceDate: 14_400)
  try withDependencies {
    $0.calendar = Calendar(identifier: .gregorian)
    $0.date = .constant(now)
  } operation: {
    @Dependency(\.date) var date
    let dayTimes = try #require(date.dayTimes)
    #expect(dayTimes.yesterday.start.timeIntervalSince1970 == 978_220_800)
    #expect(dayTimes.yesterday.now.timeIntervalSince1970 == 978_235_200)
    #expect(dayTimes.yesterday.end.timeIntervalSince1970 == 978307199.999)
    #expect(dayTimes.today.start.timeIntervalSince1970 == 978_307_200)
    #expect(dayTimes.today.now.timeIntervalSince1970 == 978_321_600)
    #expect(dayTimes.today.end.timeIntervalSince1970 == 978393599.999)
    #expect(dayTimes.tomorrow.start.timeIntervalSince1970 == 978_393_600)
    #expect(dayTimes.tomorrow.now.timeIntervalSince1970 == 978_408_000)
    #expect(dayTimes.tomorrow.end.timeIntervalSince1970 == 978479999.999)
  }
}

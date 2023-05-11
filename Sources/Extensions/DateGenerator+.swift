import Dependencies
import Foundation

public extension DateGenerator {
    struct Times: Equatable {
        public let start: Date
        public let end: Date
        public let now: Date
    }
    struct DayTimes: Equatable {
        public let yesterday: Times
        public let today: Times
        public let tomorrow: Times
    }

    var dayTimes: DayTimes? {
        @Dependency(\.calendar) var calendar
        let _now = now
        guard
            let yesterday = calendar.date(byAdding: .day, value: -1, to: _now),
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: _now),
            let yesterdayEnd = calendar.endOfDay(for: yesterday),
            let end = calendar.endOfDay(for: _now),
            let tomorrowEnd = calendar.endOfDay(for: tomorrow)
        else { return nil }
        return DayTimes(
            yesterday: .init(
                start: calendar.startOfDay(for: yesterday),
                end: yesterdayEnd,
                now: yesterday
            ),
            today: .init(
                start: calendar.startOfDay(for: _now),
                end: end,
                now: _now
            ),
            tomorrow: .init(
                start: calendar.startOfDay(for: tomorrow),
                end: tomorrowEnd,
                now: tomorrow
            )
        )
    }
}

import Foundation

public extension Calendar {

    /// Approximately the end of the day.
    ///
    /// - Note: To determine the end of the day, it is most accurate
    /// to subtract the smallest unit of time from the start of the
    /// next day. `Date` is accurate to sub-millisecond accuracy,
    /// therefore, it is safest to subtract 1ms.
    func endOfDay(for query: Date) -> Date? {
        guard let nextDay = date(byAdding: .day, value: 1, to: query) else { return nil }
        let startOfNextDay = startOfDay(for: nextDay)
        return self.date(byAdding: .nanosecond, value: -Int(NSEC_PER_MSEC), to: startOfNextDay)
    }
}

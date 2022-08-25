import Foundation
extension Task where Success == Never, Failure == Never {
    public static func sleep(seconds timeInterval: TimeInterval) async throws {
        guard !timeInterval.isNaN && timeInterval.isFinite else { return }
        try await sleep(nanoseconds: UInt64(timeInterval * Double(NSEC_PER_SEC)))
    }
}

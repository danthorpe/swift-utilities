import Foundation

#if os(Linux)
import let CDispatch.NSEC_PER_SEC
#else
import Dispatch
#endif

extension Task where Success == Never, Failure == Never {
  public static func sleep(seconds timeInterval: TimeInterval) async throws {
    guard !timeInterval.isNaN && timeInterval.isFinite else { return }
    try await sleep(nanoseconds: UInt64(timeInterval * Double(NSEC_PER_SEC)))
  }
}

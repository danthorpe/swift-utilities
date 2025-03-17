import CustomDump
import IssueReportingTestSupport

@available(*, deprecated, message: "Use Swift Testing #expect macro instead.")
public func XCTAssertThrowsError<T: Sendable>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "Expression did not throw an error.",
  file: StaticString = #filePath,
  line: UInt = #line,
  _ errorHandler: (_ error: Error) -> Void = { _ in /* no-op */ }
) async {
  do {
    _ = try await expression()
    _ = _XCTFail()
  } catch {
    errorHandler(error)
  }
}

@available(*, deprecated, message: "Use Swift Testing #expect macro instead.")
public func XCTAssertThrowsError<T: Sendable, E: Error & Equatable>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "Expression did not throw an error.",
  file: StaticString = #filePath,
  line: UInt = #line,
  matches expectation: E
) async {
  do {
    _ = try await expression()
    _ = _XCTFail()
  } catch {
    guard let error = error as? E else {
      _ = _XCTFail()
      return
    }
    XCTAssertNoDifference(error, expectation)
  }
}

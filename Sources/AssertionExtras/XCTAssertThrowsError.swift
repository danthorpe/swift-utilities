import CustomDump
import XCTestDynamicOverlay

public func XCTAssertThrowsError<T: Sendable>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "Expression did not throw an error.",
  file: StaticString = #filePath,
  line: UInt = #line,
  _ errorHandler: (_ error: Error) -> Void = { _ in /* no-op */ }
) async {
  do {
    _ = try await expression()
    XCTFail(message(), file: file, line: line)
  } catch {
    errorHandler(error)
  }
}

public func XCTAssertThrowsError<T: Sendable, E: Error & Equatable>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "Expression did not throw an error.",
  file: StaticString = #filePath,
  line: UInt = #line,
  matches expectation: E
) async {
  do {
    _ = try await expression()
    XCTFail(message(), file: file, line: line)
  } catch {
    guard let error = error as? E else {
      XCTFail("Unexpected error type received: \(error)", file: file, line: line)
      return
    }
    XCTAssertNoDifference(error, expectation)
  }
}

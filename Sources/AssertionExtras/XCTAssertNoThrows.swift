import CustomDump
import IssueReporting
import XCTest

public func XCTAssertNoThrows<T: Sendable>(
  _ expression: @autoclosure () async throws -> T,
  _ message: @autoclosure () -> String = "Expression did throw an error.",
  file: StaticString = #filePath,
  line: UInt = #line
) async -> T {
  do {
    return try await expression()
  } catch {
    XCTFail(message(), file: file, line: line)
    fatalError("Cannot return value.")
  }
}

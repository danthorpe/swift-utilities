import Dependencies
import DependenciesMacros
import Foundation
import IssueReporting

@DependencyClient
public struct FileManagerClient: Sendable {
  public var url:
    @Sendable (
      FileManager.SearchPathDirectory,
      FileManager.SearchPathDomainMask,
      URL?,
      Bool
    ) throws -> URL
  public var urls:
    @Sendable (
      FileManager.SearchPathDirectory,
      FileManager.SearchPathDomainMask
    ) -> [URL] = { _, _ in [] }
  public var createDirectoryAtURL: @Sendable (URL, Bool, [FileAttributeKey: Any]?) throws -> Void
  public var removeItemAtURL: @Sendable (URL) throws -> Void
  public var fileExistsAtPath: @Sendable (String) -> Bool = { _ in false }

}

// MARK: - Live

extension FileManagerClient: DependencyKey {
  public static let liveValue = FileManagerClient(
    url: { try FileManager.default.url(for: $0, in: $1, appropriateFor: $2, create: $3) },
    urls: { FileManager.default.urls(for: $0, in: $1) },
    createDirectoryAtURL: {
      try FileManager.default.createDirectory(
        at: $0,
        withIntermediateDirectories: $1,
        attributes: $2
      )
    },
    removeItemAtURL: { try FileManager.default.removeItem(at: $0) },
    fileExistsAtPath: { FileManager.default.fileExists(atPath: $0) }
  )

  public static let testValue = FileManagerClient()
}

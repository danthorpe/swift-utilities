import Dependencies
import DependenciesMacros
import Foundation
import IssueReporting

@DependencyClient
public struct FileManagerClient {
  public typealias LocateURLForDirectoryMask = (
    FileManager.SearchPathDirectory,
    FileManager.SearchPathDomainMask,
    URL?,
    Bool
  ) throws -> URL

  public typealias LocateURLsForDirectoryMask = (
    FileManager.SearchPathDirectory,
    FileManager.SearchPathDomainMask
  ) -> [URL]

  public typealias CreateDirectoryAtURL = (URL, Bool, [FileAttributeKey: Any]?) throws -> Void
  public typealias RemoveItemAtURL = (URL) throws -> Void
  public typealias FileExistsAtPath = (String) -> Bool

  public var url: LocateURLForDirectoryMask
  public var urls: LocateURLsForDirectoryMask
  public var createDirectoryAtURL: CreateDirectoryAtURL
  public var removeItemAtURL: RemoveItemAtURL
  public var fileExistsAtPath: FileExistsAtPath

}

// MARK: - Live

extension FileManagerClient: DependencyKey {
  public static let liveValue: FileManagerClient = {
    let fileManager = FileManager.default
    return FileManagerClient(
      url: { try fileManager.url(for: $0, in: $1, appropriateFor: $2, create: $3) },
      urls: { fileManager.urls(for: $0, in: $1) },
      createDirectoryAtURL: {
        try fileManager.createDirectory(
          at: $0,
          withIntermediateDirectories: $1,
          attributes: $2
        )
      },
      removeItemAtURL: { try fileManager.removeItem(at: $0) },
      fileExistsAtPath: { fileManager.fileExists(atPath: $0) }
    )
  }()

  public static let testValue: FileManagerClient = FileManagerClient(
    url: unimplemented("\(Self.self).url"),
    urls: unimplemented("\(Self.self).urls", placeholder: []),
    createDirectoryAtURL: unimplemented("\(Self.self).createDirectoryAtURL"),
    removeItemAtURL: unimplemented("\(Self.self).removeItemAtURL"),
    fileExistsAtPath: unimplemented("\(Self.self).fileExistsAtPath", placeholder: false)
  )
}

import Foundation

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

    public init(
        url: @escaping LocateURLForDirectoryMask,
        urls: @escaping LocateURLsForDirectoryMask,
        createDirectoryAtURL: @escaping CreateDirectoryAtURL,
        removeItemAtURL: @escaping RemoveItemAtURL,
        fileExistsAtPath: @escaping FileExistsAtPath
    ) {
        self.url = url
        self.urls = urls
        self.createDirectoryAtURL = createDirectoryAtURL
        self.removeItemAtURL = removeItemAtURL
        self.fileExistsAtPath = fileExistsAtPath
    }

    public func url(
        for directory: FileManager.SearchPathDirectory,
        in mask: FileManager.SearchPathDomainMask,
        appropriateFor: URL?,
        create: Bool
    ) throws -> URL {
        try url(directory, mask, appropriateFor, create)
    }

    public func urls(
        for directory: FileManager.SearchPathDirectory,
        in mask: FileManager.SearchPathDomainMask
    ) -> [URL] {
        urls(directory, mask)
    }

    public func createDirectory(
        at url: URL,
        withIntermediateDirectories: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        try createDirectoryAtURL(url, withIntermediateDirectories, attributes)
    }

    public func removeItem(at url: URL) throws {
        try removeItemAtURL(url)
    }

    public func fileExists(atPath path: String) -> Bool {
        fileExistsAtPath(path)
    }
}

// MARK: - Live

extension FileManagerClient {
    public static let live: Self = {
        let fileManager = FileManager.default
        return Self(
            url: { try fileManager.url(for: $0, in: $1, appropriateFor: $2, create: $3) },
            urls: { fileManager.urls(for: $0, in: $1) },
            createDirectoryAtURL: { try fileManager.createDirectory(at: $0, withIntermediateDirectories: $1, attributes: $2) },
            removeItemAtURL: { try fileManager.removeItem(at: $0) },
            fileExistsAtPath: { fileManager.fileExists(atPath: $0) }
        )
    }()
}

// MARK: - Unimplemented

import XCTestDynamicOverlay
extension FileManagerClient {
    public static let unimplemented = Self(
        url: XCTUnimplemented("\(Self.self).url"),
        urls: XCTUnimplemented("\(Self.self).urls"),
        createDirectoryAtURL: XCTUnimplemented("\(Self.self).createDirectoryAtURL"),
        removeItemAtURL: XCTUnimplemented("\(Self.self).removeItemAtURL"),
        fileExistsAtPath: XCTUnimplemented("\(Self.self).fileExistsAtPath")
    )
}


import Dependencies
import Foundation
import Protected

extension DependencyValues {

  /// Access a generator to create new ``ShortID`` values
  ///
  /// Like `UUID`, ``ShortID`` is an "uncontrolled dependency", we cannot
  ///  know what it's value will be because it is random. Therefore, to
  ///  have controlled tests, we need to be able to control the generation
  ///  of the ``ShortID`` values.
  ///
  /// To this end, do not create use `ShortID()` directly, in the same way
  ///  that we should not use `UUID()` or `Date()` directly. Instead use
  ///  dependency injection, or management, in particular swift-dependencies.
  ///
  /// See: https://github.com/pointfreeco/swift-dependencies
  ///
  /// Example:
  /// ```swift
  /// struct Message: Equatable, Hashable, Identifiable {
  ///   let id: String
  ///   let message: String
  ///
  ///   init(message: String) {
  ///     @Dependency(\.shortID) var shortID
  ///     self.init(
  ///       id: shortID().description,
  ///       message: message
  ///     )
  ///   }
  /// }
  /// ```
  /// In this example, we provide an overload of the `Message.init` where the identifier is
  /// determined using a ShortID. When this code is run in an application, each message
  /// will get a locally-unique random identifier. However, in tests, each identifier will be
  /// a locally-unique yet deterministic incrementing identifier.
  public var shortID: ShortIDGenerator {
    get { self[ShortIDGeneratorKey.self] }
    set { self[ShortIDGeneratorKey.self] = newValue }
  }

  private enum ShortIDGeneratorKey: DependencyKey {
    static let liveValue = ShortIDGenerator.live(.base62)
    static let testValue = ShortIDGenerator.incrementing
    static let previewValue = ShortIDGenerator.constant(ShortID())
  }
}

/// A dependency which generates a `ShortID`
public struct ShortIDGenerator: Sendable {
  private let generate: @Sendable () -> ShortID

  /// Creates a new ShortID every time it is executed
  /// - Parameter strategy: the ``ShortID/Strategy`` to use, defaults to .base62
  /// - Returns: ``ShortIDGenerator``
  public static func live(_ strategy: ShortID.Strategy) -> Self {
    Self { ShortID(strategy) }
  }

  /// Creates the same constant ShortID every time.
  ///
  /// This is the standard "preview" dependency, which is a
  /// normal ShortID, but will always be the same one.
  /// - Returns: ``ShortIDGenerator``
  public static func constant(_ shortID: ShortID) -> Self {
    Self { shortID }
  }

  /// Creates an incrementing ShortID every time it is executed.
  ///
  /// This is the standard "test" dependency, and it will create a
  /// new short id, as 000001, 000002, 000003 etc
  /// - Returns: ``ShortIDGenerator``
  public static var incrementing: Self {
    let generator = IncrementingGenerator()
    return Self { generator() }
  }

  init(_ generate: @escaping @Sendable () -> ShortID) {
    self.generate = generate
  }

  /// Treat ``ShortIDGenerator`` like a function.
  ///
  /// Calling it will generate a ``ShortID`` value.
  /// - Returns: ``ShortID``
  public func callAsFunction() -> ShortID {
    generate()
  }
}

private struct IncrementingGenerator: @unchecked Sendable {

  @Protected
  var sequence: Int = 0

  func callAsFunction() -> ShortID {
    ShortID(
      value: String(
        format: "%06x",
        $sequence.write {
          $0 += 1
          return $0
        }))
  }
}

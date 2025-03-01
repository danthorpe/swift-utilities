import Foundation
import Protected

/// A `ShortID` value is like a `UUID` except that it has fewer characters,
///  and is locally-unique instead of globally unique. This is useful when
///  you wish to have more-or-less unique values which are much less verbose.
public struct ShortID: Sendable {
  public enum Strategy: Sendable {

    /// Generates 6-character long ShortIDs using Base62
    ///  character set (i.e. base 64 but with + and / removed),
    ///  which is the upper and lower-case Roman alphabet
    ///  characters (A-Z, a-z) and the numerals 0-9.
    case base62

    /// Generates 7-character long ShortIDs using Base36
    ///  character set, which is the lower-case Roman alphabet
    ///  and the numerals 0-9.
    case base36
  }

  private let value: String

  init(value: String) {
    self.value = value
  }

  /// Create a new ShortID based on a specific strategy
  /// - Parameter strategy: the ``Strategy`` to use, defaults to .base62
  public init(_ strategy: Strategy = .base62) {
    self.init(value: strategy.generate())
  }
}

// MARK: - Conformances

extension ShortID: Equatable, Hashable {}

extension ShortID: CustomStringConvertible {
  public var description: String { value }
}

extension ShortID: CustomDebugStringConvertible {
  public var debugDescription: String { value.debugDescription }
}

// MARK: Random Character Generator

protocol RandomCharacterGenerator {
  var characters: String { get }
  var count: Int { get }
  var defaultLength: Int { get }
  func isUnique(_ word: String) -> Bool
}

extension RandomCharacterGenerator {

  func isUnique(_ word: String) -> Bool { true }

  func generate() -> String {
    var word: String
    repeat {
      word = randomWord()
    } while !isUnique(word)
    return word
  }

  func randomWord() -> String {
    (0 ..< defaultLength)
      .reduce(into: "") { (accumulator, _) in
        accumulator.append(randomCharacter())
      }
  }

  func randomCharacter() -> Character {
    let offset = Int.random(in: 0 ..< count)
    let index = characters.index(characters.startIndex, offsetBy: offset)
    return characters[index]
  }
}

extension ShortID.Strategy {

  private struct Base62Generator: Sendable, RandomCharacterGenerator {
    let characters: String
    let count: Int
    let defaultLength: Int

    static let shared = Base62Generator(
      characters: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
      count: 62,
      defaultLength: 6
    )

    @Protected
    private var generated: Set<String> = []

    func isUnique(_ word: String) -> Bool {
      guard false == generated.contains(word) else { return false }
      $generated.write { $0.insert(word) }
      return true
    }
  }

  private struct Base36Generator: Sendable, RandomCharacterGenerator {
    let characters: String
    let count: Int
    let defaultLength: Int

    static let shared = Base62Generator(
      characters: "0123456789abcdefghijklmnopqrstuvwxyz",
      count: 36,
      defaultLength: 7
    )

    @Protected
    private var generated: Set<String> = []

    func isUnique(_ word: String) -> Bool {
      guard false == generated.contains(word) else { return false }
      $generated.write { $0.insert(word) }
      return true
    }
  }

  func generate() -> String {
    switch self {
    case .base62:
      return Base62Generator.shared.generate()
    case .base36:
      return Base36Generator.shared.generate()
    }
  }
}

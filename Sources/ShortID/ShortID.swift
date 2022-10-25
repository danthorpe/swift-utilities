import Dependencies
import Foundation
import Protected
import XCTestDynamicOverlay

/// A `ShortID` value is like a `UUID` except that it has fewer characters,
/// and is not globally unique. This is useful when you wish to have locally
/// unique values which are less verbose.
public struct ShortID: Sendable {
    public enum Strategy {
        case base62, base36
    }

    private let value: String

    init(value: String) {
        self.value = value
    }

    public init(_ strategy: Strategy = .base62) {
        self.init(value: strategy.generate())
    }
}

// MARK: - Conformances

extension ShortID: Equatable, Hashable { }

extension ShortID: CustomStringConvertible {
    public var description: String { value }
}

extension ShortID: CustomDebugStringConvertible {
    public var debugDescription: String { value.debugDescription }
}

extension DependencyValues {

    public var shortID: ShortIDGenerator {
        get { self[ShortIDGeneratorKey.self] }
        set { self[ShortIDGeneratorKey.self] = newValue }
    }

    private enum ShortIDGeneratorKey: DependencyKey {
        static let liveValue = ShortIDGenerator { ShortID() }
        static let testValue = ShortIDGenerator {
            XCTFail(#"Unimplemented: @Dependency(\.shortId)"#)
            return ShortID()
        }
        static let previewValue = ShortIDGenerator.constant(ShortID())
    }
}

/// A dependency which generates a `ShortID`
public struct ShortIDGenerator {
    private let generate: @Sendable () -> ShortID

    public static func constant(_ shortID: ShortID) -> Self {
        Self { shortID }
    }

    public static var incrementing: Self {
        let generator = IncrementingGenerator()
        return Self { generator() }
    }

    public init(_ generate: @escaping @Sendable () -> ShortID) {
        self.generate = generate
    }

    public func callAsFunction() -> ShortID {
        generate()
    }
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
        (0..<defaultLength).reduce(into: "") { (accumulator, _) in
            accumulator.append(randomCharacter())
        }
    }

    func randomCharacter() -> Character {
        let offset = Int.random(in: 0..<count)
        let index = characters.index(characters.startIndex, offsetBy: offset)
        return characters[index]
    }
}

extension ShortID.Strategy {

    private struct Base62Generator: RandomCharacterGenerator {
        let characters: String
        let count: Int

        static let shared = Base62Generator(
            characters: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
            count: 62
        )

        var defaultLength: Int { 6 }

        @Protected
        private var generated: Set<String> = []

        func isUnique(_ word: String) -> Bool {
            guard false == generated.contains(word) else { return false }
            $generated.write { $0.insert(word) }
            return true
        }
    }

    private struct Base36Generator: RandomCharacterGenerator {
        let characters: String
        let count: Int

        static let shared = Base62Generator(
            characters: "0123456789abcdefghijklmnopqrstuvwxyz",
            count: 36
        )

        var defaultLength: Int { 7 }

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

private struct IncrementingGenerator: @unchecked Sendable {

    @Protected
    var sequence: Int = 0

    func callAsFunction() -> ShortID {
        ShortID(value: String(format: "%06x", $sequence.write { $0+=1; return $0 }))
    }
}

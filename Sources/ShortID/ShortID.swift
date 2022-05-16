import Foundation
import Concurrency

protocol RandomCharacterGenerator {
    var characters: String { get }
    var count: Int { get }

    func isUnique(_ word: String) -> Bool
}

extension RandomCharacterGenerator {

    func isUnique(_ word: String) -> Bool { true }

    func generate(_ length: Int) -> String {
        var word: String
        repeat {
            word = randomWord(length)
        } while !isUnique(word)
        return word
    }

    func randomWord(_ length: Int) -> String {
        (0..<length).reduce(into: "") { (accumulator, _) in
            accumulator.append(randomCharacter())
        }
    }

    func randomCharacter() -> Character {
        let offset = Int.random(in: 0..<count)
        let index = characters.index(characters.startIndex, offsetBy: offset)
        return characters[index]
    }
}

public struct ShortID {

    public enum Strategy {
        case base62, base36
    }

    private let value: String

    public init(_ strategy: Strategy = .base62, length: Int = Strategy.base62.defaultLength) {
        value = strategy.generate(length)
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

        @Protected
        private var generated: Set<String> = []

        func isUnique(_ word: String) -> Bool {
            guard false == generated.contains(word) else { return false }
            $generated.write { $0.insert(word) }
            return true
        }
    }

    public var defaultLength: Int {
        switch self {
        case .base62:
            return 6
        case .base36:
            return 7
        }
    }

    func generate(_ length: Int) -> String {
        switch self {
        case .base62:
            return Base62Generator.shared.generate(length)
        case .base36:
            return Base36Generator.shared.generate(length)
        }
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

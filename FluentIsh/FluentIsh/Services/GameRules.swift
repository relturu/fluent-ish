//
//  GameRules.swift
//  FluentIsh
//
//  Pure rules for the three daily games, shared by the Today previews and the
//  game screens (steps 10–12). Unit tested in FluentIshTests/GameRulesTests.
//

import Foundation

nonisolated enum GameRules {

    // MARK: Word Guess

    enum LetterResult: Equatable {
        case correct   // right letter, right spot (green)
        case present   // in the word, wrong spot (yellow)
        case absent    // not in the word (grey)
    }

    /// Uppercases and drops accents on vowels (á→A, ü→U) so players don't
    /// need to type them. Ñ stays Ñ: in Spanish it's a different letter.
    static func normalize(_ word: String) -> String {
        let map: [Character: Character] = ["Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U"]
        return String(word.uppercased().map { map[$0] ?? $0 })
    }

    /// Colours for one guess, counting repeated letters properly: if the
    /// answer has one A and the guess has two, only one A is marked. Greens
    /// are claimed first, then yellows left to right.
    static func feedback(guess: String, answer: String) -> [LetterResult] {
        let g = Array(normalize(guess)), a = Array(normalize(answer))
        var result = [LetterResult](repeating: .absent, count: g.count)
        var unmatched: [Character: Int] = [:]
        for i in a.indices where i >= g.count || g[i] != a[i] { unmatched[a[i], default: 0] += 1 }
        for i in g.indices where i < a.count && g[i] == a[i] { result[i] = .correct }
        for i in g.indices where result[i] != .correct {
            if let left = unmatched[g[i]], left > 0 {
                result[i] = .present
                unmatched[g[i]] = left - 1
            }
        }
        return result
    }

    static func isSolved(guess: String, answer: String) -> Bool {
        normalize(guess) == normalize(answer)
    }

    // MARK: Crossword

    /// True for black squares, from the one-string-per-row grid ("A#B#R").
    static func blackSquares(_ solution: [String]) -> [[Bool]] {
        solution.map { $0.map { $0 == "#" } }
    }
}

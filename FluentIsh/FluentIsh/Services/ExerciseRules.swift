//
//  ExerciseRules.swift
//  FluentIsh
//
//  Pure rules for the Skill Exercises (Fill in the Blank, Sentence Builder,
//  Definition Match). No UI and no Firebase, so they're unit tested in
//  FluentIshTests/ExerciseRulesTests.swift.
//
//  plan.md defaults: hints are free in V1, a wrong answer can be retried,
//  and accuracy counts first tries only.
//

import Foundation

nonisolated enum ExerciseRules {
    static let blank = "___"

    // MARK: Fill in the Blank

    /// "Yo ___ café." → ("Yo ", " café."). nil if the prompt has no blank.
    static func blankParts(_ prompt: String) -> (before: String, after: String)? {
        guard let range = prompt.range(of: blank) else { return nil }
        return (String(prompt[..<range.lowerBound]), String(prompt[range.upperBound...]))
    }

    /// The sentence with the blank filled in, for the speaker button.
    static func filledSentence(_ item: ExerciseItem) -> String {
        guard let parts = blankParts(item.prompt) else { return item.prompt }
        return parts.before + item.answer + parts.after
    }

    // MARK: Sentence Builder

    /// The tiles to choose from: `choices` (which may include decoys), or the
    /// answer split into words if the seed gave none.
    static func tiles(for item: ExerciseItem) -> [String] {
        if let choices = item.choices, !choices.isEmpty { return choices }
        return words(item.answer)
    }

    static func words(_ sentence: String) -> [String] {
        sentence.split(separator: " ").map(String.init)
    }

    /// The picked tiles, joined with spaces, are exactly the answer.
    static func isCorrectSentence(picked: [String], answer: String) -> Bool {
        picked == words(answer)
    }

    /// The hint: keeps the correct start of what's been picked, drops the
    /// rest, and adds the next correct tile. Works on tile indices because a
    /// word can appear on two tiles ("la", "la").
    static func hintPlacement(picked: [Int], tiles: [String], answer: String) -> [Int] {
        let target = words(answer)
        var kept: [Int] = []
        for index in picked {
            guard kept.count < target.count, tiles[index] == target[kept.count] else { break }
            kept.append(index)
        }
        guard kept.count < target.count else { return kept }
        let next = target[kept.count]
        if let free = tiles.indices.first(where: { tiles[$0] == next && !kept.contains($0) }) {
            kept.append(free)
        }
        return kept
    }

    // MARK: Scoring

    /// Share of items right on the first try, as a whole percent.
    static func accuracyPercent(firstTry: Int, total: Int) -> Int {
        guard total > 0 else { return 100 }
        return Int((Double(min(firstTry, total)) / Double(total) * 100).rounded())
    }

    /// Time on the screen, rounded up to whole minutes (at least 1), as
    /// plan.md's "Minutes" rule says.
    static func minutes(from start: Date, to end: Date) -> Int {
        max(1, Int((end.timeIntervalSince(start) / 60).rounded(.up)))
    }
}

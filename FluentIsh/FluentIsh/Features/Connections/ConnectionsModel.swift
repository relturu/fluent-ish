//
//  ConnectionsModel.swift
//  FluentIsh
//
//  Created by Jessica Zheng on 11/8/26.
//

import Foundation
import Observation

@Observable
final class ConnectionsModel {

    // MARK: - Submission Results

    enum SubmissionResult {
        case correct
        case incorrect
        case oneAway
        case won
        case gameOver
        case notEnoughSelected
    }

    // MARK: - Game Data

    let puzzle: ConnectionsPuzzle

    private(set) var words: [String] = []
    private(set) var selectedWords: Set<String> = []
    private(set) var solvedGroupIndices: Set<Int> = []
    private(set) var mistakes = 0

    private(set) var lastGuessWasOneAway = false

    let maxMistakes = 4

    let startedAt = Date()

    // MARK: - Initialization

    /// `saved` restores a game started (or finished) earlier today. It
    /// defaults to nil, so `ConnectionsModel(puzzle:)` still starts fresh.
    init(puzzle: ConnectionsPuzzle, restoring saved: GameResult? = nil) {
        self.puzzle = puzzle

        // Combine the four groups into one list of 16 words.
        words = puzzle.groups.flatMap { $0.words }

        // Randomize the initial order.
        words.shuffle()

        // Copy back the two things the game saves. Everything else
        // (isWon, isGameOver, revealedGroups…) is computed from these,
        // so a restored game ends up in the same state it was saved in.
        // Indices outside the puzzle are dropped so bad data can't crash.
        if let saved {
            mistakes = saved.mistakes ?? 0
            solvedGroupIndices = Set(
                (saved.solvedGroups ?? []).filter { puzzle.groups.indices.contains($0) }
            )
        }
    }

    // MARK: - Game State

    var remainingWords: [String] {
        let solvedWords = Set(
            solvedGroupIndices.flatMap { puzzle.groups[$0].words }
        )

        return words.filter { !solvedWords.contains($0) }
    }

    var remainingMistakes: Int {
        max(0, maxMistakes - mistakes)
    }

    var isWon: Bool {
        solvedGroupIndices.count == puzzle.groups.count
    }

    var isGameOver: Bool {
        mistakes >= maxMistakes && !isWon
    }

    var isFinished: Bool {
        isWon || isGameOver
    }

    /// The groups the player didn't find, shown as the answer after a loss.
    /// Empty while playing and after a win. Kept apart from
    /// `solvedGroupIndices` on purpose: that set is what gets saved and
    /// scored, so a revealed group must never count as a found one.
    /// Computed (not stored), so a restored lost game reveals the same
    /// groups with nothing extra to save.
    var revealedGroups: [ConnectionsGroup] {
        guard isGameOver else { return [] }

        // Walk the puzzle in its original order and keep the unsolved groups.
        return puzzle.groups.indices
            .filter { !solvedGroupIndices.contains($0) }
            .map { puzzle.groups[$0] }
    }

    var minutesElapsed: Int {
        max(1, Int(Date().timeIntervalSince(startedAt) / 60))
    }

    // MARK: - Tile Selection

    func toggleSelection(_ word: String) {
        guard !isFinished else { return }
        guard remainingWords.contains(word) else { return }

        lastGuessWasOneAway = false

        if selectedWords.contains(word) {
            selectedWords.remove(word)
        } else if selectedWords.count < 4 {
            selectedWords.insert(word)
        }
    }

    func deselectAll() {
        selectedWords.removeAll()
        lastGuessWasOneAway = false
    }

    // MARK: - Shuffle

    func shuffleWords() {
        guard !isFinished else { return }

        words.shuffle()
        Haptics.tap()
    }
    
    // MARK: - Hint State
    private(set) var hintedGroups: Set<Int> = []

    var hintsUsed: Int { hintedGroups.count }
    
    // MARK: - Hints

    /// The group a hint points at: one already hinted and still unsolved,
    /// otherwise the first unsolved group.
    var nextHintGroupIndex: Int? {
        guard !isFinished else { return nil }
        let unsolved = puzzle.groups.indices.filter { !solvedGroupIndices.contains($0) }
        return unsolved.first(where: { hintedGroups.contains($0) }) ?? unsolved.first
    }

    /// A hint is refused when only one group is left (it would be free anyway),
    /// unless that group was already hinted.
    var canUseHint: Bool {
        guard let index = nextHintGroupIndex else { return false }
        let unsolvedCount = puzzle.groups.count - solvedGroupIndices.count
        return hintedGroups.contains(index) || unsolvedCount >= 2
    }

    /// Opens a hint. Re-opening the same group doesn't cost another hint.
    @discardableResult
    func revealHint() -> Bool {
        guard canUseHint, let index = nextHintGroupIndex else { return false }
        hintedGroups.insert(index)
        return true
    }

    /// "Auto-Solve Group" button: solves the hinted group. Not a mistake.
    func autoSolveHintGroup() -> SubmissionResult? {
        guard let index = nextHintGroupIndex, hintedGroups.contains(index) else { return nil }

        solvedGroupIndices.insert(index)
        selectedWords.removeAll()
        lastGuessWasOneAway = false
        Haptics.success()

        return isWon ? .won : .correct
    }

    // MARK: - Check Answer

    func submitGuess() -> SubmissionResult {

        guard selectedWords.count == 4 else {
            return .notEnoughSelected
        }

        let guess = selectedWords

        // Check whether the selected words match an unsolved group.
        for index in puzzle.groups.indices {

            guard !solvedGroupIndices.contains(index) else {
                continue
            }

            let correctWords = Set(puzzle.groups[index].words)

            if guess == correctWords {

                solvedGroupIndices.insert(index)
                selectedWords.removeAll()
                lastGuessWasOneAway = false

                Haptics.success()

                if isWon {
                    return .won
                }

                return .correct
            }
        }

        // Incorrect answer: check whether three of the four words
        // belong to the same category.
        var isOneAway = false

        for index in puzzle.groups.indices {

            guard !solvedGroupIndices.contains(index) else {
                continue
            }

            let correctWords = Set(puzzle.groups[index].words)
            let matchingWords = guess.intersection(correctWords)

            if matchingWords.count == 3 {
                isOneAway = true
            }
        }

        // Add one mistake.
        mistakes += 1
        selectedWords.removeAll()
        lastGuessWasOneAway = isOneAway

        Haptics.error()

        if isGameOver {
            return .gameOver
        }

        if isOneAway {
            return .oneAway
        }

        return .incorrect
    }
}

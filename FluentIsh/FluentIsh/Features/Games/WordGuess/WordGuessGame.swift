//
//  WordGuessGame.swift
//  FluentIsh
//
//  The rules of one Word Guess game, with no UI and no Firebase, so every
//  rule can be unit tested (FluentIshTests/WordGuessGameTests).
//
//  Game logic ported from design/ai-studio/src/pages/GamesAndExercises.tsx
//  (lines 682–908: handleKeyClick, isWgWon, isWgComplete), with the rules
//  from docs/plan.md instead of the prototype's:
//  - 6 guesses, not 5; the word length comes from the puzzle, not "6".
//  - Colours come from GameRules.feedback (repeated letters, accents
//    ignored, Ñ kept).
//  - Score comes from ProgressRules.wordGuessScore; each hint costs 5 XP,
//    which ProgressRules.gameXP already subtracts using `hintsUsed`.
//  - A hint reveals one letter, in order (1st, then 2nd), at most 2, and
//    never the whole word. No "Solve CHARLA" button.
//  - V1 accepts any guess of the right length (no dictionary check).
//
//  It's a struct (a value type): the view keeps one in @State, and every
//  `mutating` call below produces a new state that SwiftUI redraws.
//

import Foundation

// `nonisolated`: the project makes types @MainActor by default. Pure rules
// don't touch the UI, so they opt out and can run (and be tested) anywhere,
// like GameRules and ProgressRules.
nonisolated struct WordGuessGame: Equatable {

    static let maxGuesses = 6
    static let maxHints = 2

    /// Today's answer, normalized (uppercase, no accents) so it can be
    /// compared letter by letter with what the player types.
    let answer: String
    /// Number of tiles per row (`puzzle.wordGuess.length`).
    let length: Int

    /// Submitted guesses, oldest first. `private(set)`: the view can read
    /// them but only the functions below can change them.
    private(set) var guesses: [String] = []
    /// The row being typed right now (0…length letters).
    private(set) var current: String = ""
    private(set) var hintsUsed: Int = 0

    /// Starts a new game, or rebuilds one saved earlier today from
    /// `dailyLog.games["wordGuess"]`. Because hints always reveal letters
    /// in the same order, `hintsUsed` alone is enough to restore them.
    init(answer: String, length: Int, restoring saved: GameResult? = nil) {
        self.answer = GameRules.normalize(answer)
        self.length = length
        if let saved {
            // Clamp in case the saved data is odd, so the board never has
            // more than 6 rows or more hints than allowed.
            guesses = Array((saved.guesses ?? []).map(GameRules.normalize).prefix(Self.maxGuesses))
            hintsUsed = min(max(0, saved.hintsUsed ?? 0), maxHintsForWord)
        }
    }

    // MARK: State

    /// True once any guess matches the answer.
    var isWon: Bool { guesses.contains { GameRules.isSolved(guess: $0, answer: answer) } }

    /// True after 6 guesses without finding the word.
    var isLost: Bool { !isWon && guesses.count >= Self.maxGuesses }

    /// The game is finished either way: no more typing, guesses or hints.
    var isOver: Bool { isWon || isLost }

    /// Green / yellow / grey for one submitted row.
    func feedback(for guess: String) -> [GameRules.LetterResult] {
        GameRules.feedback(guess: guess, answer: answer)
    }

    // MARK: Typing

    /// Adds one letter to the current row. Returns false (and changes
    /// nothing) if the row is full, the game is over, or it isn't a letter.
    /// Accented vowels are accepted and stored without the accent.
    @discardableResult
    mutating func type(_ letter: String) -> Bool {
        let normalized = GameRules.normalize(letter)
        guard !isOver,
              current.count < length,
              normalized.count == 1,
              normalized.first?.isLetter == true else { return false }
        current += normalized
        return true
    }

    /// Removes the last letter of the current row (the ⌫ key).
    mutating func deleteLast() {
        guard !isOver, !current.isEmpty else { return }
        current.removeLast()
    }

    // MARK: Submitting

    enum SubmitOutcome: Equatable {
        case accepted   // added as a new row (the view then checks isWon / isLost)
        case tooShort   // fewer letters than the word: the view shakes the row
        case gameOver   // the game already ended: ignored
    }

    /// ENTER: turns the current row into a guess if it has exactly
    /// `length` letters. V1 doesn't check that it's a real word.
    @discardableResult
    mutating func submit() -> SubmitOutcome {
        guard !isOver else { return .gameOver }
        guard current.count == length else { return .tooShort }
        guesses.append(current)
        current = ""
        return .accepted
    }

    // MARK: Hints

    /// At most 2 hints, and never so many that the whole word is shown
    /// (a 2-letter word only gets 1).
    private var maxHintsForWord: Int { max(0, min(Self.maxHints, length - 1)) }

    var canUseHint: Bool { !isOver && hintsUsed < maxHintsForWord }

    /// Reveals the next letter (1st, then 2nd). Returns false if no hint
    /// is left. The XP cost is applied later by ProgressRules.gameXP.
    @discardableResult
    mutating func useHint() -> Bool {
        guard canUseHint else { return false }
        hintsUsed += 1
        return true
    }

    /// One entry per tile: the revealed letter, or nil if still hidden.
    /// For CHARLA after 1 hint: [C, nil, nil, nil, nil, nil].
    var revealedLetters: [Character?] {
        let letters = Array(answer)
        return (0..<length).map { $0 < hintsUsed && $0 < letters.count ? letters[$0] : nil }
    }

    // MARK: Saving

    /// What to pass to `appState.record(.game(key: "wordGuess", result:))`.
    /// While playing it's `.inProgress` with no score; once won or lost
    /// it's `.completed` with the plan.md score (0 if lost).
    func result() -> GameResult {
        GameResult(
            status: isOver ? .completed : .inProgress,
            score: isOver ? ProgressRules.wordGuessScore(guessesUsed: guesses.count, solved: isWon) : nil,
            mistakes: nil, solvedGroups: nil,
            guesses: guesses,
            filledCells: nil,
            hintsUsed: hintsUsed)
    }
}

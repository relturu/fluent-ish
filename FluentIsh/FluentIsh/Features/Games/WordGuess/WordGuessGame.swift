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
//  - A hint reveals one letter in its correct spot: the leftmost position
//    that isn't green in any guess and isn't revealed yet. There's no fixed
//    limit (plan.md has none); a hint is refused once it would complete the
//    word. No "Solve CHARLA" button.
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
    /// Hints taken (each costs 5 XP through ProgressRules.gameXP). Kept as
    /// its own count, not `revealedPositions.count`: after a restore fewer
    /// positions may be shown (see restoredHintPositions), but the player
    /// still paid for every hint.
    private(set) var hintsUsed: Int = 0
    /// Letter positions (0-based) revealed by hints, in the order taken.
    private(set) var revealedPositions: [Int] = []
    /// True when the saved result says "completed". Firestore's status is
    /// what decides whether today's game is done, so a completed game stays
    /// locked even if its saved guesses look unfinished (e.g. edited in the
    /// console). It can't be played or scored twice.
    private(set) var finishedEarlier = false
    /// The score saved with a completed result, used instead of working it
    /// out again, so the XP shown matches what `record` used.
    private var savedScore: Double?

    /// Starts a new game, or rebuilds one saved earlier today from
    /// `dailyLog.games["wordGuess"]`. Only `hintsUsed` is saved, so the
    /// revealed positions are recomputed with the same hint rule.
    init(answer: String, length: Int, restoring saved: GameResult? = nil) {
        self.answer = GameRules.normalize(answer)
        self.length = length
        if let saved {
            // Clamp in case the saved data is odd, so the board never has
            // more than 6 rows.
            guesses = Array((saved.guesses ?? []).map(GameRules.normalize).prefix(Self.maxGuesses))
            hintsUsed = max(0, saved.hintsUsed ?? 0)
            revealedPositions = Self.restoredHintPositions(guesses: guesses, hintsUsed: hintsUsed,
                                                           answer: self.answer, length: length)
            if saved.status == .completed {
                finishedEarlier = true
                savedScore = saved.score
            }
        }
    }

    // MARK: State

    /// True once any guess matches the answer.
    var isWon: Bool { guesses.contains { GameRules.isSolved(guess: $0, answer: answer) } }

    /// True after 6 guesses without finding the word.
    var isLost: Bool { !isWon && guesses.count >= Self.maxGuesses }

    /// The game is finished (won, lost, or saved as completed earlier):
    /// no more typing, guesses or hints.
    var isOver: Bool { isWon || isLost || finishedEarlier }

    /// plan.md score: 1.0 for guess 1 … 1/6 for guess 6, 0 if not solved.
    /// For a game completed earlier, the score that was saved with it.
    var score: Double {
        if finishedEarlier, let savedScore { return savedScore }
        return ProgressRules.wordGuessScore(guessesUsed: guesses.count, solved: isWon)
    }

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

    /// True when the Submit button should be enabled: the row being typed
    /// has every letter and the game is still going. Same check as the
    /// guards in `submit()`, so an enabled Submit is always `.accepted`.
    var canSubmit: Bool { !isOver && current.count == length }

    /// The Submit button: turns the current row into a guess if it has
    /// exactly `length` letters. V1 doesn't check that it's a real word.
    @discardableResult
    mutating func submit() -> SubmitOutcome {
        guard !isOver else { return .gameOver }
        guard current.count == length else { return .tooShort }
        guesses.append(current)
        current = ""
        return .accepted
    }

    // MARK: Hints

    /// Positions that are green in at least one guess: the player already
    /// knows those letters, so a hint never spends XP on them.
    static func greenPositions(guesses: [String], answer: String) -> Set<Int> {
        var green = Set<Int>()
        for guess in guesses {
            for (index, result) in GameRules.feedback(guess: guess, answer: answer).enumerated()
            where result == .correct {
                green.insert(index)
            }
        }
        return green
    }

    /// The hint rule. The leftmost position that isn't green in any guess
    /// and isn't revealed yet, or nil if there is none, or if revealing it
    /// would leave no unknown letter (that would complete the word).
    static func nextHintPosition(guesses: [String], revealed: [Int], answer: String, length: Int) -> Int? {
        let known = greenPositions(guesses: guesses, answer: answer).union(revealed)
        let unknown = (0..<min(length, answer.count)).filter { !known.contains($0) }
        // Fewer than 2 unknown letters: revealing one would finish the word.
        guard unknown.count >= 2 else { return nil }
        return unknown.first
    }

    /// Rebuilds the revealed positions after a restore by applying the hint
    /// rule `hintsUsed` times to the saved guesses.
    ///
    /// Edge case: while playing, a hint only sees the guesses made before
    /// it. Here every saved guess counts. So if a revealed position later
    /// turned green (the player typed the hinted letter), the rule skips it
    /// and reveals the next unknown letter instead: one extra letter for
    /// free. It can also show fewer letters than `hintsUsed` when the rule
    /// runs out. XP is unaffected either way: it comes from `hintsUsed`.
    static func restoredHintPositions(guesses: [String], hintsUsed: Int, answer: String, length: Int) -> [Int] {
        var revealed: [Int] = []
        for _ in 0..<max(0, hintsUsed) {
            guard let next = nextHintPosition(guesses: guesses, revealed: revealed,
                                              answer: answer, length: length) else { break }
            revealed.append(next)
        }
        return revealed
    }

    /// Where the next hint would go, or nil if no hint can be used now.
    var nextHintPosition: Int? {
        guard !isOver else { return nil }
        return Self.nextHintPosition(guesses: guesses, revealed: revealedPositions, answer: answer, length: length)
    }

    var canUseHint: Bool { nextHintPosition != nil }

    /// Reveals one more letter. Returns false if no hint can be used. The
    /// XP cost is applied later by ProgressRules.gameXP (never below 0).
    @discardableResult
    mutating func useHint() -> Bool {
        guard let position = nextHintPosition else { return false }
        revealedPositions.append(position)
        hintsUsed += 1
        return true
    }

    /// One entry per tile: the revealed letter, or nil if still hidden.
    /// For CHARLA after 1 hint: [C, nil, nil, nil, nil, nil].
    var revealedLetters: [Character?] {
        let letters = Array(answer)
        return (0..<length).map { revealedPositions.contains($0) && $0 < letters.count ? letters[$0] : nil }
    }

    // MARK: Saving

    /// What to pass to `appState.record(.game(key: "wordGuess", result:))`.
    /// While playing it's `.inProgress` with no score; once won or lost
    /// it's `.completed` with the plan.md score (0 if lost).
    func result() -> GameResult {
        GameResult(
            status: isOver ? .completed : .inProgress,
            score: isOver ? score : nil,
            mistakes: nil, solvedGroups: nil,
            guesses: guesses,
            filledCells: nil,
            hintsUsed: hintsUsed)
    }

    /// The XP this finished game earned, or nil while it's still going.
    /// Used when a finished game is reopened: DailyLog doesn't store XP per
    /// game, but `record` awards exactly this the one time a game is
    /// completed (ProgressRules.xp(for:)), and a completed result is never
    /// overwritten, so working it out again gives the same number.
    var xpEarned: Int? {
        guard isOver else { return nil }
        return ProgressRules.gameXP(score: score, hintsUsed: hintsUsed)
    }

    /// Minutes to send with the next save. `record` *adds* the minutes it's
    /// given to today's log on every call, so each save sends only what
    /// hasn't been sent yet. plan.md counts time on the screen rounded up
    /// to whole minutes, with at least 1. Example: saves at 0:20, 0:50 and
    /// 1:30 send 1, 0 and 1 (2 minutes in total).
    static func minutesToRecord(secondsOnScreen: TimeInterval, alreadyRecorded: Int) -> Int {
        let total = max(1, Int((secondsOnScreen / 60).rounded(.up)))
        return max(0, total - alreadyRecorded)
    }
}

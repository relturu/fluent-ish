//
//  WordCookiesGame.swift
//  FluentIsh
//
//  The rules of one Word Cookies game, with no UI and no Firebase, so every
//  rule can be unit tested (FluentIshTests/WordCookiesGameTests).
//
//  Rules from docs/plan.md "Word Cookies":
//  - The day's base word is split into letter tiles. The player spells
//    words from them; each tile is used at most once per word.
//  - Only words on the puzzle's list count (no dictionary, no bonus words).
//  - Tiles are uppercase with accents dropped, except Ñ, which is its own
//    letter. This file has its own `tiles(_:)` and doesn't use Word Guess
//    code (GameRules.normalize turns Ñ into N).
//  - A hint reveals the leftmost hidden letter of the first unfound word
//    (grid order) that still has 2+ hidden letters, so a hint never gives
//    a whole word away. At most 3; each costs 5 XP via ProgressRules.gameXP.
//  - You can't lose: the score is always 1.0 (ProgressRules.wordCookiesScore).
//
//  It's a struct (a value type): the view keeps one in @State, and every
//  `mutating` call below produces a new state that SwiftUI redraws.
//

import Foundation

// `nonisolated`: the project makes types @MainActor by default. Pure rules
// don't touch the UI, so they opt out and can run (and be tested) anywhere.
nonisolated struct WordCookiesGame: Equatable {

    static let maxHints = 3
    static let minWordLength = 3

    /// One row of the slot grid: a word to find.
    struct Row: Equatable {
        let word: String      // tile form, e.g. "AREA": what the player spells
        let display: String   // as written, e.g. "área": shown once found
        let en: String        // English shown once found
        let wordId: String?   // words/{id}, for the word bank
    }

    /// One letter slot revealed by a hint: `index` is 0-based in `word`.
    struct Cell: Hashable {
        let word: String
        let index: Int

        /// How it's saved in GameResult.revealedLetters: "TAREA:0".
        /// One string per cell, because Firestore can't store arrays inside arrays.
        var saved: String { "\(word):\(index)" }

        /// Parses "TAREA:0". nil if it isn't in that shape.
        init?(saved: String) {
            guard let colon = saved.lastIndex(of: ":"),
                  let index = Int(saved[saved.index(after: colon)...]) else { return nil }
            self.init(word: String(saved[..<colon]), index: index)
        }

        init(word: String, index: Int) {
            self.word = word
            self.index = index
        }
    }

    /// The slot grid, shortest words first, then alphabetical.
    let rows: [Row]
    /// The tiles in their current order (one letter each). Shuffle changes
    /// the order, never the letters.
    private(set) var tiles: [String]
    /// Words found, in tile form, in the order they were found.
    private(set) var foundWords: [String] = []
    /// Letters revealed by hints, in the order taken.
    private(set) var revealedCells: [Cell] = []
    /// Hints taken. Kept as its own count, not `revealedCells.count`: if a
    /// saved cell turns out to be invalid on restore, the player still paid.
    private(set) var hintsUsed: Int = 0
    /// True when the saved result says "completed". Firestore's status is
    /// what decides whether today's game is done, so a completed game stays
    /// locked even if its saved words look unfinished.
    private(set) var finishedEarlier = false
    /// The score saved with a completed result, used instead of working it
    /// out again, so the XP shown matches what `record` used.
    private var savedScore: Double?

    /// Starts a new game, or rebuilds one saved earlier today from
    /// `dailyLog.games["wordCookies"]`. Saved words and cells that aren't
    /// part of this puzzle are ignored.
    init(puzzle: WordCookiesPuzzle, restoring saved: GameResult? = nil) {
        tiles = Self.tiles(puzzle.letters).map(String.init)
        rows = Self.rows(for: puzzle.words)

        guard let saved else { return }
        let words = Set(rows.map(\.word))
        for word in (saved.foundWords ?? []).map(Self.tiles)
        where words.contains(word) && !foundWords.contains(word) {
            foundWords.append(word)
        }
        for cell in (saved.revealedLetters ?? []).compactMap(Cell.init(saved:))
        where rows.contains(where: { $0.word == cell.word && cell.index >= 0 && cell.index < $0.word.count })
            && !revealedCells.contains(cell) {
            revealedCells.append(cell)
        }
        hintsUsed = min(Self.maxHints, max(0, saved.hintsUsed ?? revealedCells.count))
        if saved.status == .completed {
            finishedEarlier = true
            savedScore = saved.score
        }
    }

    // MARK: Letters

    /// A word in tile form: uppercase, every accent dropped (á→A, è→E, ç→C,
    /// ü→U), except Ñ, which stays its own letter. Anything that isn't a
    /// letter (spaces, hyphens) is dropped.
    ///
    /// Not `.folding(options: .diacriticInsensitive)`: that turns Ñ into N.
    static func tiles(_ text: String) -> String {
        var result = ""
        for character in text.uppercased() {
            // Split "Á" into "A" + a combining accent mark, keep the base letter.
            let scalars = String(character).decomposedStringWithCanonicalMapping.unicodeScalars
            guard let base = scalars.first, base.properties.isAlphabetic else { continue }
            if base == "N" && scalars.contains("\u{0303}") {
                result += "Ñ"   // N + combining tilde
            } else {
                result.unicodeScalars.append(base)
            }
        }
        return result
    }

    /// The grid rows: one per distinct word, shortest first, then A–Z.
    static func rows(for words: [WordCookiesWord]) -> [Row] {
        var rows: [Row] = []
        for word in words {
            let tileForm = tiles(word.word)
            guard !rows.contains(where: { $0.word == tileForm }) else { continue }
            rows.append(Row(word: tileForm, display: word.word, en: word.en, wordId: word.wordId))
        }
        return rows.sorted { a, b in
            a.word.count != b.word.count ? a.word.count < b.word.count : a.word < b.word
        }
    }

    // MARK: State

    /// Every word on the list has been found.
    var isComplete: Bool { rows.allSatisfy { foundWords.contains($0.word) } }

    /// The game is finished (complete, or saved as completed earlier):
    /// no more words or hints.
    var isOver: Bool { isComplete || finishedEarlier }

    /// Always 1.0 (you can't lose). For a game completed earlier, the score
    /// that was saved with it.
    var score: Double {
        if finishedEarlier, let savedScore { return savedScore }
        return ProgressRules.wordCookiesScore()
    }

    func isFound(_ word: String) -> Bool { foundWords.contains(word) }

    /// Positions in `word` revealed by hints.
    func revealedIndices(in word: String) -> Set<Int> {
        Set(revealedCells.filter { $0.word == word }.map(\.index))
    }

    /// Words with at least one letter revealed by a hint. They don't count
    /// as "correct" in the word bank (GameMix.wordCookiesAnswers).
    var hintedWords: Set<String> { Set(revealedCells.map(\.word)) }

    // MARK: Submitting

    enum SubmitOutcome: Equatable {
        case found          // a new word from the list: it fills its row
        case alreadyFound   // on the list, but found before
        case notInList      // not one of the puzzle's words: the view shakes
        case tooShort       // fewer than 3 letters
        case ignored        // a tile used twice, a bad index, or the game is over
    }

    /// Checks the word spelled by these tiles (positions in `tiles`, in the
    /// order the player dragged across them).
    @discardableResult
    mutating func submit(_ tileIndices: [Int]) -> SubmitOutcome {
        guard !isOver,
              Set(tileIndices).count == tileIndices.count,
              tileIndices.allSatisfy({ tiles.indices.contains($0) }) else { return .ignored }
        guard tileIndices.count >= Self.minWordLength else { return .tooShort }

        let word = tileIndices.map { tiles[$0] }.joined()
        if foundWords.contains(word) { return .alreadyFound }
        guard rows.contains(where: { $0.word == word }) else { return .notInList }
        foundWords.append(word)
        return .found
    }

    /// The word these tiles spell, for showing above the circle while dragging.
    func spelled(_ tileIndices: [Int]) -> String {
        tileIndices.filter { tiles.indices.contains($0) }.map { tiles[$0] }.joined()
    }

    // MARK: Shuffle

    /// Rearranges the tiles. Free, and not saved: a reopened game starts
    /// with the tiles in the puzzle's order. Tries a few times to make the
    /// order actually change.
    mutating func shuffle<G: RandomNumberGenerator>(using generator: inout G) {
        let before = tiles
        for _ in 0..<10 {
            tiles.shuffle(using: &generator)
            if tiles != before { return }
        }
    }

    mutating func shuffle() {
        var generator = SystemRandomNumberGenerator()
        shuffle(using: &generator)
    }

    // MARK: Hints

    /// Where the next hint would go: the leftmost hidden letter of the first
    /// unfound row with 2+ hidden letters. nil if the game is over, all 3
    /// hints are used, or every unfound word is down to 1 hidden letter.
    var nextHintCell: Cell? {
        guard !isOver, hintsUsed < Self.maxHints else { return nil }
        for row in rows where !isFound(row.word) {
            let revealed = revealedIndices(in: row.word)
            let hidden = (0..<row.word.count).filter { !revealed.contains($0) }
            // 2+ hidden: revealing one still leaves the word to find.
            if hidden.count >= 2, let first = hidden.first {
                return Cell(word: row.word, index: first)
            }
        }
        return nil
    }

    var canUseHint: Bool { nextHintCell != nil }

    /// Reveals one more letter. Returns false (and costs nothing) if no hint
    /// can be used. The XP cost is applied later by ProgressRules.gameXP.
    @discardableResult
    mutating func revealHint() -> Bool {
        guard let cell = nextHintCell else { return false }
        revealedCells.append(cell)
        hintsUsed += 1
        return true
    }

    // MARK: Saving

    /// What to pass to `appState.record(.game(key: "wordCookies", result:))`.
    /// While playing it's `.inProgress` with no score; once every word is
    /// found it's `.completed` with score 1.0.
    func result() -> GameResult {
        GameResult(
            status: isOver ? .completed : .inProgress,
            score: isOver ? score : nil,
            mistakes: nil, solvedGroups: nil, guesses: nil, filledCells: nil,
            hintsUsed: hintsUsed,
            foundWords: foundWords,
            revealedLetters: revealedCells.map(\.saved))
    }

    /// The XP this finished game earned, or nil while it's still going:
    /// 30 − 5 per hint. `record` awards exactly this the one time the game
    /// is completed, and a completed result is never overwritten, so working
    /// it out again for a reopened game gives the same number.
    var xpEarned: Int? {
        guard isOver else { return nil }
        return ProgressRules.gameXP(score: score, hintsUsed: hintsUsed)
    }

    /// Minutes to send with the next save. `record` *adds* the minutes it's
    /// given to today's log on every call, so each save sends only what
    /// hasn't been sent yet: time on screen rounded up, at least 1 in total.
    static func minutesToRecord(secondsOnScreen: TimeInterval, alreadyRecorded: Int) -> Int {
        let total = max(1, Int((secondsOnScreen / 60).rounded(.up)))
        return max(0, total - alreadyRecorded)
    }
}

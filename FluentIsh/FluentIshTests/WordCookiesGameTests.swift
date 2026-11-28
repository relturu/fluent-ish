//
//  WordCookiesGameTests.swift
//  FluentIshTests
//
//  Rules of one Word Cookies game (Features/Games/WordCookies/WordCookiesGame),
//  plus its score, XP and word bank results. The puzzles here are test
//  fixtures; the app loads the real ones from Firestore.
//

import Testing
@testable import FluentIsh

struct WordCookiesGameTests {

    /// Sunday's puzzle as first seeded, with 8 words (the seed now has 6).
    /// The rules work for any number of words, so the longer list stays.
    private let regatear = WordCookiesPuzzle(
        baseWordId: "w_regatear", letters: "REGATEAR",
        words: [
            WordCookiesWord(word: "área", en: "area"),
            WordCookiesWord(word: "arte", en: "art"),
            WordCookiesWord(word: "atar", en: "to tie"),
            WordCookiesWord(word: "rata", en: "rat"),
            WordCookiesWord(word: "regar", en: "to water (plants)"),
            WordCookiesWord(word: "tarea", en: "homework, task"),
            WordCookiesWord(word: "tragar", en: "to swallow"),
            WordCookiesWord(word: "regatear", en: "to haggle", wordId: "w_regatear"),
        ])

    /// A small puzzle with 3-letter words, for the hint rules.
    private let mesa = WordCookiesPuzzle(
        baseWordId: "w_mesa", letters: "MESAR",
        words: [
            WordCookiesWord(word: "mar", en: "sea"),
            WordCookiesWord(word: "mes", en: "month"),
            WordCookiesWord(word: "mesa", en: "table", wordId: "w_mesa"),
        ])

    /// Finds tiles that spell `word` (each tile used once), then submits them,
    /// like dragging across the circle.
    @discardableResult
    private func spell(_ word: String, in game: inout WordCookiesGame) -> WordCookiesGame.SubmitOutcome {
        let tileIndices = indices(for: word, in: game)
        return game.submit(tileIndices)
    }

    private func indices(for word: String, in game: WordCookiesGame) -> [Int] {
        var used: [Int] = []
        for letter in word {
            guard let index = game.tiles.indices.first(where: { !used.contains($0) && game.tiles[$0] == String(letter) })
            else { break }
            used.append(index)
        }
        return used
    }

    // MARK: Letters

    @Test func tilesDropAccentsButKeepÑ() {
        #expect(WordCookiesGame.tiles("área") == "AREA")
        #expect(WordCookiesGame.tiles("compañero") == "COMPAÑERO")
        #expect(WordCookiesGame.tiles("Ça è ü") == "CAEU")              // other languages, spaces dropped
        #expect(WordCookiesGame.tiles("an\u{0303}o") == "AÑO")          // ñ typed as n + combining tilde
    }

    @Test func tilesComeFromThePuzzleLetters() {
        let game = WordCookiesGame(puzzle: regatear)
        #expect(game.tiles == ["R", "E", "G", "A", "T", "E", "A", "R"])
    }

    @Test func rowsAreShortestFirstThenAlphabetical() {
        let game = WordCookiesGame(puzzle: regatear)
        #expect(game.rows.map(\.word) == ["AREA", "ARTE", "ATAR", "RATA", "REGAR", "TAREA", "TRAGAR", "REGATEAR"])
        #expect(game.rows.first?.display == "área")      // shown with its accent once found
    }

    // MARK: Submitting

    @Test func wordWithRepeatedLettersIsFound() {
        var game = WordCookiesGame(puzzle: regatear)
        #expect(spell("RATA", in: &game) == .found)       // two A tiles
        #expect(game.isFound("RATA"))
    }

    @Test func accentedWordIsFoundWithoutTheAccent() {
        var game = WordCookiesGame(puzzle: regatear)
        #expect(spell("AREA", in: &game) == .found)       // "área" on the list
    }

    @Test func ñIsItsOwnTile() {
        let puzzle = WordCookiesPuzzle(baseWordId: "w_companero", letters: "COMPAÑERO",
                                       words: [WordCookiesWord(word: "año", en: "year")])
        var game = WordCookiesGame(puzzle: puzzle)
        #expect(game.tiles.contains("Ñ"))
        #expect(!game.tiles.contains("N"))
        #expect(spell("AÑO", in: &game) == .found)
    }

    @Test func aTileCanOnlyBeUsedOncePerWord() {
        var game = WordCookiesGame(puzzle: regatear)
        let t = game.tiles.firstIndex(of: "T")!
        let a = game.tiles.firstIndex(of: "A")!
        let r = game.tiles.firstIndex(of: "R")!
        // A-T-A-R reusing the same A tile: rejected, nothing found.
        let reused = game.submit([a, t, a, r])
        let outOfRange = game.submit([0, 1, 99])         // not a tile
        #expect(reused == .ignored)
        #expect(outOfRange == .ignored)
        #expect(game.foundWords.isEmpty)
    }

    @Test func shortAndUnlistedWordsAreRejected() {
        var game = WordCookiesGame(puzzle: regatear)
        let short = game.submit([0, 1])
        #expect(short == .tooShort)
        #expect(spell("GATA", in: &game) == .notInList)   // a real word, but not on the list
    }

    @Test func findingAWordTwiceSaysAlreadyFound() {
        var game = WordCookiesGame(puzzle: regatear)
        spell("ARTE", in: &game)
        #expect(spell("ARTE", in: &game) == .alreadyFound)
        #expect(game.foundWords == ["ARTE"])
    }

    @Test func spelledShowsTheCurrentWord() {
        let game = WordCookiesGame(puzzle: regatear)
        #expect(game.spelled([0, 1, 2]) == "REG")
    }

    // MARK: Shuffle

    @Test func shuffleKeepsLettersAndFoundWords() {
        var game = WordCookiesGame(puzzle: regatear)
        spell("ARTE", in: &game)
        var generator = SeededGenerator(seed: "test")
        game.shuffle(using: &generator)
        #expect(game.tiles != ["R", "E", "G", "A", "T", "E", "A", "R"])
        #expect(game.tiles.sorted() == ["A", "A", "E", "E", "G", "R", "R", "T"])
        #expect(game.foundWords == ["ARTE"])
        #expect(spell("RATA", in: &game) == .found)       // still playable after the shuffle
    }

    // MARK: Hints

    @Test func hintRevealsLeftmostLetterOfFirstUnfoundWord() {
        var game = WordCookiesGame(puzzle: regatear)
        spell("AREA", in: &game)                          // first row is found: skip it
        let first = game.revealHint()
        #expect(first)
        #expect(game.revealedCells == [.init(word: "ARTE", index: 0)])
        let second = game.revealHint()
        #expect(second)
        #expect(game.revealedIndices(in: "ARTE") == [0, 1])
    }

    @Test func atMostThreeHints() {
        var game = WordCookiesGame(puzzle: regatear)
        for _ in 0..<3 { game.revealHint() }
        #expect(!game.canUseHint)
        let fourth = game.revealHint()
        #expect(!fourth)
        #expect(game.hintsUsed == 3)
    }

    @Test func aHintNeverCompletesAWord() {
        var game = WordCookiesGame(puzzle: mesa)
        game.revealHint()                                 // MAR:0
        game.revealHint()                                 // MAR:1, 1 letter left
        game.revealHint()                                 // so the next goes to MES
        #expect(game.revealedIndices(in: "MAR") == [0, 1])
        #expect(game.revealedIndices(in: "MES") == [0])
    }

    @Test func noHintWhenEveryWordHasOneLetterLeft() {
        let puzzle = WordCookiesPuzzle(baseWordId: "w_mar", letters: "MAR",
                                       words: [WordCookiesWord(word: "mar", en: "sea")])
        var game = WordCookiesGame(puzzle: puzzle)
        game.revealHint()
        game.revealHint()
        // MAR has 1 hidden letter: a third hint would give it away.
        let third = game.revealHint()
        #expect(!third)
        #expect(game.hintsUsed == 2)                      // a refused hint costs nothing
    }

    // MARK: Finishing

    @Test func findingEveryWordCompletesTheGame() {
        var game = WordCookiesGame(puzzle: regatear)
        for row in game.rows.dropLast() { spell(row.word, in: &game) }
        #expect(!game.isComplete)
        #expect(game.result().status == .inProgress)
        #expect(game.result().score == nil)
        #expect(game.xpEarned == nil)

        spell("REGATEAR", in: &game)
        #expect(game.isComplete)
        #expect(game.result().status == .completed)
        #expect(game.result().score == 1.0)
        #expect(game.xpEarned == 30)
        let afterEnd = game.submit([0, 1, 2])
        #expect(afterEnd == .ignored)                     // nothing more to play
    }

    @Test func eachHintCostsFiveXP() {
        var game = WordCookiesGame(puzzle: regatear)
        game.revealHint()
        game.revealHint()
        for row in game.rows { spell(row.word, in: &game) }
        #expect(game.xpEarned == 20)                      // 30 − 2 × 5
        #expect(ProgressRules.wordCookiesScore() == 1.0)
    }

    // MARK: Restoring

    @Test func restoresFoundWordsAndHints() {
        var game = WordCookiesGame(puzzle: regatear)
        spell("ARTE", in: &game)
        game.revealHint()                                 // AREA:0
        let saved = game.result()
        #expect(saved.foundWords == ["ARTE"])
        #expect(saved.revealedLetters == ["AREA:0"])

        let restored = WordCookiesGame(puzzle: regatear, restoring: saved)
        #expect(restored.foundWords == ["ARTE"])
        #expect(restored.revealedIndices(in: "AREA") == [0])
        #expect(restored.hintsUsed == 1)
        #expect(!restored.isOver)
    }

    @Test func restoreIgnoresWordsAndCellsNotInThePuzzle() {
        let saved = GameResult(status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
                               guesses: nil, filledCells: nil, hintsUsed: 1,
                               foundWords: ["GATA", "tarea", "TAREA"],
                               revealedLetters: ["GATA:0", "AREA:9", "nonsense", "AREA:1"])
        let game = WordCookiesGame(puzzle: regatear, restoring: saved)
        #expect(game.foundWords == ["TAREA"])
        #expect(game.revealedCells == [.init(word: "AREA", index: 1)])
    }

    @Test func aCompletedGameStaysLocked() {
        let saved = GameResult(status: .completed, score: 1.0, mistakes: nil, solvedGroups: nil,
                               guesses: nil, filledCells: nil, hintsUsed: 1,
                               foundWords: ["ARTE"], revealedLetters: ["AREA:0"])
        let game = WordCookiesGame(puzzle: regatear, restoring: saved)
        #expect(game.isOver)
        #expect(game.result().status == .completed)
        #expect(game.xpEarned == 25)
        #expect(!game.canUseHint)
    }

    // MARK: Word bank

    @Test func wordBankGetsFoundWordsWithAWordId() {
        var game = WordCookiesGame(puzzle: mesa)
        game.revealHint()                                 // MAR:0 (MAR has no word doc)
        game.revealHint()                                 // MAR:1
        game.revealHint()                                 // MES:0
        for row in game.rows { spell(row.word, in: &game) }
        let answers = GameMix.wordCookiesAnswers(rows: game.rows, foundWords: game.foundWords,
                                                 hintedWords: game.hintedWords)
        #expect(answers == [VocabAnswer(wordId: "w_mesa", correct: true)])
    }

    @Test func aHintedWordCountsAsWrong() {
        let puzzle = WordCookiesPuzzle(baseWordId: "w_mesa", letters: "MESA",
                                       words: [WordCookiesWord(word: "mesa", en: "table", wordId: "w_mesa")])
        var game = WordCookiesGame(puzzle: puzzle)
        game.revealHint()
        spell("MESA", in: &game)
        let answers = GameMix.wordCookiesAnswers(rows: game.rows, foundWords: game.foundWords,
                                                 hintedWords: game.hintedWords)
        #expect(answers == [VocabAnswer(wordId: "w_mesa", correct: false)])
    }

    // MARK: Minutes

    @Test func minutesAreSentOnlyOnce() {
        #expect(WordCookiesGame.minutesToRecord(secondsOnScreen: 20, alreadyRecorded: 0) == 1)
        #expect(WordCookiesGame.minutesToRecord(secondsOnScreen: 50, alreadyRecorded: 1) == 0)
        #expect(WordCookiesGame.minutesToRecord(secondsOnScreen: 90, alreadyRecorded: 1) == 1)
    }
}

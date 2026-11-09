//
//  WordGuessGameTests.swift
//  FluentIshTests
//
//  Rules of one Word Guess game (Features/Games/WordGuess/WordGuessGame).
//  Colours and scoring themselves are tested in GameRulesTests and
//  ProgressRulesTests; these check the game uses them correctly.
//  The words here are test fixtures only; the app loads the real answer
//  from Firestore.
//

import Testing
@testable import FluentIsh

struct WordGuessGameTests {

    /// Types a whole word and presses ENTER.
    private func guess(_ word: String, in game: inout WordGuessGame) -> WordGuessGame.SubmitOutcome {
        for letter in word { game.type(String(letter)) }
        return game.submit()
    }

    // MARK: Typing

    @Test func typingStopsAtWordLength() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        for letter in "CHARLAS" { game.type(String(letter)) }
        #expect(game.current == "CHARLA")
        // #expect can't call a mutating function itself, so call it first.
        let accepted = game.type("X")
        #expect(!accepted)
    }

    @Test func typingNormalizesAndRejectsNonLetters() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        game.type("á")      // accent dropped, uppercased
        game.type("ñ")      // Ñ kept as its own letter
        game.type("3")      // ignored
        game.type("")       // ignored
        #expect(game.current == "AÑ")
    }

    @Test func deleteRemovesLastLetter() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        game.type("C"); game.type("H")
        game.deleteLast()
        #expect(game.current == "C")
        game.deleteLast(); game.deleteLast()   // deleting an empty row is harmless
        #expect(game.current == "")
    }

    // MARK: Submitting

    @Test func shortGuessIsRejected() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        #expect(guess("CHARL", in: &game) == .tooShort)
        #expect(game.guesses.isEmpty)
        #expect(game.current == "CHARL")    // kept so the player can finish it
    }

    @Test func anyFullLengthGuessIsAccepted() {
        // V1 has no dictionary check.
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        #expect(guess("ZZZZZZ", in: &game) == .accepted)
        #expect(game.guesses == ["ZZZZZZ"])
        #expect(game.current == "")
    }

    @Test func boardLengthComesFromThePuzzle() {
        var game = WordGuessGame(answer: "CAFÉ", length: 4)
        #expect(guess("CAFE", in: &game) == .accepted)
        #expect(game.isWon)                 // accents don't matter
    }

    // MARK: Win and loss

    @Test func solvingOnGuessTwoScoresFiveSixths() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        _ = guess("CAMINO", in: &game)
        _ = guess("charla", in: &game)
        #expect(game.isWon && game.isOver && !game.isLost)
        let result = game.result()
        #expect(result.status == .completed)
        #expect(abs((result.score ?? 0) - 5.0 / 6) < 1e-9)
        #expect(result.guesses == ["CAMINO", "CHARLA"])
    }

    @Test func sixWrongGuessesLosesWithScoreZero() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        for _ in 0..<6 { _ = guess("CORTAR", in: &game) }
        #expect(game.isLost && game.isOver)
        #expect(game.result().status == .completed)
        #expect(game.result().score == 0)
    }

    @Test func nothingChangesAfterTheGameEnds() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        _ = guess("CHARLA", in: &game)
        let typed = game.type("A")
        let submitted = game.submit()
        let hinted = game.useHint()
        #expect(!typed)
        #expect(submitted == .gameOver)
        #expect(!hinted)
        #expect(game.guesses.count == 1)
    }

    @Test func unfinishedGameIsInProgressWithNoScore() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        _ = guess("CAMINO", in: &game)
        #expect(game.result().status == .inProgress)
        #expect(game.result().score == nil)
    }

    // MARK: Hints
    // CHARLA is the answer below. CAMINO and CORTAR both get only the C
    // (position 0) green, which is what the "skips green" tests rely on.

    @Test func hintRevealsLeftmostUnknownLetterAndCountsIt() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        #expect(game.revealedLetters == [nil, nil, nil, nil, nil, nil])
        let used = game.useHint()
        #expect(used)
        #expect(game.revealedPositions == [0])
        #expect(game.revealedLetters == ["C", nil, nil, nil, nil, nil])
        #expect(game.hintsUsed == 1)
        #expect(game.result().hintsUsed == 1)
    }

    @Test func hintSkipsLettersAlreadyGreen() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        _ = guess("CAMINO", in: &game)      // C is green, so the hint goes to H
        game.useHint()
        #expect(game.revealedPositions == [1])
        #expect(game.revealedLetters[1] == "H")
    }

    @Test func hintsNeverRepeatAndStopBeforeTheLastLetter() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        while game.useHint() {}             // take every hint allowed
        #expect(game.revealedPositions == [0, 1, 2, 3, 4])
        #expect(Set(game.revealedPositions).count == game.revealedPositions.count)
        #expect(game.hintsUsed == 5)
        #expect(!game.canUseHint)           // the 6th would complete the word
    }

    @Test func hintRefusedWhenOnlyOneLetterIsUnknown() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        _ = guess("CHARLO", in: &game)      // 5 greens, only the last A unknown
        let used = game.useHint()
        #expect(!used)
        #expect(game.hintsUsed == 0)
        #expect(game.nextHintPosition == nil)
    }

    @Test func twoLetterWordGetsOneHint() {
        var game = WordGuessGame(answer: "YA", length: 2)
        let first = game.useHint()
        let second = game.useHint()
        #expect(first)
        #expect(!second)
        #expect(game.revealedLetters.compactMap { $0 }.count < game.length)
    }

    @Test func hintRefusedAfterTheGameEnds() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        _ = guess("CHARLA", in: &game)
        let used = game.useHint()
        #expect(!used)
        #expect(!game.canUseHint)
    }

    @Test func hintsCostFiveXPEachThroughGameXP() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        game.useHint(); game.useHint()
        _ = guess("CHARLA", in: &game)      // score 1.0 → 30 XP, minus 2 × 5
        let result = game.result()
        #expect(ProgressRules.gameXP(score: result.score ?? 0, hintsUsed: result.hintsUsed ?? 0) == 20)
    }

    @Test func manyHintsNeverMakeXPNegative() {
        // No hint limit, so check the floor: 5 hints and a win on guess 6
        // → 30 × 1/6 = 5 XP, minus 25. ProgressRules.gameXP stops at 0.
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        while game.useHint() {}
        for _ in 0..<5 { _ = guess("ZZZZZZ", in: &game) }
        _ = guess("CHARLA", in: &game)
        let result = game.result()
        #expect(result.hintsUsed == 5)
        #expect(ProgressRules.gameXP(score: result.score ?? 0, hintsUsed: result.hintsUsed ?? 0) == 0)
    }

    // MARK: Restoring

    @Test func restoresGuessesAndHintsFromSavedResult() {
        let saved = GameResult(status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
                               guesses: ["CAMINO", "cortar"], filledCells: nil, hintsUsed: 1)
        let game = WordGuessGame(answer: "CHARLA", length: 6, restoring: saved)
        #expect(game.guesses == ["CAMINO", "CORTAR"])
        #expect(game.hintsUsed == 1)
        #expect(game.revealedPositions == [1])  // C is green, so the hint is H
        #expect(!game.isOver)
    }

    @Test func restoreMatchesLivePlayWhenHintedLetterIsNotTyped() {
        // Guess, take a hint, guess again without the hinted letter.
        var live = WordGuessGame(answer: "CHARLA", length: 6)
        _ = guess("CAMINO", in: &live)
        live.useHint()                      // reveals H (position 1)
        _ = guess("CORTAR", in: &live)
        let restored = WordGuessGame(answer: "CHARLA", length: 6, restoring: live.result())
        #expect(restored.revealedPositions == live.revealedPositions)
        #expect(restored.hintsUsed == live.hintsUsed)
    }

    @Test func restoreCanShiftAHintWhenTheHintedLetterTurnedGreen() {
        // The known edge case (documented in restoredHintPositions): the
        // hint reveals C, then the player types C and it turns green. The
        // recompute skips the now-green C and shows H instead. XP is the
        // same, because it comes from hintsUsed.
        var live = WordGuessGame(answer: "CHARLA", length: 6)
        live.useHint()                      // reveals C (position 0)
        _ = guess("CORTAR", in: &live)      // C now green
        let restored = WordGuessGame(answer: "CHARLA", length: 6, restoring: live.result())
        #expect(live.revealedPositions == [0])
        #expect(restored.revealedPositions == [1])
        #expect(restored.hintsUsed == 1)
    }

    @Test func restoredHintPositionsFunction() {
        #expect(WordGuessGame.restoredHintPositions(guesses: [], hintsUsed: 2, answer: "CHARLA", length: 6) == [0, 1])
        #expect(WordGuessGame.restoredHintPositions(guesses: ["CAMINO"], hintsUsed: 2, answer: "CHARLA", length: 6) == [1, 2])
        #expect(WordGuessGame.restoredHintPositions(guesses: ["CAMINO"], hintsUsed: 0, answer: "CHARLA", length: 6) == [])
    }

    @Test func restoringAFinishedGameKeepsItFinished() {
        let saved = GameResult(status: .completed, score: 1, mistakes: nil, solvedGroups: nil,
                               guesses: ["CHARLA"], filledCells: nil, hintsUsed: 0)
        let game = WordGuessGame(answer: "CHARLA", length: 6, restoring: saved)
        #expect(game.isWon)
        #expect(game.result().status == .completed)
    }

    @Test func restoringClampsBadData() {
        // 9 guesses → 6 rows. 7 hints paid for, but with only C green the
        // rule can show at most 4 more letters (H A R L), never the last A.
        let saved = GameResult(status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
                               guesses: Array(repeating: "CORTAR", count: 9), filledCells: nil, hintsUsed: 7)
        let game = WordGuessGame(answer: "CHARLA", length: 6, restoring: saved)
        #expect(game.guesses.count == WordGuessGame.maxGuesses)
        #expect(game.revealedPositions == [1, 2, 3, 4])
        #expect(game.hintsUsed == 7)        // XP still charges every hint taken
    }
}

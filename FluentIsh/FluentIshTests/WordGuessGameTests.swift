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

    @Test func hintsRevealLettersInOrderUpToTwo() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        #expect(game.revealedLetters == [nil, nil, nil, nil, nil, nil])
        let first = game.useHint()
        #expect(first)
        #expect(game.revealedLetters == ["C", nil, nil, nil, nil, nil])
        let second = game.useHint()
        #expect(second)
        #expect(game.revealedLetters == ["C", "H", nil, nil, nil, nil])
        let third = game.useHint()
        #expect(!third)                     // a third hint is refused
        #expect(game.result().hintsUsed == 2)
    }

    @Test func hintsNeverRevealTheWholeWord() {
        var game = WordGuessGame(answer: "YA", length: 2)
        let first = game.useHint()
        let second = game.useHint()
        #expect(first)
        #expect(!second)                    // only 1 of 2 letters can be shown
        #expect(game.revealedLetters.compactMap { $0 }.count < game.length)
    }

    @Test func hintsCostFiveXPEachThroughGameXP() {
        var game = WordGuessGame(answer: "CHARLA", length: 6)
        game.useHint(); game.useHint()
        _ = guess("CHARLA", in: &game)      // score 1.0 → 30 XP, minus 2 × 5
        let result = game.result()
        #expect(ProgressRules.gameXP(score: result.score ?? 0, hintsUsed: result.hintsUsed ?? 0) == 20)
    }

    // MARK: Restoring

    @Test func restoresGuessesAndHintsFromSavedResult() {
        let saved = GameResult(status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
                               guesses: ["CAMINO", "cortar"], filledCells: nil, hintsUsed: 1)
        let game = WordGuessGame(answer: "CHARLA", length: 6, restoring: saved)
        #expect(game.guesses == ["CAMINO", "CORTAR"])
        #expect(game.revealedLetters.first == "C")
        #expect(!game.isOver)
    }

    @Test func restoringAFinishedGameKeepsItFinished() {
        let saved = GameResult(status: .completed, score: 1, mistakes: nil, solvedGroups: nil,
                               guesses: ["CHARLA"], filledCells: nil, hintsUsed: 0)
        let game = WordGuessGame(answer: "CHARLA", length: 6, restoring: saved)
        #expect(game.isWon)
        #expect(game.result().status == .completed)
    }

    @Test func restoringClampsBadData() {
        let saved = GameResult(status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
                               guesses: Array(repeating: "CORTAR", count: 9), filledCells: nil, hintsUsed: 7)
        let game = WordGuessGame(answer: "CHARLA", length: 6, restoring: saved)
        #expect(game.guesses.count == WordGuessGame.maxGuesses)
        #expect(game.hintsUsed == WordGuessGame.maxHints)
    }
}

//
//  ConnectionsTests.swift
//  FluentIsh
//
//  Created by Jessica Zheng on 11/8/26.
//

import Testing
import Foundation
@testable import FluentIsh

private enum TestPuzzle {
    static let groupWords: [[String]] = [
        ["cortado", "taza", "azúcar", "leche"],            // 0 cosas del cafe
        ["además", "aunque", "sin embargo", "pues"],       // 1 connectors
        ["charlar", "compartir", "invitar", "brindar"],    // 2 verbs
        ["merienda", "siesta", "madrugada", "sobremesa"],  // 3 momentos del dia
    ]

    static let groupDifficulties: [Int] = [1, 2, 3, 4]
    
    static var allWords: [String] { groupWords.flatMap { $0 } }

    static func make() -> ConnectionsPuzzle {
        ConnectionsPuzzle(groups: groupWords.enumerated().map { index, words in
            ConnectionsGroup(category: "Group \(index)", words: words, difficulty: groupDifficulties[index])
        })
    }
}

// MARK: - Helpers

@MainActor
private func makeModel() -> ConnectionsModel {
    ConnectionsModel(puzzle: TestPuzzle.make())
}

@MainActor
private func select(_ words: [String], in model: ConnectionsModel) {
    for word in words { model.toggleSelection(word) }
}

@MainActor
@discardableResult
private func solve(_ index: Int, in model: ConnectionsModel) -> ConnectionsModel.SubmissionResult {
    select(TestPuzzle.groupWords[index], in: model)
    return model.submitGuess()
}

@MainActor
@discardableResult
private func makeMistake(in model: ConnectionsModel) -> ConnectionsModel.SubmissionResult {
    let g0 = TestPuzzle.groupWords[0]
    let g1 = TestPuzzle.groupWords[1]
    select([g0[0], g0[1], g1[0], g1[1]], in: model)
    return model.submitGuess()
}

// MARK: - Starting state

@MainActor
struct ConnectionsStartTests {
    @Test func startsWithAllSixteenWords() {
        let model = makeModel()
        #expect(model.words.count == 16)
        #expect(Set(model.words) == Set(TestPuzzle.allWords))
        #expect(model.remainingWords.count == 16)
    }

    @Test func startsClean() {
        let model = makeModel()
        #expect(model.selectedWords.isEmpty)
        #expect(model.solvedGroupIndices.isEmpty)
        #expect(model.mistakes == 0)
        #expect(model.remainingMistakes == 4)
        #expect(!model.isWon)
        #expect(!model.isGameOver)
        #expect(!model.isFinished)
    }

    @Test func minutesElapsedIsAtLeastOne() {
        #expect(makeModel().minutesElapsed >= 1)
    }
}

// MARK: - Selecting tiles

@MainActor
struct ConnectionsSelectionTests {
    @Test func tappingSelectsAndTappingAgainDeselects() {
        let model = makeModel()
        model.toggleSelection("cortado")
        #expect(model.selectedWords == ["cortado"])
        model.toggleSelection("cortado")
        #expect(model.selectedWords.isEmpty)
    }

    @Test func atMostFourWordsCanBeSelected() {
        let model = makeModel()
        let four = model.puzzle.groups[0].words
        let extra = model.puzzle.groups[1].words[0]

        select(four + [extra], in: model)

        #expect(model.selectedWords == Set(four))
        #expect(!model.selectedWords.contains(extra))
    }

    @Test func deselectAllClearsTheSelection() {
        let model = makeModel()
        select(["cortado", "sobremesa"], in: model)
        model.deselectAll()
        #expect(model.selectedWords.isEmpty)
    }

    @Test func unknownWordsAreIgnored() {
        let model = makeModel()
        model.toggleSelection("not-in-the-puzzle")
        #expect(model.selectedWords.isEmpty)
    }

    @Test func shuffleKeepsTheSameWords() {
        let model = makeModel()
        model.shuffleWords()
        #expect(model.words.count == 16)
        #expect(Set(model.words) == Set(TestPuzzle.allWords))
    }
}

// MARK: - Submitting guesses

@MainActor
struct ConnectionsSubmitTests {
    @Test func needsFourWordsToSubmit() {
        let model = makeModel()
        select(["cortado", "sobremesa", "merienda"], in: model)
        #expect(model.submitGuess() == .notEnoughSelected)
        #expect(model.mistakes == 0)
        #expect(model.selectedWords.count == 3)   // the selection is kept
    }

    @Test func correctGroupIsSolved() {
        let model = makeModel()
        #expect(solve(0, in: model) == .correct)
        #expect(model.solvedGroupIndices == [0])
        #expect(model.selectedWords.isEmpty)
        #expect(model.mistakes == 0)
    }

    @Test func solvedWordsLeaveTheGrid() {
        let model = makeModel()
        solve(0, in: model)
        #expect(model.remainingWords.count == 12)
        for word in TestPuzzle.groupWords[0] {
            #expect(!model.remainingWords.contains(word))
        }
    }

    @Test func solvedWordsCantBeSelectedAgain() {
        let model = makeModel()
        solve(0, in: model)
        model.toggleSelection("cortado")
        #expect(model.selectedWords.isEmpty)
    }

    @Test func wrongGuessCostsAMistake() {
        let model = makeModel()
        #expect(makeMistake(in: model) == .incorrect)
        #expect(model.mistakes == 1)
        #expect(model.remainingMistakes == 3)
        #expect(model.selectedWords.isEmpty)
        #expect(model.solvedGroupIndices.isEmpty)
        #expect(!model.lastGuessWasOneAway)
    }

    @Test func threeOfFourIsOneAway() {
        let model = makeModel()
        let g0 = TestPuzzle.groupWords[0]
        select([g0[0], g0[1], g0[2], TestPuzzle.groupWords[1][0]], in: model)
        #expect(model.submitGuess() == .oneAway)
        #expect(model.lastGuessWasOneAway)
        #expect(model.mistakes == 1)       // one away still counts as a mistake
    }

    @Test func oneAwayFlagClearsOnTheNextTap() {
        let model = makeModel()
        let g0 = TestPuzzle.groupWords[0]
        select([g0[0], g0[1], g0[2], TestPuzzle.groupWords[1][0]], in: model)
        model.submitGuess()
        model.toggleSelection("cortado")
        #expect(!model.lastGuessWasOneAway)
    }

    @Test func aWrongGuessDoesNotRevealOrSolveAnything() {
        let model = makeModel()
        makeMistake(in: model)
        #expect(model.remainingWords.count == 16)
    }
}

// MARK: - Winning and losing

@MainActor
struct ConnectionsEndgameTests {
    @Test func solvingAllFourGroupsWins() {
        let model = makeModel()
        #expect(solve(0, in: model) == .correct)
        #expect(solve(1, in: model) == .correct)
        #expect(solve(2, in: model) == .correct)
        #expect(solve(3, in: model) == .won)
        #expect(model.isWon)
        #expect(model.isFinished)
        #expect(!model.isGameOver)
        #expect(model.remainingWords.isEmpty)
    }

    @Test func winningKeepsTheMistakeCount() {
        let model = makeModel()
        makeMistake(in: model)
        makeMistake(in: model)
        for index in 0..<4 { solve(index, in: model) }
        #expect(model.isWon)
        #expect(model.mistakes == 2)
    }

    @Test func fourthMistakeEndsTheGame() {
        let model = makeModel()
        #expect(makeMistake(in: model) == .incorrect)
        #expect(makeMistake(in: model) == .incorrect)
        #expect(makeMistake(in: model) == .incorrect)
        #expect(makeMistake(in: model) == .gameOver)
        #expect(model.isGameOver)
        #expect(model.isFinished)
        #expect(!model.isWon)
        #expect(model.remainingMistakes == 0)
    }

    @Test func nothingCanBeSelectedAfterGameOver() {
        let model = makeModel()
        for _ in 0..<4 { makeMistake(in: model) }
        model.toggleSelection("cortado")
        #expect(model.selectedWords.isEmpty)
    }

    @Test func nothingCanBeSelectedAfterWinning() {
        let model = makeModel()
        for index in 0..<4 { solve(index, in: model) }
        model.toggleSelection("cortado")
        #expect(model.selectedWords.isEmpty)
    }

    @Test func shuffleDoesNothingOnceFinished() {
        let model = makeModel()
        for _ in 0..<4 { makeMistake(in: model) }
        let before = model.words
        model.shuffleWords()
        #expect(model.words == before)
    }

    @Test func gameOverKeepsAnyGroupsAlreadySolved() {
        let model = makeModel()
        solve(2, in: model)
        for _ in 0..<4 { makeMistake(in: model) }
        #expect(model.isGameOver)
        #expect(model.solvedGroupIndices == [2])
    }
}


// MARK: - Difficulty Tests

@MainActor
struct ConnectionsDifficultyTests {

    @Test
    func allGroupsHaveDifficultyLevels() {

        let model = makeModel()

        #expect(model.puzzle.groups.count == 4)

        for index in model.puzzle.groups.indices {
            #expect(model.puzzle.groups[index].difficulty >= 1)
            #expect(model.puzzle.groups[index].difficulty <= 4)
        }
    }

    @Test
    func groupsHaveExpectedDifficultyLevels() {

        let model = makeModel()

        for index in model.puzzle.groups.indices {
            #expect(
                model.puzzle.groups[index].difficulty ==
                TestPuzzle.groupDifficulties[index]
            )
        }
    }

    @Test
    func difficultyStaysWithCorrectGroupAfterShuffle() {

        let model = makeModel()

        model.shuffleWords()

        for index in model.puzzle.groups.indices {
            #expect(
                model.puzzle.groups[index].difficulty ==
                TestPuzzle.groupDifficulties[index]
            )
        }
    }

    @Test
    func solvingGroupDoesNotChangeItsDifficulty() {

        let model = makeModel()

        _ = solve(0, in: model)

        #expect(model.puzzle.groups[0].difficulty == 1)
        #expect(model.puzzle.groups[1].difficulty == 2)
    }
}


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

    init(puzzle: ConnectionsPuzzle) {
        self.puzzle = puzzle

        // Combine the four groups into one list of 16 words.
        words = puzzle.groups.flatMap { $0.words }

        // Randomize the initial order.
        words.shuffle()
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

//
//  GameRulesTests.swift
//  FluentIshTests
//

import Testing
@testable import FluentIsh

struct WordGuessFeedbackTests {
    typealias R = GameRules.LetterResult

    @Test func exactMatchIsAllGreen() {
        #expect(GameRules.feedback(guess: "PRECIO", answer: "PRECIO") == Array(repeating: R.correct, count: 6))
    }

    @Test func misplacedLettersAreYellow() {
        // CORTES vs PRECIO: C, O, R and E are all in PRECIO but in other spots.
        #expect(GameRules.feedback(guess: "CORTES", answer: "PRECIO")
                == [.present, .present, .present, .absent, .present, .absent])
    }

    @Test func repeatedLetterOnlyCountsAsOftenAsInAnswer() {
        // Answer PALABR has two As; SALSAS gets one green A and one yellow A, and its Ss stay grey.
        #expect(GameRules.feedback(guess: "SALSAS", answer: "PALABR")
                == [.absent, .correct, .correct, .absent, .present, .absent])
        // Answer has one E: the green E takes it, the other E stays grey.
        #expect(GameRules.feedback(guess: "EEEEEE", answer: "PRECIO")
                == [.absent, .absent, .correct, .absent, .absent, .absent])
    }

    @Test func accentsDontMatterButEnyeDoes() {
        #expect(GameRules.isSolved(guess: "cafe", answer: "CAFÉ"))
        #expect(GameRules.normalize("pingüino") == "PINGUINO")
        #expect(!GameRules.isSolved(guess: "ANO", answer: "AÑO"))
    }
}

struct CrosswordGridTests {
    @Test func blackSquaresFromRows() {
        let grid = GameRules.blackSquares(["PLATO", "A#B#R"])
        #expect(grid[0] == [false, false, false, false, false])
        #expect(grid[1] == [false, true, false, true, false])
    }
}

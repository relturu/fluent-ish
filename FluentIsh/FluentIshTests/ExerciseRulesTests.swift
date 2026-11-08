//
//  ExerciseRulesTests.swift
//  FluentIshTests
//

import Foundation
import Testing
@testable import FluentIsh

struct FillBlankRulesTests {
    @Test func splitsAroundTheBlank() throws {
        let parts = try #require(ExerciseRules.blankParts("Yo ___ café por la mañana."))
        #expect(parts.before == "Yo ")
        #expect(parts.after == " café por la mañana.")
    }

    @Test func blankAtTheStartOrEnd() throws {
        let start = try #require(ExerciseRules.blankParts("¿___ cuesta el pan?"))
        #expect(start.before == "¿")
        let end = try #require(ExerciseRules.blankParts("Hoy hace mucho ___"))
        #expect(end.after == "")
    }

    @Test func noBlankIsNil() {
        #expect(ExerciseRules.blankParts("Hola") == nil)
    }

    @Test func fillsTheSentenceForAudio() {
        let item = ExerciseItem(prompt: "Yo ___ café.", answer: "bebo", choices: nil, promptEn: nil)
        #expect(ExerciseRules.filledSentence(item) == "Yo bebo café.")
    }
}

struct SentenceBuilderRulesTests {
    @Test func tilesComeFromChoices() {
        let item = ExerciseItem(prompt: "I like coffee.", answer: "Me gusta el café.",
                                choices: ["café.", "Me", "el", "gusta"], promptEn: nil)
        #expect(ExerciseRules.tiles(for: item) == ["café.", "Me", "el", "gusta"])
    }

    @Test func tilesFallBackToTheAnswer() {
        let item = ExerciseItem(prompt: "x", answer: "Comemos en casa.", choices: nil, promptEn: nil)
        #expect(ExerciseRules.tiles(for: item) == ["Comemos", "en", "casa."])
    }

    @Test func checksTheOrderIncludingPunctuationTiles() {
        let answer = "¿Quedamos a las ocho en la plaza?"
        #expect(ExerciseRules.isCorrectSentence(
            picked: ["¿Quedamos", "a", "las", "ocho", "en", "la", "plaza?"], answer: answer))
        #expect(!ExerciseRules.isCorrectSentence(
            picked: ["¿Quedamos", "a", "las", "nueve", "en", "la", "plaza?"], answer: answer))
        #expect(!ExerciseRules.isCorrectSentence(picked: ["¿Quedamos"], answer: answer))
    }

    @Test func hintAddsTheNextTile() {
        let tiles = ["café.", "Me", "el", "gusta"]
        #expect(ExerciseRules.hintPlacement(picked: [], tiles: tiles, answer: "Me gusta el café.") == [1])
        #expect(ExerciseRules.hintPlacement(picked: [1], tiles: tiles, answer: "Me gusta el café.") == [1, 3])
    }

    @Test func hintDropsWrongTilesFirst() {
        let tiles = ["café.", "Me", "el", "gusta"]
        // "Me el" is wrong after "Me": keep "Me", drop "el", add "gusta".
        #expect(ExerciseRules.hintPlacement(picked: [1, 2], tiles: tiles, answer: "Me gusta el café.") == [1, 3])
    }

    @Test func hintHandlesRepeatedWords() {
        // Two "la" tiles: the hint must use the second one, not reuse the first.
        let tiles = ["la", "la", "casa", "y"]
        #expect(ExerciseRules.hintPlacement(picked: [0, 2, 3], tiles: tiles, answer: "la casa y la") == [0, 2, 3, 1])
    }

    @Test func hintOnACompleteSentenceChangesNothing() {
        let tiles = ["Hoy", "invito", "yo."]
        #expect(ExerciseRules.hintPlacement(picked: [0, 1, 2], tiles: tiles, answer: "Hoy invito yo.") == [0, 1, 2])
    }
}

struct ExerciseScoringTests {
    @Test func accuracyIsAWholePercent() {
        #expect(ExerciseRules.accuracyPercent(firstTry: 4, total: 4) == 100)
        #expect(ExerciseRules.accuracyPercent(firstTry: 3, total: 4) == 75)
        #expect(ExerciseRules.accuracyPercent(firstTry: 0, total: 3) == 0)
        #expect(ExerciseRules.accuracyPercent(firstTry: 2, total: 3) == 67)
        #expect(ExerciseRules.accuracyPercent(firstTry: 0, total: 0) == 100)
    }

    @Test func minutesRoundUpWithAMinimumOfOne() {
        let start = Date(timeIntervalSince1970: 0)
        #expect(ExerciseRules.minutes(from: start, to: start) == 1)
        #expect(ExerciseRules.minutes(from: start, to: start.addingTimeInterval(59)) == 1)
        #expect(ExerciseRules.minutes(from: start, to: start.addingTimeInterval(61)) == 2)
        #expect(ExerciseRules.minutes(from: start, to: start.addingTimeInterval(120)) == 2)
    }
}

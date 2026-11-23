//
//  ExerciseBuilderTests.swift
//  FluentIshTests
//
//  Skill Exercises built from the user's word bank (word bank restructure,
//  Phase 3): which words are used, how each item is made, and that a day's
//  exercise always comes out the same.
//

import Foundation
import Testing
@testable import FluentIsh

// MARK: Helpers

private func word(_ id: String, _ term: String, lemma: String? = nil, gender: String? = nil,
                  pos: String = "noun", definition: String = "", example: String? = nil,
                  exampleEn: String? = nil) -> Word {
    var w = Word(language: "es", term: term, lemma: lemma ?? term, gender: gender, partOfSpeech: pos,
                 definitionEn: definition.isEmpty ? "meaning of \(term)" : definition,
                 category: "Basics", level: "A2", example: example, exampleEn: exampleEn, azure: nil)
    w.id = id
    return w
}

private let acera = word("w_acera", "la acera", lemma: "acera", gender: "f", definition: "sidewalk",
                         example: "Camina por la acera, que hay mucho tráfico.",
                         exampleEn: "Walk on the sidewalk; there's a lot of traffic.")
private let esquina = word("w_esquina", "la esquina", lemma: "esquina", gender: "f", definition: "corner",
                           example: "Hay una panadería en la esquina.", exampleEn: "There's a bakery on the corner.")
private let cuesta = word("w_cuesta", "la cuesta", lemma: "cuesta", gender: "f", definition: "slope",
                          example: "Esta cuesta es dura.", exampleEn: "This hill is tough.")
private let llave = word("w_llave", "la llave", lemma: "llave", gender: "f", definition: "key",
                         example: "Le dejé una llave a la vecina.", exampleEn: "I left a key with my neighbor.")
private let banco = word("w_banco", "el banco", lemma: "banco", gender: "m", definition: "bench",
                         example: "Nos sentamos en un banco del parque.", exampleEn: "We sat on a park bench.")
private let hola = word("w_hola", "hola", pos: "interjection", definition: "hello",
                        example: "¡Hola! ¿Qué tal?", exampleEn: "Hi! How's it going?")
private let gracias = word("w_gracias", "gracias", pos: "interjection", definition: "thanks",
                           example: "Muchas gracias por tu ayuda.", exampleEn: "Thanks a lot for your help.")
private let adios = word("w_adios", "adiós", pos: "interjection", definition: "goodbye",
                         example: "¡Adiós! Hasta mañana.", exampleEn: "Goodbye! See you tomorrow.")
private let porFavor = word("w_por_favor", "por favor", pos: "expression", definition: "please",
                            example: "Un café, por favor.", exampleEn: "A coffee, please.")
/// Conjugated in its example, so it can't be a Fill in the Blank item.
private let perderse = word("w_perderse", "perderse", pos: "verb", definition: "to get lost",
                            example: "Me encanta perderme por las calles del centro.",
                            exampleEn: "I love getting lost in the streets downtown.")

private let all = [acera, esquina, cuesta, llave, banco, hola, gracias, adios, porFavor, perderse]

// MARK: Finding the blank

struct ExerciseBlankTests {
    @Test func blanksAWordAndKeepsThePunctuation() {
        let found = ExerciseBuilder.blank(hola, in: hola.example!)
        #expect(found?.prompt == "¡___! ¿Qué tal?")
        #expect(found?.answer == "Hola")                      // keeps the example's capital
    }

    @Test func blanksANounWithoutItsArticle() {
        let found = ExerciseBuilder.blank(acera, in: acera.example!)
        #expect(found?.prompt == "Camina por la ___, que hay mucho tráfico.")
        #expect(found?.answer == "acera")
    }

    @Test func blanksAWholeExpression() {
        let found = ExerciseBuilder.blank(porFavor, in: porFavor.example!)
        #expect(found?.prompt == "Un café, ___.")
        #expect(found?.answer == "por favor")
    }

    @Test func conjugatedVerbHasNoBlank() {
        #expect(ExerciseBuilder.blank(perderse, in: perderse.example!) == nil)
    }
}

// MARK: Items

struct ExerciseItemBuilderTests {
    @Test func fillBlankHasTheRightNumberOfUniqueChoices() {
        for (difficulty, expected) in [("easy", 3), ("medium", 4), ("hard", 4)] {
            var rng = SeededGenerator(seed: "test")
            let item = ExerciseBuilder.fillBlank(acera, difficulty: difficulty, pool: all, rng: &rng)
            #expect(item?.choices?.count == expected)
            #expect(Set(item?.choices ?? []).count == expected)
            #expect(item?.choices?.filter { $0 == "acera" }.count == 1)
            #expect(item?.promptEn == acera.exampleEn)
        }
    }

    @Test func fillBlankPrefersNounsOfTheSameGender() {
        // Easy needs 2 wrong choices; esquina, cuesta and llave are feminine nouns.
        var rng = SeededGenerator(seed: "gender")
        let item = ExerciseBuilder.fillBlank(acera, difficulty: "easy", pool: all, rng: &rng)
        let wrong = (item?.choices ?? []).filter { $0 != "acera" }
        #expect(wrong.allSatisfy { ["esquina", "cuesta", "llave"].contains($0) })
    }

    @Test func fillBlankCapitalizesChoicesWhenTheAnswerIs() {
        var rng = SeededGenerator(seed: "caps")
        let item = ExerciseBuilder.fillBlank(hola, difficulty: "easy", pool: all, rng: &rng)
        #expect(item?.choices?.allSatisfy { $0.first?.isUppercase == true } == true)
    }

    @Test func sentenceBuilderHasEveryWordButNotInOrder() {
        var rng = SeededGenerator(seed: "build")
        let item = ExerciseBuilder.sentenceBuilder(esquina, difficulty: "easy", pool: all, rng: &rng)
        #expect(item?.prompt == esquina.exampleEn)
        #expect(item?.answer == esquina.example)
        #expect(item?.choices?.sorted() == ExerciseRules.words(esquina.example!).sorted())
        #expect(item?.choices != ExerciseRules.words(esquina.example!))
    }

    @Test func hardSentenceBuilderAddsTwoDecoys() {
        var rng = SeededGenerator(seed: "decoys")
        let item = ExerciseBuilder.sentenceBuilder(esquina, difficulty: "hard", pool: all, rng: &rng)
        #expect(item?.choices?.count == ExerciseRules.words(esquina.example!).count + 2)
    }

    @Test func easySentenceBuilderSkipsLongSentences() {
        var rng = SeededGenerator(seed: "long")
        // 8 words: too long for easy (6), fine for medium (8).
        #expect(ExerciseBuilder.sentenceBuilder(perderse, difficulty: "easy", pool: all, rng: &rng) == nil)
        #expect(ExerciseBuilder.sentenceBuilder(perderse, difficulty: "medium", pool: all, rng: &rng) != nil)
    }

    @Test func definitionMatchPairsTermAndMeaning() {
        let item = ExerciseBuilder.definitionMatch(acera)
        #expect(item.prompt == "la acera" && item.answer == "sidewalk")
    }
}

// MARK: Whole exercises

struct ExerciseBuildTests {
    @Test func usesTheLeastFamiliarWordsFirst() {
        let built = ExerciseBuilder.build(type: "definitionMatch", difficulty: "easy",
                                          words: all, pool: all, seed: "s")
        #expect(built?.wordIds == ["w_acera", "w_esquina", "w_cuesta", "w_llave"])
        #expect(built?.exercise.items.count == 4)
        #expect(built?.exercise.id == "gen_definitionMatch_easy")
    }

    @Test func itemCountGrowsWithDifficulty() {
        let counts = ["easy", "medium", "hard"].map {
            ExerciseBuilder.build(type: "definitionMatch", difficulty: $0, words: all, pool: all, seed: "s")?
                .exercise.items.count
        }
        #expect(counts == [4, 5, 6])
    }

    @Test func skipsWordsThatDontFitTheType() {
        // perderse comes first but can't be blanked, so the next words are used.
        let words = [perderse, acera, esquina, cuesta]
        let built = ExerciseBuilder.build(type: "fillBlank", difficulty: "easy", words: words, pool: all, seed: "s")
        #expect(built?.wordIds == ["w_acera", "w_esquina", "w_cuesta"])
    }

    @Test func wordIdsLineUpWithItems() {
        let built = ExerciseBuilder.build(type: "fillBlank", difficulty: "medium", words: all, pool: all, seed: "s")
        #expect(built?.wordIds.count == built?.exercise.items.count)
        #expect(built?.exercise.items.first?.answer == "acera")
    }

    @Test func sameDaySameExercise() {
        let a = ExerciseBuilder.build(type: "fillBlank", difficulty: "hard", words: all, pool: all, seed: "2026-11-22")
        let b = ExerciseBuilder.build(type: "fillBlank", difficulty: "hard", words: all, pool: all, seed: "2026-11-22")
        #expect(a?.exercise.items.map(\.choices) == b?.exercise.items.map(\.choices))
    }

    @Test func tooFewWordsGivesNoExercise() {
        #expect(ExerciseBuilder.build(type: "definitionMatch", difficulty: "easy",
                                      words: [acera], pool: all, seed: "s") == nil)
        #expect(ExerciseBuilder.build(type: "fillBlank", difficulty: "easy",
                                      words: [], pool: all, seed: "s") == nil)
    }
}

// MARK: Results for the word bank

struct ExerciseWordAnswerTests {
    @Test func oneAnswerPerItem() {
        let answers = ExerciseRules.wordAnswers(wordIds: ["a", "b"], results: [true, false])
        #expect(answers == [VocabAnswer(wordId: "a", correct: true), VocabAnswer(wordId: "b", correct: false)])
    }

    @Test func seededExercisesSendNothing() {
        #expect(ExerciseRules.wordAnswers(wordIds: [], results: [true, true]).isEmpty)
        #expect(ExerciseRules.wordAnswers(wordIds: ["a"], results: [true, false]).isEmpty)
    }
}

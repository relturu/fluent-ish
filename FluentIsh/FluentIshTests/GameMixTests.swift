//
//  GameMixTests.swift
//  FluentIshTests
//
//  Today's games mixing the daily theme with the user's own words (word
//  bank restructure, Phase 4): the personal Connections group, swapping it
//  into the puzzle, and the word bank results both games send.
//

import Foundation
import Testing
@testable import FluentIsh

// MARK: Helpers

private func word(_ id: String, _ term: String, lemma: String? = nil, category: String) -> Word {
    var w = Word(language: "es", term: term, lemma: lemma ?? term, gender: nil, partOfSpeech: "noun",
                 definitionEn: "meaning", category: category, level: "A2",
                 example: nil, exampleEn: nil, azure: nil)
    w.id = id
    return w
}

private let home = [
    word("w_llave", "la llave", lemma: "llave", category: "Home"),
    word("w_ruido", "el ruido", lemma: "ruido", category: "Home"),
    word("w_timbre", "el timbre", lemma: "timbre", category: "Home"),
    word("w_ascensor", "el ascensor", lemma: "ascensor", category: "Home"),
]
private let starters = ["hola", "gracias", "adiós", "gato", "perro", "playa"].map {
    word("w_\($0)", $0, category: "Basics")
}
/// Today's deck (Work theme).
private let deck = [
    word("w_sueldo", "el sueldo", lemma: "sueldo", category: "Work"),
    word("w_horario", "el horario", lemma: "horario", category: "Work"),
]

private let puzzle = ConnectionsPuzzle(groups: [
    ConnectionsGroup(category: "Tener ___", words: ["prisa", "éxito", "suerte", "razón"], difficulty: 4),
    ConnectionsGroup(category: "En la oficina", words: ["impresora", "escritorio", "carpeta", "bolígrafo"], difficulty: 1),
    ConnectionsGroup(category: "En tu contrato", words: ["sueldo", "horario", "jornada", "vacaciones"], difficulty: 2),
    ConnectionsGroup(category: "Verbos", words: ["contratar", "despedir", "entregar", "renunciar"], difficulty: 3),
])

// MARK: Personal group

struct PersonalGroupTests {
    @Test func fourKnownWordsFromOneCategory() {
        let picked = GameMix.personalGroup(known: home, starters: starters, deck: deck, puzzle: puzzle, seed: "d")
        #expect(picked?.group.category == "En casa")
        #expect(Set(picked?.group.words ?? []) == ["llave", "ruido", "timbre", "ascensor"])  // no articles
        #expect(Set(picked?.wordIds ?? []) == Set(home.compactMap(\.id)))
        #expect(picked?.group.difficulty == 1)
    }

    @Test func newUserGetsStarterWords() {
        let picked = GameMix.personalGroup(known: [], starters: starters, deck: deck, puzzle: puzzle, seed: "d")
        #expect(picked?.group.category == "Palabras básicas")
        #expect(picked?.group.words.count == 4)
    }

    @Test func skipsTodaysDeckWordsAndTheirCategory() {
        // Known Work words are the daily theme's category: not personal.
        let work = (1...4).map { word("w_work\($0)", "work\($0)", category: "Work") }
        let picked = GameMix.personalGroup(known: work + deck, starters: starters, deck: deck, puzzle: puzzle, seed: "d")
        #expect(picked?.group.category == "Palabras básicas")
    }

    @Test func skipsWordsThatAreAlreadyTiles() {
        // "prisa" is a tile in a group that stays, so it can't be in the personal group.
        let withTile = Array(home.prefix(3)) + [word("w_prisa", "la prisa", lemma: "prisa", category: "Home")]
        let picked = GameMix.personalGroup(known: withTile, starters: [], deck: deck, puzzle: puzzle, seed: "d")
        #expect(picked == nil)
    }

    @Test func noCategoryWithFourWordsGivesNone() {
        let picked = GameMix.personalGroup(known: Array(home.prefix(3)), starters: Array(starters.prefix(3)),
                                           deck: deck, puzzle: puzzle, seed: "d")
        #expect(picked == nil)
    }

    @Test func sameDaySameGroup() {
        let a = GameMix.personalGroup(known: [], starters: starters, deck: deck, puzzle: puzzle, seed: "2026-11-22")
        let b = GameMix.personalGroup(known: [], starters: starters, deck: deck, puzzle: puzzle, seed: "2026-11-22")
        #expect(a?.group.words == b?.group.words)
    }
}

// MARK: Mixing it in

struct MixedPuzzleTests {
    let personal = ConnectionsGroup(category: "En casa", words: ["llave", "ruido", "timbre", "ascensor"], difficulty: 1)

    @Test func replacesTheYellowGroupInPlace() {
        let mixed = GameMix.mixedPuzzle(puzzle, personal: personal)
        #expect(mixed.groups[1].category == "En casa")                     // same position as "En la oficina"
        #expect(mixed.groups.map(\.difficulty) == puzzle.groups.map(\.difficulty))
        #expect(mixed.groups[0].category == "Tener ___" && mixed.groups[3].category == "Verbos")
    }

    @Test func noPersonalGroupKeepsTheSeededPuzzle() {
        #expect(GameMix.mixedPuzzle(puzzle, personal: nil).groups.map(\.category) == puzzle.groups.map(\.category))
    }
}

// MARK: Word bank results

struct GameWordAnswerTests {
    let mixed = GameMix.mixedPuzzle(puzzle, personal: ConnectionsGroup(
        category: "En casa", words: ["llave", "ruido", "timbre", "ascensor"], difficulty: 1))

    @Test func onlyTilesWithAWordAreTracked() {
        let tiles = GameMix.tileWordIds(puzzle: mixed, words: deck + home)
        #expect(tiles["sueldo"] == "w_sueldo" && tiles["llave"] == "w_llave")
        #expect(tiles["prisa"] == nil)                                     // no word doc
        #expect(tiles.count == 6)
    }

    @Test func foundWithoutAHintIsRight() {
        let tiles = GameMix.tileWordIds(puzzle: mixed, words: deck + home)
        // Personal group (1) found; contract group (2) found but hinted.
        let answers = GameMix.connectionsAnswers(puzzle: mixed, solved: [1, 2], hinted: [2], tileWordIds: tiles)
        #expect(answers.filter(\.correct).map(\.wordId).sorted() == ["w_ascensor", "w_llave", "w_ruido", "w_timbre"])
        #expect(answers.filter { !$0.correct }.map(\.wordId).sorted() == ["w_horario", "w_sueldo"])
    }

    @Test func unsolvedGroupsAreWrong() {
        let tiles = GameMix.tileWordIds(puzzle: mixed, words: home)
        let answers = GameMix.connectionsAnswers(puzzle: mixed, solved: [], hinted: [], tileWordIds: tiles)
        #expect(answers.count == 4 && answers.allSatisfy { !$0.correct })
    }

    @Test func wordGuessWinIsRight() {
        let answers = GameMix.wordGuessAnswers(answer: "SUELDO", guesses: ["SALUDO", "SUELDO"], deck: deck)
        #expect(answers == [VocabAnswer(wordId: "w_sueldo", correct: true)])
    }

    @Test func wordGuessLossIsWrong() {
        let answers = GameMix.wordGuessAnswers(answer: "SUELDO", guesses: ["SALUDO", "SUELTO"], deck: deck)
        #expect(answers == [VocabAnswer(wordId: "w_sueldo", correct: false)])
    }

    @Test func wordGuessWithoutADeckWordSendsNothing() {
        #expect(GameMix.wordGuessAnswers(answer: "CHARLA", guesses: ["CHARLA"], deck: deck).isEmpty)
    }
}

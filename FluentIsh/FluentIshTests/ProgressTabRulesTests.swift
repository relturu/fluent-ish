//
//  ProgressTabRulesTests.swift
//  FluentIshTests
//
//  The Progress tab's pure rules: Quest Path shading, day summaries, Player
//  Stats labels, and the Word Log search, chips and order.
//

import Foundation
import Testing
@testable import FluentIsh

// MARK: Helpers

private let today = "2026-11-09"

private func log(_ date: String = today, vocab: Bool = false, games: [String: GameStatus] = [:],
                 exercises: [String] = [], minutes: Int = 0) -> DailyLog {
    var log = ProgressRules.emptyLog(date: date, language: "es")
    log.vocabCompleted = vocab
    log.games = games.mapValues {
        GameResult(status: $0, score: nil, mistakes: nil, solvedGroups: nil, guesses: nil,
                   filledCells: nil, hintsUsed: nil)
    }
    log.exercisesCompleted = exercises
    log.minutesSpent = minutes
    return log
}

private func entry(_ id: String, term: String, lemma: String, definition: String, category: String,
                   status: WordStatus = .learning, reviewed: Date? = nil) -> WordLogEntry {
    let word = Word(language: "es", term: term, lemma: lemma, gender: nil, partOfSpeech: "noun",
                    definitionEn: definition, category: category, level: "B1",
                    example: nil, exampleEn: nil, azure: nil)
    return WordLogEntry(id: id, word: word, status: status, lastReviewed: reviewed)
}

private var sobremesa: WordLogEntry { entry("w_sobremesa", term: "la sobremesa", lemma: "sobremesa",
                              definition: "relaxed conversation at the table after a meal",
                              category: "Culture & Idioms") }
private var ademas: WordLogEntry { entry("w_ademas", term: "además", lemma: "además",
                           definition: "furthermore, besides", category: "Connector") }
private var cortado: WordLogEntry { entry("w_cortado", term: "el cortado", lemma: "cortado",
                            definition: "espresso cut with warm milk", category: "Café & Dining") }

// MARK: Quest Path

struct QuestPathTests {
    @Test func emptyDayIsLevelZero() {
        #expect(ProgressTabRules.activityLevel(nil) == 0)
        #expect(ProgressTabRules.activityLevel(log()) == 0)
    }

    @Test func minutesWithoutFinishingIsLight() {
        // A game saved halfway: time was spent, nothing finished.
        #expect(ProgressTabRules.activityLevel(log(games: ["wordGuess": .inProgress], minutes: 3)) == 1)
    }

    @Test func eachFinishedActivityDarkensTheSquareUpToThree() {
        #expect(ProgressTabRules.activityLevel(log(vocab: true)) == 1)
        #expect(ProgressTabRules.activityLevel(log(vocab: true, games: ["connections": .completed])) == 2)
        #expect(ProgressTabRules.activityLevel(log(vocab: true, games: ["connections": .completed,
                                                                       "wordGuess": .completed],
                                                   exercises: ["e1", "e2"])) == 3)
    }

    @Test func inProgressGamesDontCountAsFinished() {
        #expect(ProgressTabRules.activityLevel(log(vocab: true, games: ["connections": .inProgress])) == 1)
    }

    @Test func pathIs28DaysEndingToday() {
        let cells = ProgressTabRules.questCells(today: today, logs: [])
        #expect(cells.count == 28)
        #expect(cells.first?.day == 1)
        #expect(cells.first?.date == "2026-10-13")
        #expect(cells.last?.date == today)
        #expect(cells.last?.isToday == true)
        #expect(cells.filter(\.isToday).count == 1)
    }

    @Test func logsLandOnTheirOwnDay() {
        let logs = [log(today, vocab: true), log("2026-11-01", vocab: true, games: ["connections": .completed])]
        let cells = ProgressTabRules.questCells(today: today, logs: logs)
        #expect(cells.last?.level == 1)
        #expect(cells.first { $0.date == "2026-11-01" }?.level == 2)
        #expect(cells.first { $0.date == "2026-11-02" }?.level == 0)
    }

    @Test func logsOlderThanThePathAreIgnored() {
        let cells = ProgressTabRules.questCells(today: today, logs: [log("2026-10-01", vocab: true)])
        #expect(cells.allSatisfy { $0.level == 0 })
    }

    @Test func summaryListsWhatWasDone() {
        #expect(ProgressTabRules.activitySummary(nil) == "No activity")
        #expect(ProgressTabRules.activitySummary(log()) == "No activity")
        #expect(ProgressTabRules.activitySummary(log(vocab: true, games: ["connections": .completed],
                                                     exercises: ["e1"], minutes: 12))
                == "Vocab lesson · 1 game · 1 exercise · 12 min")
        #expect(ProgressTabRules.activitySummary(log(games: ["connections": .completed, "wordGuess": .completed]))
                == "2 games")
    }
}

// MARK: Player Stats

struct PlayerStatsTests {
    @Test func xpLabelShowsTotalAndNextCEFRLevel() {
        #expect(ProgressTabRules.xpLabel(ProgressRules.level(forXP: 445)) == "445 / 800 XP → B1")
        #expect(ProgressTabRules.xpLabel(ProgressRules.level(forXP: 0)) == "0 / 300 XP → A2")
    }

    @Test func xpLabelAtTopLevel() {
        #expect(ProgressTabRules.xpLabel(ProgressRules.level(forXP: 4000)).hasSuffix("XP · Top level"))
    }

    @Test func recallIsADashBeforeAnyReviews() {
        #expect(ProgressTabRules.recallLabel(reviewsCorrect: 0, reviewsTotal: 0) == "—")
    }

    @Test func recallIsARoundedPercent() {
        #expect(ProgressTabRules.recallLabel(reviewsCorrect: 89, reviewsTotal: 100) == "89%")
        #expect(ProgressTabRules.recallLabel(reviewsCorrect: 2, reviewsTotal: 3) == "67%")
        #expect(ProgressTabRules.recallLabel(reviewsCorrect: 5, reviewsTotal: 5) == "100%")
    }
}

// MARK: Word Log

struct WordLogTests {
    let all = [sobremesa, ademas, cortado]

    @Test func chipsOnlyShowCategoriesTheUserHas() {
        #expect(ProgressTabRules.categories(in: all) == ["All", "Connector", "Café & Dining", "Culture & Idioms"])
        #expect(ProgressTabRules.categories(in: []) == ["All"])
    }

    @Test func unknownCategoriesGoLast() {
        let odd = entry("w_x", term: "x", lemma: "x", definition: "x", category: "Travel")
        #expect(ProgressTabRules.categories(in: [odd, ademas]) == ["All", "Connector", "Travel"])
    }

    @Test func categoryChipFilters() {
        let shown = ProgressTabRules.filter(all, category: "Connector", query: "")
        #expect(shown.map(\.id) == ["w_ademas"])
        #expect(ProgressTabRules.filter(all, category: "All", query: "").count == 3)
    }

    @Test func searchIgnoresCaseAndAccents() {
        #expect(ProgressTabRules.filter(all, category: "All", query: "ADEMAS").map(\.id) == ["w_ademas"])
        #expect(ProgressTabRules.filter(all, category: "All", query: "  sobremesa ").map(\.id) == ["w_sobremesa"])
    }

    @Test func searchLooksAtTheEnglishDefinition() {
        #expect(ProgressTabRules.filter(all, category: "All", query: "espresso").map(\.id) == ["w_cortado"])
    }

    @Test func searchAndChipCombine() {
        #expect(ProgressTabRules.filter(all, category: "Connector", query: "espresso").isEmpty)
    }

    @Test func newestReviewsFirstThenAlphabetical() {
        let older = entry("w_a", term: "a", lemma: "a", definition: "", category: "Connector",
                          reviewed: Date(timeIntervalSince1970: 1_000))
        let newer = entry("w_b", term: "b", lemma: "b", definition: "", category: "Connector",
                          reviewed: Date(timeIntervalSince1970: 2_000))
        let never1 = entry("w_z", term: "zz", lemma: "zz", definition: "", category: "Connector")
        let never2 = entry("w_c", term: "cc", lemma: "cc", definition: "", category: "Connector")
        let order = ProgressTabRules.sorted([never1, older, never2, newer]).map(\.id)
        #expect(order == ["w_b", "w_a", "w_c", "w_z"])
    }
}

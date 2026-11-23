//
//  ProgressRulesTests.swift
//  FluentIshTests
//
//  The rules in docs/plan.md "Defaults to implement", checked one by one.
//

import Testing
import Foundation
@testable import FluentIsh

struct DayKeyTests {
    /// Fixed calendar so tests don't depend on the Mac's time zone.
    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    @Test func formatsAsYearMonthDay() {
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 23, minute: 59))!
        #expect(ProgressRules.dayKey(for: date, calendar: calendar) == "2026-11-04")
    }

    @Test func dayBeforeCrossesMonthAndYear() {
        #expect(ProgressRules.dayKey(before: "2026-11-01", calendar: calendar) == "2026-10-31")
        #expect(ProgressRules.dayKey(before: "2027-01-01", calendar: calendar) == "2026-12-31")
        #expect(ProgressRules.dayKey(before: "2028-03-01", calendar: calendar) == "2028-02-29")   // leap year
    }

    @Test func dayBeforeRejectsGarbage() {
        #expect(ProgressRules.dayKey(before: "not-a-date") == nil)
    }
}

struct LevelTests {
    @Test(arguments: [
        (0, "A1"), (299, "A1"), (300, "A2"), (799, "A2"), (800, "B1"),
        (1245, "B1"), (1500, "B2"), (2500, "C1"), (4000, "C2"), (99_999, "C2"),
    ])
    func cefrFloors(xp: Int, expected: String) {
        #expect(ProgressRules.level(forXP: xp).name == expected)
    }

    @Test func sofiaIsB1HeadingToB2() {
        // Seeded u_sofia: 1245 XP → "1,245 / 1,500 XP → B2".
        let level = ProgressRules.level(forXP: 1245)
        #expect(level.nextName == "B2")
        #expect(level.nextFloor == 1500)
        #expect(level.xpToNext == 255)
        #expect(abs(level.fraction - (445.0 / 700.0)) < 0.0001)   // 1245−800 of 1500−800
    }

    @Test func topLevelIsFull() {
        let level = ProgressRules.level(forXP: 5000)
        #expect(level.nextName == nil)
        #expect(level.fraction == 1)
        #expect(level.xpToNext == 0)
    }

    @Test func negativeXPIsTreatedAsZero() {
        #expect(ProgressRules.level(forXP: -40).name == "A1")
    }
}

struct StreakDisplayTests {
    @Test func countedTodayShowsStreak() {
        #expect(ProgressRules.displayedStreak(current: 14, lastActiveDate: "2026-11-04", today: "2026-11-04") == 14)
        #expect(ProgressRules.countedToday(lastActiveDate: "2026-11-04", today: "2026-11-04"))
    }

    @Test func activeYesterdayKeepsStreakButNotCounted() {
        // Still alive: they have until midnight to play today.
        #expect(ProgressRules.displayedStreak(current: 14, lastActiveDate: "2026-11-03", today: "2026-11-04") == 14)
        #expect(!ProgressRules.countedToday(lastActiveDate: "2026-11-03", today: "2026-11-04"))
    }

    @Test func missedADayShowsZero() {
        // The demo user's copied data: last active Oct 24, today Nov 4.
        #expect(ProgressRules.displayedStreak(current: 14, lastActiveDate: "2026-10-24", today: "2026-11-04") == 0)
    }
}

// MARK: - Step 5

/// Fixed New York calendar, shared by the step 5 tests.
private let ny: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/New_York")!
    return c
}()

struct WeekIdTests {
    @Test(arguments: [
        ("2026-10-24", "2026-W43"),   // seeded leaderboard week (a Saturday)
        ("2026-10-25", "2026-W43"),   // Sunday is still the same ISO week
        ("2026-10-26", "2026-W44"),   // Monday starts a new one
        ("2026-11-04", "2026-W45"),
        ("2027-01-01", "2026-W53"),   // belongs to the previous ISO year
        ("2027-01-04", "2027-W01"),
    ])
    func isoWeeks(day: String, expected: String) {
        #expect(ProgressRules.weekId(forKey: day, calendar: ny) == expected)
    }
}

struct StreakUpdateTests {
    @Test func yesterdayAddsOne() {
        #expect(ProgressRules.nextStreak(current: 14, lastActiveDate: "2026-11-03", today: "2026-11-04") == 15)
    }
    @Test func sameDayNoChange() {
        #expect(ProgressRules.nextStreak(current: 14, lastActiveDate: "2026-11-04", today: "2026-11-04") == 14)
    }
    @Test func missedDayResetsToOne() {
        #expect(ProgressRules.nextStreak(current: 14, lastActiveDate: "2026-10-24", today: "2026-11-04") == 1)
    }
    @Test func newUserStartsAtOne() {
        #expect(ProgressRules.nextStreak(current: 0, lastActiveDate: "", today: "2026-11-04") == 1)
    }
}

struct ScoreTests {
    @Test(arguments: [(0, 1.0), (1, 0.75), (3, 0.25), (4, 0.0), (6, 0.0)])
    func connections(mistakes: Int, expected: Double) {
        #expect(ProgressRules.connectionsScore(mistakes: mistakes) == expected)
    }

    @Test func wordGuess() {
        #expect(ProgressRules.wordGuessScore(guessesUsed: 1, solved: true) == 1)
        #expect(abs(ProgressRules.wordGuessScore(guessesUsed: 2, solved: true) - 5.0 / 6) < 1e-9)
        #expect(abs(ProgressRules.wordGuessScore(guessesUsed: 6, solved: true) - 1.0 / 6) < 1e-9)
        #expect(ProgressRules.wordGuessScore(guessesUsed: 6, solved: false) == 0)
    }

    @Test func crossword() {
        #expect(ProgressRules.crosswordScore(hintsUsed: 0) == 1)
        #expect(abs(ProgressRules.crosswordScore(hintsUsed: 3) - 0.7) < 1e-9)
        #expect(ProgressRules.crosswordScore(hintsUsed: 12) == 0)
    }

    @Test func vocabScoreUsesOneHundredPointScale() {
        #expect(ProgressRules.vocabScorePoints(score: 1) == 100)
        #expect(ProgressRules.vocabScorePoints(score: 0.75) == 75)
        #expect(ProgressRules.vocabScorePoints(score: -1) == 0)
        #expect(ProgressRules.vocabScorePoints(score: 2) == 100)
    }

    @Test func gameXPMatchesSeededLog() {
        // Sofía, Oct 22: vocab 30 + connections 0.75 + word guess 0.83 + crossword 1.0 = 108 XP.
        let total = ProgressRules.vocabLessonXP
            + ProgressRules.gameXP(score: 0.75) + ProgressRules.gameXP(score: 0.83) + ProgressRules.gameXP(score: 1)
        #expect(total == 108)
    }

    @Test func hintsCostXPButNeverBelowZero() {
        #expect(ProgressRules.gameXP(score: 0.8, hintsUsed: 2) == 24 - 10)
        #expect(ProgressRules.gameXP(score: 0.1, hintsUsed: 9) == 0)
    }
}

struct WordStatusTests {
    let today = "2026-11-04"

    func word(_ status: WordStatus, correct: Int) -> WordProgress {
        WordProgress(wordId: "w_x", language: "es", status: status, timesSeen: correct + 1,
                     timesCorrect: correct, lastReviewed: nil, nextReview: today)
    }

    @Test func firstSightingBecomesLearningForOneDay() {
        let seen = ProgressRules.reviewed(nil, wordId: "w_x", language: "es", correct: false, today: today)
        #expect(seen.status == .learning)
        #expect(seen.timesSeen == 1)
        #expect(seen.nextReview == "2026-11-05")
    }

    @Test func thirdCorrectIsFamiliarForThreeDays() {
        let next = ProgressRules.reviewed(word(.learning, correct: 2), wordId: "w_x", language: "es", correct: true, today: today)
        #expect(next.status == .familiar)
        #expect(next.nextReview == "2026-11-07")
    }

    @Test func sixthCorrectIsMasteredForAWeek() {
        let next = ProgressRules.reviewed(word(.familiar, correct: 5), wordId: "w_x", language: "es", correct: true, today: today)
        #expect(next.status == .mastered)
        #expect(next.nextReview == "2026-11-11")
    }

    @Test func wrongAnswerDropsOneStatus() {
        let next = ProgressRules.reviewed(word(.mastered, correct: 7), wordId: "w_x", language: "es", correct: false, today: today)
        #expect(next.status == .familiar)
        #expect(next.timesCorrect == 7)
        #expect(next.timesSeen == 9)
    }

    @Test func correctAnswerNeverDemotes() {
        // Seeded data can be "familiar" with only 2 correct answers.
        let next = ProgressRules.reviewed(word(.familiar, correct: 1), wordId: "w_x", language: "es", correct: true, today: today)
        #expect(next.status == .familiar)
    }
}

struct DailyDeckTests {
    let themed = (1...10).map { "w\($0)" }

    @Test func deckIsExactlyTheDaysTenWordsInOrder() {
        let deck = ProgressRules.dailyDeck(newWordIds: themed, alreadySeen: [])
        #expect(deck.wordIds == themed)
        #expect(deck.reviewIds.isEmpty)
    }

    @Test func otherKnownWordsAreNotMixedIn() {
        // Words from other days in the user's bank stay out of today's deck.
        let deck = ProgressRules.dailyDeck(newWordIds: themed, alreadySeen: ["r1", "r2", "r3"])
        #expect(deck.wordIds == themed)
        #expect(deck.reviewIds.isEmpty)
    }

    @Test func wordsSeenLastWeekShowAsReview() {
        // The 7 seeded days loop weekly, so a deck can come back already known.
        let deck = ProgressRules.dailyDeck(newWordIds: themed, alreadySeen: ["w2", "w5", "other"])
        #expect(deck.wordIds == themed)
        #expect(deck.reviewIds == ["w2", "w5"])
        #expect(deck.isReview("w2") && !deck.isReview("w1"))
    }

    @Test func duplicateIdsAppearOnce() {
        let deck = ProgressRules.dailyDeck(newWordIds: ["a", "b", "a"], alreadySeen: [])
        #expect(deck.wordIds == ["a", "b"])
    }
}

struct WordBankTests {
    let today = "2026-11-22"

    func word(_ id: String, _ status: WordStatus = .learning, seen: Int = 2, correct: Int = 1,
              next: String = "2026-11-25", last: Date? = Date(timeIntervalSince1970: 1_000)) -> WordProgress {
        WordProgress(wordId: id, language: "es", status: status, timesSeen: seen, timesCorrect: correct,
                     lastReviewed: last, nextReview: next)
    }

    // MARK: Merging answers

    @Test func oneAnswerPerWordInFirstOrder() {
        let merged = ProgressRules.mergedAnswers([
            VocabAnswer(wordId: "a", correct: true), VocabAnswer(wordId: "b", correct: true),
            VocabAnswer(wordId: "a", correct: true),
        ])
        #expect(merged == [VocabAnswer(wordId: "a", correct: true), VocabAnswer(wordId: "b", correct: true)])
    }

    @Test func anyWrongAnswerMakesTheWordWrong() {
        let merged = ProgressRules.mergedAnswers([
            VocabAnswer(wordId: "a", correct: false), VocabAnswer(wordId: "a", correct: true),
        ])
        #expect(merged == [VocabAnswer(wordId: "a", correct: false)])
    }

    @Test func aGameAnswerAddsAWordToTheBank() {
        // A starter word the user has never seen gets its first wordProgress.
        let added = ProgressRules.reviewed(nil, wordId: "w_hola", language: "es", correct: true, today: today)
        #expect(added.timesSeen == 1 && added.timesCorrect == 1 && added.status == .learning)
        #expect(added.nextReview == "2026-11-23")
    }

    // MARK: Least familiar first

    @Test func dueWordsComeFirst() {
        let due = word("due", .mastered, seen: 9, correct: 9, next: today)
        let notDue = word("notDue", .learning, seen: 1, correct: 0)
        #expect(ProgressRules.leastFamiliarFirst([notDue, due], today: today).map(\.wordId) == ["due", "notDue"])
    }

    @Test func lowerStatusComesFirst() {
        let ranked = ProgressRules.leastFamiliarFirst(
            [word("m", .mastered, seen: 6, correct: 6), word("l", .learning), word("f", .familiar, seen: 4, correct: 3)],
            today: today)
        #expect(ranked.map(\.wordId) == ["l", "f", "m"])
    }

    @Test func lowerAccuracyComesFirst() {
        let ranked = ProgressRules.leastFamiliarFirst(
            [word("good", seen: 4, correct: 2), word("bad", seen: 4, correct: 0)], today: today)
        #expect(ranked.map(\.wordId) == ["bad", "good"])
    }

    @Test func seenLessComesFirstAtTheSameAccuracy() {
        let ranked = ProgressRules.leastFamiliarFirst(
            [word("often", seen: 4, correct: 2), word("rarely", seen: 2, correct: 1)], today: today)
        #expect(ranked.map(\.wordId) == ["rarely", "often"])
    }

    @Test func longestSinceReviewedComesFirst() {
        let ranked = ProgressRules.leastFamiliarFirst(
            [word("recent", last: Date(timeIntervalSince1970: 5_000)),
             word("old", last: Date(timeIntervalSince1970: 10)),
             word("never", last: nil)], today: today)
        #expect(ranked.map(\.wordId) == ["never", "old", "recent"])
    }

    @Test func sameOrderWhateverTheInputOrder() {
        let words = [word("b"), word("a"), word("c")]
        let one = ProgressRules.leastFamiliarFirst(words, today: today).map(\.wordId)
        let two = ProgressRules.leastFamiliarFirst(words.reversed(), today: today).map(\.wordId)
        #expect(one == ["a", "b", "c"] && one == two)
    }
}

struct ContentDayTests {
    let seeded = ["2026-10-28", "2026-10-24", "2026-10-26", "2026-10-25", "2026-10-27"]   // any order

    @Test func usesTodayWhenSeeded() {
        #expect(ProgressRules.contentDay(today: "2026-10-26", available: seeded, calendar: ny) == "2026-10-26")
    }

    @Test func rotatesThroughEverySeededDay() {
        // Five days in a row after the seeded range get five different days.
        let days = ["2026-11-04", "2026-11-05", "2026-11-06", "2026-11-07", "2026-11-08"]
            .compactMap { ProgressRules.contentDay(today: $0, available: seeded, calendar: ny) }
        #expect(Set(days) == Set(seeded))
    }

    @Test func loopsWeeklyBySameWeekday() {
        // Oct 24, 2026 is a Saturday, so the seed covers Sat–Wed.
        #expect(ProgressRules.contentDay(today: "2026-11-23", available: seeded, calendar: ny) == "2026-10-26")  // Mon
        #expect(ProgressRules.contentDay(today: "2026-11-22", available: seeded, calendar: ny) == "2026-10-25")  // Sun
        #expect(ProgressRules.contentDay(today: "2026-11-30", available: seeded, calendar: ny) == "2026-10-26")  // next Mon
    }

    @Test func fullWeekAlwaysMatchesWeekday() {
        let week = seeded + ["2026-10-29", "2026-10-30"]                                 // + Thu, Fri
        #expect(ProgressRules.contentDay(today: "2026-11-26", available: week, calendar: ny) == "2026-10-29")    // Thu
        #expect(ProgressRules.contentDay(today: "2026-11-27", available: week, calendar: ny) == "2026-10-30")    // Fri
    }

    @Test func missingWeekdayStillGetsContent() {
        // Thursday has no seeded day yet: fall back to a seeded day, not nil.
        let day = ProgressRules.contentDay(today: "2026-11-26", available: seeded, calendar: ny)
        #expect(day.map(seeded.contains) == true)
    }

    @Test func sameDaySameContent() {
        let a = ProgressRules.contentDay(today: "2026-11-04", available: seeded, calendar: ny)
        let b = ProgressRules.contentDay(today: "2026-11-04", available: seeded.reversed(), calendar: ny)
        #expect(a == b)
    }

    @Test func nothingSeeded() {
        #expect(ProgressRules.contentDay(today: "2026-11-04", available: []) == nil)
    }
}

struct ActivityTests {
    let today = "2026-11-04"

    var progress: LanguageProgress {
        LanguageProgress(language: "es", level: "B1", xp: 1490, weeklyXP: 300, weekId: "2026-W43",
                         currentStreak: 14, longestStreak: 14, lastActiveDate: "2026-11-03",
                         wordsLearned: 20, reviewsCorrect: 8, reviewsTotal: 9,
                         displayName: "Sofía", avatarInitials: "SR")
    }

    var emptyLog: DailyLog { ProgressRules.emptyLog(date: today, language: "es") }

    func game(_ status: GameStatus, score: Double? = nil, hints: Int? = nil) -> GameResult {
        GameResult(status: status, score: score, mistakes: nil, solvedGroups: nil,
                   guesses: nil, filledCells: nil, hintsUsed: hints)
    }

    @Test func earningXPUpdatesEverything() {
        let p = ProgressRules.applying(xp: 20, to: progress, today: today, weekId: "2026-W45")
        #expect(p.xp == 1510)
        #expect(p.level == "B2")                 // crossed 1,500 → level-up
        #expect(p.weeklyXP == 20)                // new week: reset, then add
        #expect(p.weekId == "2026-W45")
        #expect(p.currentStreak == 15)
        #expect(p.longestStreak == 15)
        #expect(p.lastActiveDate == today)
    }

    @Test func sameWeekAddsToWeeklyXP() {
        var start = progress
        start.weekId = "2026-W45"
        #expect(ProgressRules.applying(xp: 10, to: start, today: today, weekId: "2026-W45").weeklyXP == 310)
    }

    @Test func zeroXPIsNotAnActiveDay() {
        let p = ProgressRules.applying(xp: 0, to: progress, today: today, weekId: "2026-W45")
        #expect(p.lastActiveDate == "2026-11-03")
        #expect(p.currentStreak == 14)
    }

    @Test func replayEarnsNoXP() {
        let once = ProgressRules.applying(.exercise(id: "e1"), xp: 10, minutes: 2, to: emptyLog)
        #expect(ProgressRules.xp(for: .exercise(id: "e1"), log: once) == 0)
        #expect(ProgressRules.xp(for: .exercise(id: "e2"), log: once) == 10)

        #expect(ProgressRules.xp(for: .vocab(score: 1), log: emptyLog) == 30)
        let vocab = ProgressRules.applying(.vocab(score: 1), xp: 30, minutes: 3, to: emptyLog)
        #expect(vocab.vocabCompleted)
        #expect(vocab.vocabScore == 1)
        #expect(vocab.xpEarned == 30)
        #expect(ProgressRules.xp(for: .vocab(score: 1), log: vocab) == 0)
    }

    @Test func vocabCompletionActivatesStreakAndCanLevelUp() {
        var starting = progress
        starting.xp = 1470
        starting.weekId = "2026-W45"
        let xp = ProgressRules.xp(for: .vocab(score: 1), log: emptyLog)
        let updated = ProgressRules.applying(xp: xp, to: starting, today: today, weekId: "2026-W45")

        #expect(updated.xp == 1500)
        #expect(updated.level == "B2")
        #expect(updated.currentStreak == starting.currentStreak + 1)
        #expect(updated.lastActiveDate == today)
    }

    @Test func gamesEarnXPOnlyWhenCompleted() {
        let halfway = game(.inProgress)
        #expect(ProgressRules.xp(for: .game(key: "connections", result: halfway), log: emptyLog) == 0)
        let saved = ProgressRules.applying(.game(key: "connections", result: halfway), xp: 0, minutes: 0, to: emptyLog)
        #expect(saved.games["connections"]?.status == .inProgress)

        let done = game(.completed, score: 0.75)
        #expect(ProgressRules.xp(for: .game(key: "connections", result: done), log: saved) == 23)
    }

    @Test func finishedGameIsNotOverwritten() {
        let done = ProgressRules.applying(.game(key: "crossword", result: game(.completed, score: 1)),
                                          xp: 30, minutes: 4, to: emptyLog)
        let replay = ProgressRules.applying(.game(key: "crossword", result: game(.completed, score: 0.2)),
                                            xp: 0, minutes: 2, to: done)
        #expect(replay.games["crossword"]?.score == 1)
        #expect(replay.xpEarned == 30)
        #expect(replay.minutesSpent == 6)        // time still counts
    }
}

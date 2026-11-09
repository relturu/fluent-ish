//
//  ProgressRules.swift
//  FluentIsh
//
//  Pure game rules from docs/plan.md "Defaults to implement". No Firebase, no
//  UI, so every rule can be unit tested (FluentIshTests/ProgressRulesTests).
//  Step 4 added dates, levels and streak display; step 5 adds week IDs,
//  streak updates, scoring, XP, word status, the 70/30 lesson mix, the
//  content-date fallback, and what one finished activity does to
//  `progress/{lang}` and `dailyLog/{lang_date}`.
//
//  `nonisolated`: FirestoreService runs these inside a Firestore transaction,
//  which calls back on a background thread, not the main actor.
//

import Foundation

nonisolated enum ProgressRules {

    // MARK: Days

    /// "Today" is the device's local calendar date, as `yyyy-MM-dd`.
    /// The same format is used in document IDs (`es_2026-11-04`) and in
    /// `lastActiveDate`, so string comparison works for ordering.
    static func dayKey(for date: Date = Date(), calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    /// Parses a `yyyy-MM-dd` key back to midnight local time.
    static func date(fromKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    /// The day before `key` (handles month and year boundaries).
    static func dayKey(before key: String, calendar: Calendar = .current) -> String? {
        guard let date = date(fromKey: key, calendar: calendar),
              let previous = calendar.date(byAdding: .day, value: -1, to: date) else { return nil }
        return dayKey(for: previous, calendar: calendar)
    }

    // MARK: Levels (CEFR)

    /// XP floors from plan.md: A1 0 · A2 300 · B1 800 · B2 1500 · C1 2500 · C2 4000.
    static let levels: [(name: String, floor: Int)] = [
        ("A1", 0), ("A2", 300), ("B1", 800), ("B2", 1500), ("C1", 2500), ("C2", 4000),
    ]

    struct LevelInfo: Equatable {
        let name: String          // "B1"
        let floor: Int            // XP where this level starts
        let nextName: String?     // "B2", nil at C2
        let nextFloor: Int?       // 1500
        let xp: Int

        /// 0…1 progress from this level's floor to the next one (1 at C2).
        var fraction: Double {
            guard let nextFloor else { return 1 }
            return Double(xp - floor) / Double(nextFloor - floor)
        }

        /// XP still needed for the next level (0 at C2).
        var xpToNext: Int { max(0, (nextFloor ?? xp) - xp) }
    }

    static func level(forXP xp: Int) -> LevelInfo {
        let xp = max(0, xp)
        let index = levels.lastIndex { xp >= $0.floor } ?? 0
        let next = index + 1 < levels.count ? levels[index + 1] : nil
        return LevelInfo(name: levels[index].name, floor: levels[index].floor,
                         nextName: next?.name, nextFloor: next?.floor, xp: xp)
    }

    // MARK: Streak (display)

    /// The streak to show right now. The stored `currentStreak` only changes
    /// when the user earns XP, so if they skipped a whole day it's stale: the
    /// streak is broken and the app shows 0 until they play again.
    static func displayedStreak(current: Int, lastActiveDate: String, today: String) -> Int {
        if lastActiveDate == today || lastActiveDate == dayKey(before: today) {
            return current
        }
        return 0
    }

    /// True once the user has earned XP today (green dot on the flame).
    static func countedToday(lastActiveDate: String, today: String) -> Bool {
        lastActiveDate == today
    }

    // MARK: Week ID

    /// ISO week, Monday start: "2026-W45". Uses the ISO *week-year*, so
    /// Jan 1 2027 (a Friday) is "2026-W53", not "2027-W53".
    static func weekId(for date: Date = Date(), timeZone: TimeZone = .current) -> String {
        var iso = Calendar(identifier: .iso8601)
        iso.timeZone = timeZone
        let c = iso.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear!, c.weekOfYear!)
    }

    /// Week ID for a `yyyy-MM-dd` key (dates are local midnight).
    static func weekId(forKey key: String, calendar: Calendar = .current) -> String? {
        date(fromKey: key, calendar: calendar).map { weekId(for: $0, timeZone: calendar.timeZone) }
    }

    // MARK: Streak (update)

    /// The stored streak after earning XP today. plan.md: last active
    /// yesterday → +1; already today → no change; anything else → 1.
    static func nextStreak(current: Int, lastActiveDate: String, today: String) -> Int {
        if lastActiveDate == today { return max(current, 1) }
        if lastActiveDate == dayKey(before: today) { return current + 1 }
        return 1
    }

    // MARK: Scores (0…1)

    /// Connections: every mistake costs a quarter; 4 mistakes ends the game at 0.
    static func connectionsScore(mistakes: Int) -> Double {
        max(0, 1 - Double(mistakes) / 4)
    }

    /// Word Guess: solved on guess 1 → 1.0, guess 6 → 1/6. Not solved → 0.
    static func wordGuessScore(guessesUsed: Int, solved: Bool) -> Double {
        guard solved, (1...6).contains(guessesUsed) else { return 0 }
        return Double(7 - guessesUsed) / 6
    }

    /// Crossword: each hint costs 10%.
    static func crosswordScore(hintsUsed: Int) -> Double {
        max(0, 1 - 0.1 * Double(hintsUsed))
    }

    /// The vocab recap's 100-point scale for a score stored from 0 to 1.
    static func vocabScorePoints(score: Double) -> Int {
        Int((min(1, max(0, score)) * 100).rounded())
    }

    // MARK: XP

    static let vocabLessonXP = 30
    static let exerciseXP = 10
    static let gameMaxXP = 30
    static let hintPenaltyXP = 5

    /// A game is worth 30 × score, minus 5 per hint, never below 0. Rounded
    /// half-up, which matches the seeded logs (0.75 → 23 XP, 0.83 → 25 XP).
    static func gameXP(score: Double, hintsUsed: Int = 0) -> Int {
        max(0, Int((Double(gameMaxXP) * score).rounded()) - hintPenaltyXP * hintsUsed)
    }

    // MARK: Word status (spaced repetition)

    /// Days until a word comes back for review.
    static func reviewInterval(for status: WordStatus) -> Int {
        switch status {
        case .new, .learning: 1
        case .familiar: 3
        case .mastered: 7
        }
    }

    /// Status earned by a number of correct answers: 3 → familiar, 6 → mastered.
    static func status(forCorrect timesCorrect: Int) -> WordStatus {
        switch timesCorrect {
        case 6...: .mastered
        case 3...: .familiar
        default: .learning
        }
    }

    /// One step down after a wrong answer (never below learning once seen).
    static func demoted(_ status: WordStatus) -> WordStatus {
        switch status {
        case .mastered: .familiar
        case .familiar, .learning, .new: .learning
        }
    }

    /// "Words learned" counts familiar + mastered.
    static func isLearned(_ status: WordStatus) -> Bool {
        status == .familiar || status == .mastered
    }

    /// A word's progress after one answer in a vocab lesson. Pass `nil` for
    /// a word the user has never seen.
    static func reviewed(_ word: WordProgress?, wordId: String, language: String,
                         correct: Bool, today: String, now: Date = Date()) -> WordProgress {
        var next = word ?? WordProgress(wordId: wordId, language: language, status: .new,
                                        timesSeen: 0, timesCorrect: 0, lastReviewed: nil, nextReview: today)
        next.timesSeen += 1
        if correct {
            next.timesCorrect += 1
            // Never demote on a correct answer, even if the count is behind
            // (e.g. seeded data, or a word that was knocked down earlier).
            next.status = higher(status(forCorrect: next.timesCorrect), higher(next.status, .learning))
        } else {
            next.status = demoted(next.status)
        }
        next.lastReviewed = now
        next.nextReview = dayKey(adding: reviewInterval(for: next.status), to: today) ?? today
        return next
    }

    private static func rank(_ s: WordStatus) -> Int {
        switch s { case .new: 0; case .learning: 1; case .familiar: 2; case .mastered: 3 }
    }
    private static func higher(_ a: WordStatus, _ b: WordStatus) -> WordStatus { rank(a) >= rank(b) ? a : b }

    static func dayKey(adding days: Int, to key: String, calendar: Calendar = .current) -> String? {
        guard let date = date(fromKey: key, calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: days, to: date) else { return nil }
        return dayKey(for: moved, calendar: calendar)
    }

    // MARK: The 70/30 lesson mix

    /// Word IDs for today's deck: up to `wordCount × reviewRatio` due review
    /// words (7 of 10), then unseen words to fill the rest. Remaining slots
    /// use previously seen candidates if the daily lesson has too few unseen
    /// words, keeping the lesson at its configured size.
    static func lessonWordIds(dueReviewIds: [String], newWordIds: [String], alreadySeen: Set<String>,
                              wordCount: Int = 10, reviewRatio: Double = 0.7) -> [String] {
        let fresh = newWordIds.filter { !alreadySeen.contains($0) }
        let due = dueReviewIds.filter { !fresh.contains($0) }
        let reviewSlots = Int((Double(wordCount) * reviewRatio).rounded())
        var ids = Array(due.prefix(reviewSlots))
        ids += fresh.prefix(max(0, wordCount - ids.count))
        ids += due.dropFirst(reviewSlots).prefix(max(0, wordCount - ids.count))
        if ids.count < wordCount {
            let knownCandidates = newWordIds.filter { alreadySeen.contains($0) && !ids.contains($0) }
            ids += knownCandidates.prefix(wordCount - ids.count)
        }
        return ids
    }

    // MARK: Content date fallback

    /// Which seeded day's content to show. Today's own content if it exists;
    /// otherwise rotate through the seeded days by day number, so everyone
    /// gets the same puzzle on the same day and it changes at midnight.
    static func contentDay(today: String, available: [String], calendar: Calendar = .current) -> String? {
        let days = available.sorted()
        if days.contains(today) { return today }
        guard !days.isEmpty, let date = date(fromKey: today, calendar: calendar) else { return days.first }
        let dayNumber = Int((date.timeIntervalSince1970 + Double(calendar.timeZone.secondsFromGMT(for: date))) / 86_400)
        return days[((dayNumber % days.count) + days.count) % days.count]
    }

    // MARK: Finishing an activity

    enum Activity {
        case vocab(score: Double)
        case game(key: String, result: GameResult)      // "connections" | "wordGuess" | "crossword"
        case exercise(id: String)
    }

    /// Empty log for a day with no activity yet.
    static func emptyLog(date: String, language: String) -> DailyLog {
        DailyLog(date: date, language: language, vocabCompleted: false, vocabScore: nil,
                 games: [:], exercisesCompleted: [], xpEarned: 0, minutesSpent: 0)
    }

    /// XP this activity earns today. 0 if it was already finished today,
    /// so replaying a game can't farm XP.
    static func xp(for activity: Activity, log: DailyLog) -> Int {
        switch activity {
        case .vocab:
            return log.vocabCompleted ? 0 : vocabLessonXP
        case .game(let key, let result):
            guard log.games[key]?.status != .completed, result.status == .completed else { return 0 }
            return gameXP(score: result.score ?? 0, hintsUsed: result.hintsUsed ?? 0)
        case .exercise(let id):
            return log.exercisesCompleted.contains(id) ? 0 : exerciseXP
        }
    }

    /// Today's log after the activity. Minutes always count (the time was
    /// really spent), XP only the first time.
    static func applying(_ activity: Activity, xp: Int, minutes: Int, to log: DailyLog) -> DailyLog {
        var log = log
        switch activity {
        case .vocab(let score):
            if !log.vocabCompleted {
                log.vocabCompleted = true
                log.vocabScore = score
            }
        case .game(let key, let result):
            // A finished game is final; later saves don't overwrite it.
            if log.games[key]?.status != .completed { log.games[key] = result }
        case .exercise(let id):
            if !log.exercisesCompleted.contains(id) { log.exercisesCompleted.append(id) }
        }
        log.xpEarned += xp
        log.minutesSpent += max(0, minutes)
        return log
    }

    /// Progress after earning `xp` today: lifetime XP, weekly XP (reset when
    /// the week changed), streak, longest streak and CEFR level. Earning 0 XP
    /// changes nothing, so it doesn't count as an active day.
    static func applying(xp: Int, to progress: LanguageProgress, today: String, weekId: String) -> LanguageProgress {
        guard xp > 0 else { return progress }
        var p = progress
        p.xp += xp
        p.weeklyXP = (p.weekId == weekId ? p.weeklyXP : 0) + xp
        p.weekId = weekId
        p.currentStreak = nextStreak(current: p.currentStreak, lastActiveDate: p.lastActiveDate, today: today)
        p.longestStreak = max(p.longestStreak, p.currentStreak)
        p.lastActiveDate = today
        p.level = level(forXP: p.xp).name
        return p
    }
}

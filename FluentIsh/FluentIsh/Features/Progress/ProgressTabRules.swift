//
//  ProgressTabRules.swift
//  FluentIsh
//
//  The pure logic behind the Progress tab: how dark each Quest Path square
//  is, the summary line for a day, the Word Log search and category chips,
//  and the text in Player Stats. No UI and no Firebase, so every rule is
//  unit tested (FluentIshTests/ProgressTabRulesTests.swift).
//
//  `nonisolated` for the same reason as ProgressRules: the project defaults
//  to MainActor, and tests call these from any thread.
//

import Foundation

/// One square on the Quest Path: a calendar day, oldest (day 1) to today (day 28).
nonisolated struct QuestCell: Identifiable {
    let day: Int              // 1…28, position on the path
    let date: String          // "2026-11-09"
    let level: Int            // 0 none · 1 light · 2 medium · 3 high
    let isToday: Bool
    let log: DailyLog?

    var id: Int { day }
}

/// One row in the Word Log: the word's content plus how well the user knows it.
nonisolated struct WordLogEntry: Identifiable {
    let id: String            // word ID, e.g. "w_sobremesa"
    let word: Word
    let status: WordStatus
    let lastReviewed: Date?
}

nonisolated enum ProgressTabRules {

    // MARK: Quest Path

    static let questLength = 28

    /// How dark a day's square is, from what that day's dailyLog says was
    /// finished: the vocab lesson, each completed game and each exercise
    /// count as one activity. 0 → empty, 1 → light, 2 → medium, 3+ → full.
    /// A day with only time logged (a game saved halfway) still shows light.
    static func activityLevel(_ log: DailyLog?) -> Int {
        guard let log else { return 0 }
        let finished = (log.vocabCompleted ? 1 : 0) + gamesCompleted(log) + log.exercisesCompleted.count
        if finished == 0 { return log.minutesSpent > 0 ? 1 : 0 }
        return min(finished, 3)
    }

    /// The last `length` days, oldest first, so today is always the last
    /// square (★ 28). `logs` is what `service.recentLogs` returns.
    static func questCells(today: String, logs: [DailyLog], length: Int = questLength) -> [QuestCell] {
        let byDate = Dictionary(logs.map { ($0.date, $0) }, uniquingKeysWith: { first, _ in first })
        return (0..<length).map { index in
            let date = ProgressRules.dayKey(adding: index - (length - 1), to: today) ?? today
            let log = byDate[date]
            return QuestCell(day: index + 1, date: date, level: activityLevel(log),
                             isToday: index == length - 1, log: log)
        }
    }

    /// Same count as `DailyLog.gamesCompleted`, written out here because that
    /// computed property is main-actor isolated and these rules aren't.
    static func gamesCompleted(_ log: DailyLog) -> Int {
        log.games.values.filter { $0.status == .completed }.count
    }

    /// "Vocab lesson · 2 games · 1 exercise · 12 min", or "No activity".
    static func activitySummary(_ log: DailyLog?) -> String {
        guard let log else { return "No activity" }
        var parts: [String] = []
        if log.vocabCompleted { parts.append("Vocab lesson") }
        let games = gamesCompleted(log)
        if games > 0 { parts.append(games == 1 ? "1 game" : "\(games) games") }
        let exercises = log.exercisesCompleted.count
        if exercises > 0 { parts.append(exercises == 1 ? "1 exercise" : "\(exercises) exercises") }
        if log.minutesSpent > 0 { parts.append("\(log.minutesSpent) min") }
        return parts.isEmpty ? "No activity" : parts.joined(separator: " · ")
    }

    // MARK: Player Stats

    /// "1,245 / 1,500 XP → B2" (plan.md: levels are CEFR, not "Level 1").
    static func xpLabel(_ level: ProgressRules.LevelInfo) -> String {
        guard let nextFloor = level.nextFloor, let nextName = level.nextName else {
            return "\(level.xp.formatted()) XP · Top level"
        }
        return "\(level.xp.formatted()) / \(nextFloor.formatted()) XP → \(nextName)"
    }

    /// "89%", or "—" before any word has been reviewed (plan.md: recall only
    /// counts words seen before, so a new user has nothing to show yet).
    static func recallLabel(reviewsCorrect: Int, reviewsTotal: Int) -> String {
        guard reviewsTotal > 0 else { return "—" }
        let percent = (Double(reviewsCorrect) / Double(reviewsTotal) * 100).rounded()
        return "\(Int(percent))%"
    }

    // MARK: Word Log

    static let allCategory = "All"

    /// The categories in seed/words.json, in the mockup's chip order.
    static let knownCategories = ["Connector", "Café & Dining", "Daily Verb", "Culture & Idioms"]

    /// "All", then only the categories the user actually has words in, so a
    /// chip never leads to an empty list. Unknown categories go at the end.
    static func categories(in entries: [WordLogEntry]) -> [String] {
        let present = Set(entries.map(\.word.category))
        let known = knownCategories.filter(present.contains)
        let extra = present.subtracting(knownCategories).sorted()
        return [allCategory] + known + extra
    }

    /// Words matching the chip and the search box. Search ignores case and
    /// accents ("ademas" finds "además") and looks at the Spanish term, its
    /// lemma and the English definition.
    static func filter(_ entries: [WordLogEntry], category: String, query: String) -> [WordLogEntry] {
        let needle = normalized(query.trimmingCharacters(in: .whitespacesAndNewlines))
        return entries.filter { entry in
            if category != allCategory && entry.word.category != category { return false }
            if needle.isEmpty { return true }
            return [entry.word.term, entry.word.lemma, entry.word.definitionEn]
                .contains { normalized($0).contains(needle) }
        }
    }

    /// Most recently reviewed first; never-reviewed words last, A–Z.
    static func sorted(_ entries: [WordLogEntry]) -> [WordLogEntry] {
        entries.sorted { a, b in
            switch (a.lastReviewed, b.lastReviewed) {
            case let (x?, y?) where x != y: return x > y
            case (.some, nil): return true
            case (nil, .some): return false
            default: return normalized(a.word.lemma) < normalized(b.word.lemma)
            }
        }
    }

    static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es"))
    }
}

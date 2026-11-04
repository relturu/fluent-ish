//
//  ProgressRules.swift
//  FluentIsh
//
//  Pure game rules from docs/plan.md "Defaults to implement". No Firebase, no
//  UI, so every rule can be unit tested (FluentIshTests/ProgressRulesTests).
//  Step 4 adds dates, levels and streak display; step 5 adds scoring, XP,
//  streak updates, word status and the content-date fallback.
//

import Foundation

enum ProgressRules {

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
}

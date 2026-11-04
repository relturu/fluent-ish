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

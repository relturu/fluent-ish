//
//  SettingsChoices.swift
//  FluentIsh
//
//  Created by Jessica Zheng on 11/8/26.

//  The Settings screen's logic with no UI, so it can be unit tested
//  (FluentIshTests/SettingsTests.swift). SettingsView calls these.
//

import Foundation

nonisolated enum SettingsChoices {

    // MARK: Daily goal

    static let dailyGoalOptions = [5, 10, 15, 20]
    static let defaultDailyGoal = 10

    static func goalLabel(minutes: Int) -> String {
        "\(minutes) min"
    }

    // MARK: Language

    struct Language: Equatable {
        let name: String
        let code: String
    }

    static let languages = [
        Language(name: "Spanish", code: "ES"),
        Language(name: "French", code: "FR"),
        Language(name: "Italian", code: "IT"),
        Language(name: "Portuguese", code: "PT"),
    ]

    static func needsSwitchConfirmation(current: String, selected: String) -> Bool {
        current != selected
    }

    static func switchNotice(language: String) -> String {
        "Switched to \(language). Progress reset."
    }

    // MARK: Profile card

    static func profileSubtitle(language: String, streakDays: Int, countedToday: Bool) -> String {
        "\(language) · \(streakDays)d streak (\(countedToday ? "Counted Today ✓" : "Pending"))"
    }

    static func initials(for name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "?" : String(trimmed.prefix(2)).uppercased()
    }

    static func displayName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Player" : trimmed
    }

    static func levelPillText(_ label: String) -> String {
        "LEVEL \(label)".uppercased()
    }
}

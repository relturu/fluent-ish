//
//  SettingsTests.swift
//  FluentIshTests
//

import Foundation
import Testing
@testable import FluentIsh

struct SettingsGoalTests {
    @Test func offersFiveTenFifteenTwenty() {
        #expect(SettingsChoices.dailyGoalOptions == [5, 10, 15, 20])
    }

    @Test func defaultGoalIsOneOfTheOptions() {
        #expect(SettingsChoices.dailyGoalOptions.contains(SettingsChoices.defaultDailyGoal))
        #expect(SettingsChoices.defaultDailyGoal == 10)
    }

    @Test func goalLabelReadsLikeTheDesign() {
        #expect(SettingsChoices.goalLabel(minutes: 10) == "10 min")
        #expect(SettingsChoices.goalLabel(minutes: 5) == "5 min")
    }

    @Test func goalOptionsMatchOnboarding() {
        // Onboarding and Settings should offer the same daily paces.
        #expect(SettingsChoices.dailyGoalOptions == [5, 10, 15, 20])
    }
}

struct SettingsLanguageTests {
    @Test func listsTheFourLanguages() {
        #expect(SettingsChoices.languages.map(\.name) == ["Spanish", "French", "Italian", "Portuguese"])
        #expect(SettingsChoices.languages.map(\.code) == ["ES", "FR", "IT", "PT"])
    }

    @Test func tappingTheActiveLanguageNeedsNoConfirmation() {
        #expect(!SettingsChoices.needsSwitchConfirmation(current: "Spanish", selected: "Spanish"))
    }

    @Test func tappingAnotherLanguageAsksFirst() {
        #expect(SettingsChoices.needsSwitchConfirmation(current: "Spanish", selected: "French"))
        #expect(SettingsChoices.needsSwitchConfirmation(current: "French", selected: "Spanish"))
    }

    @Test func switchNoticeNamesTheLanguage() {
        #expect(SettingsChoices.switchNotice(language: "French") == "Switched to French. Progress reset.")
    }
}

struct SettingsProfileTests {
    @Test func subtitleWhenTodayIsPending() {
        #expect(SettingsChoices.profileSubtitle(language: "Spanish", streakDays: 14, countedToday: false)
                == "Spanish · 14d streak (Pending)")
    }

    @Test func subtitleWhenTodayIsCounted() {
        #expect(SettingsChoices.profileSubtitle(language: "Spanish", streakDays: 15, countedToday: true)
                == "Spanish · 15d streak (Counted Today ✓)")
    }

    @Test func subtitleWithNoStreak() {
        #expect(SettingsChoices.profileSubtitle(language: "Spanish", streakDays: 0, countedToday: false)
                == "Spanish · 0d streak (Pending)")
    }

    @Test func initialsAreTheFirstTwoLetters() {
        #expect(SettingsChoices.initials(for: "Sofía") == "SO")
        #expect(SettingsChoices.initials(for: "jess") == "JE")
        #expect(SettingsChoices.initials(for: "Al") == "AL")
    }

    @Test func initialsHandleShortAndEmptyNames() {
        #expect(SettingsChoices.initials(for: "J") == "J")
        #expect(SettingsChoices.initials(for: "") == "?")
        #expect(SettingsChoices.initials(for: "   ") == "?")
    }

    @Test func initialsIgnoreSurroundingSpaces() {
        #expect(SettingsChoices.initials(for: "  maya ") == "MA")
    }

    @Test func displayNameFallsBackToPlayer() {
        #expect(SettingsChoices.displayName("Sofía") == "Sofía")
        #expect(SettingsChoices.displayName("") == "Player")
        #expect(SettingsChoices.displayName("  ") == "Player")
        #expect(SettingsChoices.displayName("  Maya ") == "Maya")
    }

    @Test func levelPillIsUppercase() {
        #expect(SettingsChoices.levelPillText("1") == "LEVEL 1")
        #expect(SettingsChoices.levelPillText("a1") == "LEVEL A1")
    }
}

//
//  OnboardingTests.swift
//  FluentIshTests
//
//  How onboarding answers turn into the first Firestore documents.
//

import Testing
import Foundation
@testable import FluentIsh

struct OnboardingTests {
    @Test func initialsUseFirstAndLastWord() {
        #expect(OnboardingChoices.initials("Sofía Martínez") == "SM")
        #expect(OnboardingChoices.initials("  ana  maría  lópez ") == "AL")
        #expect(OnboardingChoices.initials("Cher") == "C")
        #expect(OnboardingChoices.initials("") == "")
    }

    @Test func usernameIsAsciiFirstNamePlusUid() {
        #expect(OnboardingChoices.username("Sofía Martínez", uid: "6oty37dOmP") == "sofia_6oty")
        #expect(OnboardingChoices.username("Ñoño", uid: "AbCd99") == "nono_abcd")
        #expect(OnboardingChoices.username("李", uid: "zz12") == "learner_zz12")   // nothing ASCII left
    }

    @Test func avatarColorIsStable() {
        let a = OnboardingChoices.avatarColor(uid: "6oty37dOmPcjAjehXvp6EHt82Z73")
        #expect(a == OnboardingChoices.avatarColor(uid: "6oty37dOmPcjAjehXvp6EHt82Z73"))
        #expect(OnboardingChoices.avatarColors.contains(a))
    }

    @Test(arguments: OnboardingChoices.StartingLevel.allCases)
    func startingLevelMatchesItsXP(level: OnboardingChoices.StartingLevel) {
        // Starting XP must land exactly on that CEFR level, or the top bar
        // would show a different level than the one picked.
        #expect(ProgressRules.level(forXP: level.startingXP).name == level.cefr)
    }

    @Test func nameIsRequiredAndTrimmed() {
        var choices = OnboardingChoices()
        #expect(!choices.canFinish)
        choices.name = "   "
        #expect(!choices.canFinish)
        choices.name = "  Arielle  "
        #expect(choices.canFinish)
        #expect(choices.trimmedName == "Arielle")
    }

    @Test func documentsFromChoices() {
        var choices = OnboardingChoices()
        choices.name = "Arielle Turullols"
        choices.dailyMinutes = 15
        choices.startingLevel = .intermediate

        let user = choices.makeUser(uid: "6oty37dOmP")
        #expect(user.displayName == "Arielle Turullols")
        #expect(user.username == "arielle_6oty")
        #expect(user.avatarInitials == "AT")
        #expect(user.targetLanguage == "es")
        #expect(user.settings.dailyGoalMinutes == 15)

        let progress = choices.makeProgress(weekId: "2026-W45")
        #expect(progress.level == "B1")
        #expect(progress.xp == 800)
        #expect(progress.weeklyXP == 0)
        #expect(progress.currentStreak == 0)
        #expect(progress.lastActiveDate == "")
        #expect(progress.displayName == "Arielle Turullols")
        // A new user's flame shows 0 until their first XP.
        #expect(ProgressRules.displayedStreak(current: 0, lastActiveDate: "", today: "2026-11-04") == 0)
    }
}

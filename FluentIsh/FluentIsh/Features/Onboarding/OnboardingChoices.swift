//
//  OnboardingChoices.swift
//  FluentIsh
//
//  What the user picks during onboarding, and how those picks become their
//  first Firestore documents. Pure Swift (no UI, no Firebase calls), so the
//  rules are unit tested in FluentIshTests/OnboardingTests.swift.
//
//  Where each answer goes:
//  - name, language, starting level, daily minutes → Firestore
//    (`users/{uid}` and `users/{uid}/progress/{lang}`), per plan.md.
//  - motivation, weekly frequency, favourite games → @AppStorage on the
//    device. plan.md has no fields for them, and nothing in V1 reads them
//    from another device.
//

import Foundation

nonisolated struct OnboardingChoices {
    var name = ""
    var language = "es"
    var motivation = "travel"
    var dailyMinutes = 10
    var weeklyFrequency = "daily"          // "daily" | "casual-week"
    var preferredGames: Set<String> = ["connections", "wordGuess", "crossword"]
    var startingLevel: StartingLevel = .beginner

    /// "How much Spanish do you know?" Each answer starts the user at a CEFR
    /// level by giving them that level's XP floor.
    enum StartingLevel: String, CaseIterable {
        case beginner, elementary, intermediate, advanced

        var cefr: String {
            switch self {
            case .beginner: "A1"
            case .elementary: "A2"
            case .intermediate: "B1"
            case .advanced: "B2"
            }
        }

        var startingXP: Int {
            ProgressRules.levels.first { $0.name == cefr }?.floor ?? 0
        }
    }

    /// The seeded demo friends, so a brand-new user's leaderboard and feed
    /// aren't empty. Real friend requests are V2.
    static let starterFriends = ["u_maya", "u_lucas", "u_elena"]

    /// Same style as the seeded users' avatar colours.
    static let avatarColors = ["#E8743B", "#3B82C4", "#2E9E6B", "#8E5BC7", "#D9485F", "#C99A2E"]

    static let maxNameLength = 24

    var trimmedName: String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(Self.maxNameLength))
    }

    var canFinish: Bool { !trimmedName.isEmpty }

    // MARK: Derived profile fields

    /// "Sofía Martínez" → "SM", "Cher" → "C". First and last word only.
    static func initials(_ name: String) -> String {
        let words = name.split(whereSeparator: \.isWhitespace)
        let picks = words.count > 1 ? [words.first!, words.last!] : words
        return picks.compactMap { $0.first.map { String($0).uppercased() } }.joined()
    }

    /// "Sofía Martínez" + uid "6oty37…" → "sofia_6oty". The uid suffix keeps
    /// two people called Sofía apart without a uniqueness check (V2).
    static func username(_ name: String, uid: String) -> String {
        let first = name.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? ""
        let ascii = first.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .lowercased().filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        let base = ascii.isEmpty ? "learner" : ascii
        return "\(base)_\(uid.prefix(4).lowercased())"
    }

    /// Picks a colour from the uid, so it's stable but varies between users.
    static func avatarColor(uid: String) -> String {
        let sum = uid.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return avatarColors[sum % avatarColors.count]
    }

    // MARK: Documents

    func makeUser(uid: String, now: Date = Date()) -> AppUser {
        AppUser(displayName: trimmedName,
                username: Self.username(trimmedName, uid: uid),
                avatarInitials: Self.initials(trimmedName),
                avatarColor: Self.avatarColor(uid: uid),
                nativeLanguage: "en",
                targetLanguage: language,
                settings: UserSettings(dailyGoalMinutes: dailyMinutes),
                createdAt: now)
    }

    /// Fresh progress: the chosen level's XP, no streak yet. `lastActiveDate`
    /// is empty until the first XP, so the flame shows 0.
    func makeProgress(weekId: String) -> LanguageProgress {
        LanguageProgress(language: language,
                         level: startingLevel.cefr,
                         xp: startingLevel.startingXP,
                         weeklyXP: 0,
                         weekId: weekId,
                         currentStreak: 0,
                         longestStreak: 0,
                         lastActiveDate: "",
                         wordsLearned: 0,
                         reviewsCorrect: 0,
                         reviewsTotal: 0,
                         displayName: trimmedName,
                         avatarInitials: Self.initials(trimmedName))
    }
}

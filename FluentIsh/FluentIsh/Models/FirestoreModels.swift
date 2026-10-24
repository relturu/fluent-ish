//
//  FirestoreModels.swift
//  FluentIsh
//
//  One Codable struct per Firestore document type (see docs/plan.md).
//  Field names must match the documents exactly. If you rename one, update
//  docs/plan.md and the seed data in the same change.
//

import Foundation
import FirebaseFirestore

// MARK: - User data

struct AppUser: Codable, Identifiable {             // users/{uid}
    @DocumentID var id: String?
    var displayName: String
    var username: String
    var avatarInitials: String
    var avatarColor: String
    var nativeLanguage: String
    var targetLanguage: String
    var settings: UserSettings
    var createdAt: Date
}

struct UserSettings: Codable {
    var dailyGoalMinutes: Int
}

struct LanguageProgress: Codable, Identifiable {   // users/{uid}/progress/{lang}
    @DocumentID var id: String?
    var language: String
    var level: String
    var xp: Int
    var weeklyXP: Int
    var weekId: String
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String
    var wordsLearned: Int
    var reviewsCorrect: Int
    var reviewsTotal: Int
    var displayName: String
    var avatarInitials: String

    var recallRate: Double {          // 89% on Progress
        reviewsTotal == 0 ? 0 : Double(reviewsCorrect) / Double(reviewsTotal)
    }
}

enum WordStatus: String, Codable { case new, learning, familiar, mastered }

struct WordProgress: Codable, Identifiable {        // users/{uid}/wordProgress/{wordId}
    @DocumentID var id: String?
    var wordId: String
    var language: String
    var status: WordStatus
    var timesSeen: Int
    var timesCorrect: Int
    var lastReviewed: Date?
    var nextReview: String
}

enum GameStatus: String, Codable { case notStarted, inProgress, completed }

struct GameResult: Codable {
    var status: GameStatus
    var score: Double?
    var mistakes: Int?
    var solvedGroups: [Int]?          // Connections
    var guesses: [String]?            // Word Guess
    var filledCells: [String]?        // Crossword
    var hintsUsed: Int?
}

struct DailyLog: Codable, Identifiable {            // users/{uid}/dailyLog/{lang_date}
    @DocumentID var id: String?
    var date: String
    var language: String
    var vocabCompleted: Bool
    var vocabScore: Double?
    var games: [String: GameResult]   // "connections", "wordGuess", "crossword"
    var exercisesCompleted: [String]
    var xpEarned: Int
    var minutesSpent: Int

    var gamesCompleted: Int { games.values.filter { $0.status == .completed }.count }
}

struct Friend: Codable, Identifiable {              // users/{uid}/friends/{friendId}
    @DocumentID var id: String?
    var friendId: String
    var status: String                // "pending" | "accepted"
    var since: Date
}

// MARK: - Content

struct AzureCache: Codable {
    var translations: [String]
    var fetchedAt: Date
}

struct Word: Codable, Identifiable {                // words/{wordId}
    @DocumentID var id: String?
    var language: String
    var term: String
    var lemma: String
    var gender: String?               // "m" | "f" | nil
    var partOfSpeech: String
    var definitionEn: String
    var category: String
    var level: String
    var example: String?
    var exampleEn: String?
    var azure: AzureCache?
}

struct VocabLesson: Codable, Identifiable {         // vocabLessons/{lang_date}
    @DocumentID var id: String?
    var language: String
    var date: String
    var title: String
    var wordCount: Int
    var reviewRatio: Double
    var newWordIds: [String]
}

struct ConnectionsGroup: Codable {
    var category: String
    var words: [String]
    var difficulty: Int
}

struct ConnectionsPuzzle: Codable { var groups: [ConnectionsGroup] }

struct WordGuessPuzzle: Codable {
    var answer: String
    var length: Int
    var definitionEn: String
}

struct CrosswordClue: Codable {
    var number: Int
    var row: Int
    var col: Int
    var clue: String
    var answer: String
}

struct CrosswordPuzzle: Codable {
    var size: Int
    var solution: [String]            // one string per row, "#" = black square
    var cluesAcross: [CrosswordClue]
    var cluesDown: [CrosswordClue]
}

struct DailyPuzzle: Codable, Identifiable {         // dailyPuzzles/{lang_date}
    @DocumentID var id: String?
    var language: String
    var date: String
    var connections: ConnectionsPuzzle
    var wordGuess: WordGuessPuzzle
    var crossword: CrosswordPuzzle
}

struct ExerciseItem: Codable {
    var prompt: String
    var answer: String
    var choices: [String]?
}

struct Exercise: Codable, Identifiable {            // exercises/{id}
    @DocumentID var id: String?
    var language: String
    var type: String                  // fillBlank | sentenceBuilder | definitionMatch
    var title: String
    var subtitle: String
    var difficulty: String            // easy | medium | hard
    var items: [ExerciseItem]
}

struct QuestDay: Codable {
    var day: Int
    var title: String
    var tier: String                  // L1 | L2 | L3
    var rewardXp: Int
    var mascotMessage: String
}

struct Quest: Codable, Identifiable {               // quests/{lang_28day}
    @DocumentID var id: String?
    var language: String
    var lengthDays: Int
    var days: [QuestDay]
}

struct DailyPrompt: Codable, Identifiable {         // dailyPrompts/{lang_date}
    @DocumentID var id: String?
    var language: String
    var date: String
    var theme: String
    var text: String
    var textEn: String?               // filled by Azure /translate at seed time
}

// MARK: - Social

struct Post: Codable, Identifiable {                // posts/{postId}
    @DocumentID var id: String?
    var authorId: String
    var authorName: String
    var authorHandle: String
    var language: String
    var type: String                  // promptResponse | achievement
    var promptId: String?
    var badge: String?
    var text: String
    var likesCount: Int
    var createdAt: Date
}

struct Like: Codable, Identifiable {                // posts/{postId}/likes/{uid}
    @DocumentID var id: String?
    var likedAt: Date
}

struct LeaderboardPeriod: Codable, Identifiable {   // leaderboardPeriods/{weekId}
    @DocumentID var id: String?
    var label: String
    var startDate: String
    var endDate: String
}

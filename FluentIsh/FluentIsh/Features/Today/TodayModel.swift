//
//  TodayModel.swift
//  FluentIsh
//
//  Loads what the Today tab shows: which seeded day to use, the vocab lesson
//  and its deck, the three puzzles, and the exercises. Progress on them
//  (games solved, lesson done) comes live from `appState.todayLog`, so this
//  only loads content, once per launch, plus a deck refresh after a lesson.
//

import Foundation
import Observation

@Observable
final class TodayModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }

    struct DeckWord: Identifiable {
        let word: Word
        let isReview: Bool
        var id: String { word.id ?? word.term }
    }

    private(set) var phase: Phase = .loading
    private(set) var lesson: VocabLesson?
    private(set) var deck: [DeckWord] = []
    private(set) var puzzle: DailyPuzzle?
    /// Seeded exercises from the `exercises` collection (the fallback).
    private(set) var exercises: [Exercise] = []
    /// Exercises built from the user's least familiar words, by ID.
    private(set) var built: [String: BuiltExercise] = [:]

    /// Built exercises first, then the seeded ones, for TodayDestination.
    var allExercises: [Exercise] { built.values.map(\.exercise) + exercises }

    /// The word behind each item of a built exercise (empty for seeded ones).
    func wordIds(forExercise id: String) -> [String] { built[id]?.wordIds ?? [] }

    func load(uid: String, language: String, today: String, service: FirestoreService) async {
        if phase != .loaded { phase = .loading }
        do {
            guard let day = try await service.contentDay(language: language, today: today) else {
                phase = .failed("No lessons have been published for this language yet.")
                return
            }
            async let lessonDoc = service.vocabLesson(language: language, day: day)
            async let puzzleDoc = service.dailyPuzzle(language: language, day: day)
            async let exerciseDocs = service.exercises(language: language)
            let lesson = try await lessonDoc
            let deck = try await service.lessonDeck(uid: uid, language: language, lesson: lesson)
            let words = try await service.words(ids: deck.wordIds)

            self.lesson = lesson
            self.deck = words.map { DeckWord(word: $0, isReview: deck.isReview($0.id ?? "")) }
            self.puzzle = try await puzzleDoc
            self.exercises = try await exerciseDocs
            self.built = await buildExercises(uid: uid, language: language, today: today,
                                              deckWords: words, service: service)
            phase = .loaded
        } catch {
            phase = .failed("Couldn't load today's content: \(error.localizedDescription)")
        }
    }

    /// The 9 exercises (3 types × 3 difficulties) from the user's word bank,
    /// least familiar first, then starter words (a new user's bank is empty).
    /// Today's deck words only supply wrong choices. If anything fails, Today
    /// falls back to the seeded exercises instead of showing an error.
    private func buildExercises(uid: String, language: String, today: String, deckWords: [Word],
                                service: FirestoreService) async -> [String: BuiltExercise] {
        do {
            async let bankDocs = service.allWordProgress(uid: uid, language: language)
            async let starterDocs = service.starterWords(language: language)
            let ranked = ProgressRules.leastFamiliarFirst(try await bankDocs, today: today).map(\.wordId)
            let bankWords = try await service.words(ids: ranked)
            let starters = try await starterDocs.filter { !ranked.contains($0.id ?? "") }
            let ordered = bankWords + starters
            var result: [String: BuiltExercise] = [:]
            for type in ExerciseBuilder.types {
                for difficulty in ExerciseBuilder.difficulties {
                    let id = ExerciseBuilder.id(type: type, difficulty: difficulty)
                    result[id] = ExerciseBuilder.build(type: type, difficulty: difficulty, words: ordered,
                                                       pool: ordered + deckWords, seed: "\(today)_\(id)")
                }
            }
            return result
        } catch {
            return [:]
        }
    }

    /// The exercise of `type` at the chosen difficulty: built from the word
    /// bank if possible, otherwise the seeded one (or any seeded one of
    /// that type).
    func exercise(type: String, difficulty: String) -> Exercise? {
        built[ExerciseBuilder.id(type: type, difficulty: difficulty)]?.exercise
            ?? exercises.first { $0.type == type && $0.difficulty == difficulty }
            ?? exercises.first { $0.type == type }
    }
}

/// Where the Today tab can navigate. Each case is a filler screen until its
/// owner builds it (see TodayDestination). The Mini Crossword is V2.
enum TodayRoute: Hashable {
    case vocab
    case connections
    case wordGuess
    case exercise(id: String)
}

/// The games that count toward "x/2" on Today in V1.
enum V1Games {
    static let keys = ["connections", "wordGuess"]

    static func completed(in log: DailyLog?) -> Int {
        keys.filter { log?.games[$0]?.status == .completed }.count
    }
}

/// Churro's greeting above "¡Hola!", one per day.
enum ChurroGreetings {
    static let all = [
        "¡Un cafecito y a jugar!",
        "¡Qué bueno verte!",
        "¡Poco a poco se llega lejos!",
        "¡Hoy toca aprender algo nuevo!",
        "¡A darle con todo!",
    ]

    static func forDay(_ day: String) -> String {
        let number = day.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return all[number % all.count]
    }
}

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
    private(set) var exercises: [Exercise] = []

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
            let deck = try await service.lessonDeck(uid: uid, language: language, today: today, lesson: lesson)
            let words = try await service.words(ids: deck.wordIds)

            self.lesson = lesson
            self.deck = words.map { DeckWord(word: $0, isReview: deck.isReview($0.id ?? "")) }
            self.puzzle = try await puzzleDoc
            self.exercises = try await exerciseDocs
            phase = .loaded
        } catch {
            phase = .failed("Couldn't load today's content: \(error.localizedDescription)")
        }
    }

    /// The exercise of `type` at the chosen difficulty, or any of that type
    /// if none matches (V1 seeds one per type).
    func exercise(type: String, difficulty: String) -> Exercise? {
        exercises.first { $0.type == type && $0.difficulty == difficulty }
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

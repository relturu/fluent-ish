//
//  ProgressModel.swift
//  FluentIsh
//
//  Loads what the Progress tab needs beyond appState.progress (which is
//  live already): the last 28 dailyLogs for the Quest Path, every word the
//  user has seen for the Word Log, and the quest definitions.
//
//  These reads are one-off (not listeners), so ProgressTabView reloads them
//  whenever XP, words learned or today's minutes change. Same pattern as
//  TodayModel.
//

import Foundation
import Observation

@Observable
final class ProgressModel {
    enum Phase: Equatable { case loading, loaded, failed(String) }

    private(set) var phase: Phase = .loading
    private(set) var logs: [DailyLog] = []
    private(set) var words: [WordLogEntry] = []
    /// Optional: if it can't be read, the Quest Path still shows activity.
    private(set) var quest: Quest?

    func load(uid: String, language: String, today: String, service: FirestoreService) async {
        // Keep showing the old data while refreshing; only the first load shows a spinner.
        if phase != .loaded { phase = .loading }
        do {
            // Both reads start at once; `try await` below waits for each.
            async let progressDocs = service.allWordProgress(uid: uid, language: language)
            async let recent = service.recentLogs(uid: uid, language: language, today: today)

            let seen = try await progressDocs
            // wordProgress only holds IDs and status; the term, definition and
            // category live in `words`.
            let content = try await service.words(ids: seen.map(\.wordId))
            var byId: [String: Word] = [:]
            for word in content { if let id = word.id { byId[id] = word } }

            let entries = seen.compactMap { progress -> WordLogEntry? in
                guard let word = byId[progress.wordId] else { return nil }
                return WordLogEntry(id: progress.wordId, word: word, status: progress.status,
                                    lastReviewed: progress.lastReviewed)
            }
            self.words = ProgressTabRules.sorted(entries)
            self.logs = try await recent
            if quest == nil { quest = try? await service.quest(language: language) }
            phase = .loaded
        } catch {
            phase = .failed("Couldn't load your progress: \(error.localizedDescription)")
        }
    }

    func questDay(_ day: Int) -> QuestDay? {
        quest?.days.first { $0.day == day }
    }
}

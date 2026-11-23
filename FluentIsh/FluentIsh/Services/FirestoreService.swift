//
//  FirestoreService.swift
//  FluentIsh
//
//  Every Firestore read and write the screens need, in one place, so views
//  never build document paths themselves. The rules (XP, streak, scores,
//  word status) live in ProgressRules; this file only moves data.
//
//  Writes that change XP all go through ONE transaction (`record`): it reads
//  progress + today's log, applies ProgressRules, and writes both back.
//  A transaction means two quick finishes (or two devices) can't both read
//  "1,245 XP" and both write "1,275": Firestore retries one of them.
//
//  Social reads and writes for the Friends tab live here; onboarding creates
//  the initial friend list.
//

import Foundation
import FirebaseFirestore

/// What finishing an activity did, for Session Review and the level-up modal.
struct ActivityOutcome {
    let xpAwarded: Int
    let previousLevel: String
    let progress: LanguageProgress
    let log: DailyLog

    var level: ProgressRules.LevelInfo { ProgressRules.level(forXP: progress.xp) }
    var leveledUp: Bool { level.name != previousLevel }
}

/// The word IDs in today's vocab lesson.
struct LessonDeck: Equatable {
    var wordIds: [String]
    var reviewIds: Set<String>

    func isReview(_ wordId: String) -> Bool { reviewIds.contains(wordId) }
}

/// One answer about one word: a vocab lesson card, a game tile or answer,
/// or an exercise item. Updates that word's wordProgress (all-time bank).
struct VocabAnswer: Equatable {
    let wordId: String
    let correct: Bool
}

enum FirestoreServiceError: LocalizedError {
    case noProgress
    case missingPost
    case insufficientLessonWords(required: Int, available: Int)

    var errorDescription: String? {
        switch self {
        case .noProgress: "You don't have progress for this language yet. Finish onboarding first."
        case .missingPost: "This post is no longer available."
        case .insufficientLessonWords(let required, let available):
            "Today's lesson needs \(required) words, but only \(available) are available. Update and re-seed the vocabulary content."
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let userId: String
    let progress: LanguageProgress

    var id: String { userId }
}

final class FirestoreService {
    private let db = Firestore.firestore()

    /// Seeded content days per language, fetched once per launch.
    private var availableDays: [String: [String]] = [:]

    // MARK: Paths

    static func dayDocId(_ language: String, _ day: String) -> String { "\(language)_\(day)" }

    func progressRef(uid: String, language: String) -> DocumentReference {
        db.document("users/\(uid)/progress/\(language)")
    }

    func dailyLogRef(uid: String, language: String, day: String) -> DocumentReference {
        db.document("users/\(uid)/dailyLog/\(Self.dayDocId(language, day))")
    }

    // MARK: Daily content (read-only)

    /// The day whose lesson, puzzles and prompt to show today. All three use
    /// the same day so they belong together. The user's own dailyLog is still
    /// keyed by the real date.
    func contentDay(language: String, today: String) async throws -> String? {
        if availableDays[language] == nil {
            let snapshot = try await db.collection("dailyPuzzles")
                .whereField("language", isEqualTo: language)
                .getDocuments()
            availableDays[language] = snapshot.documents.compactMap { $0.get("date") as? String }
        }
        return ProgressRules.contentDay(today: today, available: availableDays[language] ?? [])
    }

    func vocabLesson(language: String, day: String) async throws -> VocabLesson {
        try await db.document("vocabLessons/\(Self.dayDocId(language, day))").getDocument(as: VocabLesson.self)
    }

    func dailyPuzzle(language: String, day: String) async throws -> DailyPuzzle {
        try await db.document("dailyPuzzles/\(Self.dayDocId(language, day))").getDocument(as: DailyPuzzle.self)
    }

    func dailyPrompt(language: String, day: String) async throws -> DailyPrompt {
        try await db.document("dailyPrompts/\(Self.dayDocId(language, day))").getDocument(as: DailyPrompt.self)
    }

    /// The 28-day quest: each day's title, tier (L1/L2/L3) and Churro's line
    /// (Progress › Quest Path). One document per language: `quests/es_28day`.
    func quest(language: String) async throws -> Quest {
        try await db.document("quests/\(language)_28day").getDocument(as: Quest.self)
    }

    // MARK: Friends

    func friends(uid: String) async throws -> [Friend] {
        try await db.collection("users/\(uid)/friends")
            .getDocuments()
            .documents.map { try $0.data(as: Friend.self) }
    }

    func leaderboard(language: String, weekId: String) async throws -> [LeaderboardEntry] {
        let snapshot = try await db.collectionGroup("progress")
            .whereField("language", isEqualTo: language)
            .whereField("weekId", isEqualTo: weekId)
            .order(by: "weeklyXP", descending: true)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            guard let userId = document.reference.parent.parent?.documentID else { return nil }
            return LeaderboardEntry(userId: userId, progress: try document.data(as: LanguageProgress.self))
        }
    }

    func friendPosts(authorIds: [String]) async throws -> [Post] {
        guard !authorIds.isEmpty else { return [] }
        return try await db.collection("posts")
            .whereField("authorId", in: Array(authorIds.prefix(30)))
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .getDocuments()
            .documents.map { try $0.data(as: Post.self) }
    }

    func hasLiked(postId: String, uid: String) async throws -> Bool {
        try await db.document("posts/\(postId)/likes/\(uid)").getDocument().exists
    }

    func createPromptPost(uid: String, user: AppUser, prompt: DailyPrompt, text: String) async throws -> Post {
        let reference = db.collection("posts").document()
        try await reference.setData([
            "authorId": uid,
            "authorName": user.displayName,
            "authorHandle": user.username,
            "language": prompt.language,
            "type": "promptResponse",
            "promptId": prompt.id ?? "",
            "badge": NSNull(),
            "text": text,
            "likesCount": 0,
            "createdAt": Timestamp(date: Date()),
        ])
        return try await reference.getDocument(as: Post.self)
    }

    /// Toggles the signed-in user's like and its visible count atomically.
    func toggleLike(postId: String, uid: String) async throws -> Bool {
        let postReference = db.document("posts/\(postId)")
        let likeReference = db.document("posts/\(postId)/likes/\(uid)")
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let post = try transaction.getDocument(postReference)
                let like = try transaction.getDocument(likeReference)
                guard post.exists, let count = post.data()?["likesCount"] as? Int else {
                    throw FirestoreServiceError.missingPost
                }

                if like.exists {
                    transaction.deleteDocument(likeReference)
                    transaction.updateData(["likesCount": max(0, count - 1)], forDocument: postReference)
                    return false
                } else {
                    transaction.setData(["likedAt": Timestamp(date: Date())], forDocument: likeReference)
                    transaction.updateData(["likesCount": count + 1], forDocument: postReference)
                    return true
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        return result as? Bool ?? false
    }

    func exercises(language: String) async throws -> [Exercise] {
        try await db.collection("exercises")
            .whereField("language", isEqualTo: language)
            .getDocuments()
            .documents.map { try $0.data(as: Exercise.self) }
    }

    /// Words by ID, in the order asked for. Firestore's `in` filter takes at
    /// most 30 values, so longer lists are fetched in chunks.
    func words(ids: [String]) async throws -> [Word] {
        var byId: [String: Word] = [:]
        for chunk in ids.chunked(into: 30) {
            let snapshot = try await db.collection("words")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            for doc in snapshot.documents {
                byId[doc.documentID] = try doc.data(as: Word.self)
            }
        }
        return ids.compactMap { byId[$0] }
    }

    /// Words almost everyone knows (hola, gracias…), marked `starter: true`.
    /// They stand in for the all-time bank until a new user has one.
    func starterWords(language: String) async throws -> [Word] {
        try await db.collection("words")
            .whereField("language", isEqualTo: language)
            .whereField("starter", isEqualTo: true)
            .getDocuments()
            .documents.map { try $0.data(as: Word.self) }
    }

    // MARK: Word progress

    /// Review words due today (needs the language + nextReview index). No
    /// longer used by the vocab deck; Skill Exercises review instead (Phase 3).
    func dueReviews(uid: String, language: String, today: String, limit: Int = 7) async throws -> [WordProgress] {
        try await db.collection("users/\(uid)/wordProgress")
            .whereField("language", isEqualTo: language)
            .whereField("nextReview", isLessThanOrEqualTo: today)
            .limit(to: limit)
            .getDocuments()
            .documents.map { try $0.data(as: WordProgress.self) }
    }

    /// Every word the user has seen (Word Log, step 14).
    func allWordProgress(uid: String, language: String) async throws -> [WordProgress] {
        try await db.collection("users/\(uid)/wordProgress")
            .whereField("language", isEqualTo: language)
            .getDocuments()
            .documents.map { try $0.data(as: WordProgress.self) }
    }

    /// Today's deck: the day's 10 themed words (ProgressRules.dailyDeck).
    /// Only reads which of them are already in the user's word bank, so
    /// those can show as review.
    func lessonDeck(uid: String, language: String, lesson: VocabLesson) async throws -> LessonDeck {
        var seen: Set<String> = []
        let progressRef = db.collection("users/\(uid)/wordProgress")
        for chunk in lesson.newWordIds.chunked(into: 30) {
            let snapshot = try await progressRef
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            seen.formUnion(snapshot.documents.map(\.documentID))
        }
        let deck = ProgressRules.dailyDeck(newWordIds: lesson.newWordIds, alreadySeen: seen)
        guard deck.wordIds.count == lesson.wordCount else {
            throw FirestoreServiceError.insufficientLessonWords(required: lesson.wordCount, available: deck.wordIds.count)
        }
        return deck
    }

    // MARK: Day logs

    /// Logs from the last `days` days, newest first (Quest Path, Recent
    /// Activity). Filters by date only, so no composite index is needed;
    /// the language is checked here instead.
    func recentLogs(uid: String, language: String, today: String, days: Int = 28) async throws -> [DailyLog] {
        let start = ProgressRules.dayKey(adding: -(days - 1), to: today) ?? today
        return try await db.collection("users/\(uid)/dailyLog")
            .whereField("date", isGreaterThanOrEqualTo: start)
            .order(by: "date", descending: true)
            .getDocuments()
            .documents.map { try $0.data(as: DailyLog.self) }
            .filter { $0.language == language }
    }

    // MARK: Writes

    /// Onboarding: the user's profile, their progress in the chosen language,
    /// and the starter friends, in one batch (all or nothing). Only for a new
    /// user: it overwrites progress, so "Replay onboarding" (step 16) must not
    /// call it.
    func createProfile(uid: String, user: AppUser, progress: LanguageProgress,
                       friendIds: [String], now: Date = Date()) async throws {
        let batch = db.batch()
        try batch.setData(from: user, forDocument: db.document("users/\(uid)"))
        try batch.setData(from: progress, forDocument: progressRef(uid: uid, language: progress.language))
        for friendId in friendIds {
            try batch.setData(from: Friend(friendId: friendId, status: "accepted", since: now),
                              forDocument: db.document("users/\(uid)/friends/\(friendId)"))
        }
        try await batch.commit()
    }

    /// Finish (or save part of) an activity: one transaction that updates
    /// today's log and, if XP was earned, progress (XP, weekly XP, streak,
    /// level). Saving an in-progress game earns 0 XP and only updates the log.
    /// `words` are the right/wrong results for each word the activity used;
    /// they update wordProgress in the same transaction. Only send results
    /// once per finished activity, or they'd count twice.
    @discardableResult
    func record(_ activity: ProgressRules.Activity, minutes: Int, uid: String, language: String,
                today: String = ProgressRules.dayKey(), words: [VocabAnswer] = []) async throws -> ActivityOutcome {
        try await Self.runTransaction(db: db, uid: uid, language: language, today: today,
                                      activity: activity, minutes: minutes,
                                      answers: ProgressRules.mergedAnswers(words))
    }

    /// Finish today's vocab lesson: the same transaction as `record`, plus a
    /// wordProgress update for every card, and words-learned / recall counts.
    @discardableResult
    func completeVocabLesson(_ answers: [VocabAnswer], minutes: Int, uid: String, language: String,
                             today: String = ProgressRules.dayKey()) async throws -> ActivityOutcome {
        let score = answers.isEmpty ? 0 : Double(answers.filter(\.correct).count) / Double(answers.count)
        return try await Self.runTransaction(db: db, uid: uid, language: language, today: today,
                                             activity: .vocab(score: score), minutes: minutes,
                                             answers: ProgressRules.mergedAnswers(answers))
    }

    /// Firestore calls the transaction block on a background thread, so this
    /// is `nonisolated` (and so is everything it calls). The block may run
    /// more than once if the data changed underneath it; it only reads and
    /// computes, so retrying is safe.
    nonisolated private static func runTransaction(
        db: Firestore, uid: String, language: String, today: String,
        activity: ProgressRules.Activity, minutes: Int, answers: [VocabAnswer]
    ) async throws -> ActivityOutcome {
        let progressRef = db.document("users/\(uid)/progress/\(language)")
        let logRef = db.document("users/\(uid)/dailyLog/\(dayDocId(language, today))")
        let wordRefs = answers.map { db.document("users/\(uid)/wordProgress/\($0.wordId)") }
        let weekId = ProgressRules.weekId()

        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                // 1. Read everything first (Firestore requires reads before writes).
                let progressSnap = try transaction.getDocument(progressRef)
                guard progressSnap.exists else { throw FirestoreServiceError.noProgress }
                let progress = try progressSnap.data(as: LanguageProgress.self)
                let logSnap = try transaction.getDocument(logRef)
                let log = logSnap.exists ? try logSnap.data(as: DailyLog.self)
                                         : ProgressRules.emptyLog(date: today, language: language)
                let words: [WordProgress?] = try wordRefs.map { ref in
                    let snap = try transaction.getDocument(ref)
                    return snap.exists ? try snap.data(as: WordProgress.self) : nil
                }

                // 2. Apply the rules.
                let xp = ProgressRules.xp(for: activity, log: log)
                let newLog = ProgressRules.applying(activity, xp: xp, minutes: minutes, to: log)
                var newProgress = ProgressRules.applying(xp: xp, to: progress, today: today, weekId: weekId)

                for (index, answer) in answers.enumerated() {
                    let old = words[index]
                    let updated = ProgressRules.reviewed(old, wordId: answer.wordId, language: language,
                                                         correct: answer.correct, today: today)
                    // Recall % only counts words being *recalled*, not first sightings.
                    if let old, old.status != .new {
                        newProgress.reviewsTotal += 1
                        if answer.correct { newProgress.reviewsCorrect += 1 }
                    }
                    let wasLearned = old.map { ProgressRules.isLearned($0.status) } ?? false
                    let isLearned = ProgressRules.isLearned(updated.status)
                    if isLearned != wasLearned { newProgress.wordsLearned += isLearned ? 1 : -1 }
                    try transaction.setData(from: updated, forDocument: wordRefs[index])
                }

                // 3. Write.
                try transaction.setData(from: newLog, forDocument: logRef)
                try transaction.setData(from: newProgress, forDocument: progressRef)
                return ActivityOutcome(xpAwarded: xp,
                                       previousLevel: ProgressRules.level(forXP: progress.xp).name,
                                       progress: newProgress, log: newLog)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let outcome = result as? ActivityOutcome else { throw FirestoreServiceError.noProgress }
        return outcome
    }
}

extension Array {
    nonisolated func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

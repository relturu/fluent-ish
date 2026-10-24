//
//  DataSmokeTest.swift
//  FluentIsh
//
//  DEBUG-only end-to-end check of the data layer: reads one document of every
//  Firestore type as the signed-in user (through the real security rules and
//  indexes) and decodes it into its Swift struct. Results print to the Xcode
//  console with a 🧪 prefix.
//
//  The user's own dailyLog/wordProgress/friends are private, so first give your
//  simulator user data with: node scripts/demo-user.js <uid>
//

#if DEBUG
import Foundation
import FirebaseAuth
import FirebaseFirestore

enum DataSmokeTest {
    static let demoDate = "2026-10-24"      // first seeded day
    static let weekId = "2026-W43"

    static func run() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("🧪 Not signed in, skipping smoke test")
            return
        }
        let db = Firestore.firestore()
        var passed = 0
        var failed = 0

        func check(_ label: String, _ body: () async throws -> String) async {
            do {
                let detail = try await body()
                passed += 1
                print("🧪 ✅ \(label): \(detail)")
            } catch {
                failed += 1
                print("🧪 ❌ \(label): \(error.localizedDescription)")
            }
        }

        print("🧪 Smoke test as \(uid)")

        // MARK: User data (own documents only)
        await check("AppUser") {
            let user = try await db.document("users/\(uid)").getDocument(as: AppUser.self)
            return "\(user.displayName), goal \(user.settings.dailyGoalMinutes) min"
        }
        await check("LanguageProgress") {
            let progress = try await db.document("users/\(uid)/progress/es").getDocument(as: LanguageProgress.self)
            return "\(progress.level), \(progress.xp) XP, recall \(Int(progress.recallRate * 100))%"
        }
        await check("WordProgress (due-review query, needs index)") {
            let snap = try await db.collection("users/\(uid)/wordProgress")
                .whereField("language", isEqualTo: "es")
                .whereField("nextReview", isLessThanOrEqualTo: demoDate)
                .limit(to: 7)
                .getDocuments()
            let due = try snap.documents.map { try $0.data(as: WordProgress.self) }
            return "\(due.count) due: " + due.map(\.wordId).joined(separator: ", ")
        }
        await check("DailyLog") {
            let log = try await db.document("users/\(uid)/dailyLog/es_\(demoDate)").getDocument(as: DailyLog.self)
            return "\(log.gamesCompleted)/3 games, \(log.xpEarned) XP, \(log.minutesSpent) min"
        }
        await check("Friend") {
            let snap = try await db.collection("users/\(uid)/friends").getDocuments()
            let friends = try snap.documents.map { try $0.data(as: Friend.self) }
            return "\(friends.count) friends: " + friends.map(\.friendId).joined(separator: ", ")
        }

        // MARK: Shared content (read-only)
        await check("Word") {
            let word = try await db.document("words/w_sobremesa").getDocument(as: Word.self)
            return "\(word.term): \(word.definitionEn)"
        }
        await check("VocabLesson") {
            let lesson = try await db.document("vocabLessons/es_\(demoDate)").getDocument(as: VocabLesson.self)
            return "\(lesson.title), new: " + lesson.newWordIds.joined(separator: ", ")
        }
        await check("DailyPuzzle") {
            let puzzle = try await db.document("dailyPuzzles/es_\(demoDate)").getDocument(as: DailyPuzzle.self)
            return "\(puzzle.connections.groups.count) groups, guess \(puzzle.wordGuess.length) letters, "
                + "crossword " + puzzle.crossword.solution.joined(separator: "/")
        }
        await check("Exercise") {
            let snap = try await db.collection("exercises").getDocuments()
            let exercises = try snap.documents.map { try $0.data(as: Exercise.self) }
            return exercises.map { "\($0.type) (\($0.difficulty))" }.joined(separator: ", ")
        }
        await check("Quest") {
            let quest = try await db.document("quests/es_28day").getDocument(as: Quest.self)
            return "\(quest.days.count) days, last: \(quest.days.last?.title ?? "-")"
        }
        await check("DailyPrompt") {
            let prompt = try await db.document("dailyPrompts/es_\(demoDate)").getDocument(as: DailyPrompt.self)
            return prompt.text
        }

        // MARK: Social
        await check("Post (friend feed query, needs index)") {
            let friendIds = try await db.collection("users/\(uid)/friends").getDocuments().documents.map(\.documentID)
            guard !friendIds.isEmpty else { return "no friends to query" }
            let snap = try await db.collection("posts")
                .whereField("authorId", in: Array(friendIds.prefix(30)))
                .order(by: "createdAt", descending: true)
                .getDocuments()
            let posts = try snap.documents.map { try $0.data(as: Post.self) }
            return "\(posts.count) posts, newest by @\(posts.first?.authorHandle ?? "-")"
        }
        await check("Like") {
            let snap = try await db.collection("posts/p_001/likes").getDocuments()
            let likes = try snap.documents.map { try $0.data(as: Like.self) }
            return "\(likes.count) likes on p_001"
        }
        await check("LeaderboardPeriod") {
            let period = try await db.document("leaderboardPeriods/\(weekId)").getDocument(as: LeaderboardPeriod.self)
            return "\(period.label) \(period.startDate) → \(period.endDate)"
        }
        await check("Leaderboard (collection-group query, needs index)") {
            let snap = try await db.collectionGroup("progress")
                .whereField("language", isEqualTo: "es")
                .whereField("weekId", isEqualTo: weekId)
                .order(by: "weeklyXP", descending: true)
                .getDocuments()
            let rows = try snap.documents.map { try $0.data(as: LanguageProgress.self) }
            return rows.map { "\($0.displayName) \($0.weeklyXP)" }.joined(separator: " > ")
        }

        // MARK: Security rules: this write must be rejected
        await check("Rules block writing another user's doc") {
            do {
                try await db.document("users/u_maya").setData(["displayName": "hacked"], merge: true)
            } catch let error as NSError where error.code == FirestoreErrorCode.permissionDenied.rawValue {
                return "permission denied, as expected"
            }
            throw NSError(domain: "DataSmokeTest", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "write to users/u_maya was ALLOWED"])
        }

        print("🧪 \(failed == 0 ? "All" : "\(passed) of") \(passed + failed) checks passed\(failed == 0 ? "" : ", \(failed) failed")")
    }
}
#endif

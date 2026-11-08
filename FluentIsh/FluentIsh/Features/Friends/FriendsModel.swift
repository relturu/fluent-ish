//
//  FriendsModel.swift
//  FluentIsh
//

import Foundation
import Observation

@Observable
final class FriendsModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    enum LeaderboardScope: String, CaseIterable {
        case friends = "Friends"
        case global = "Global"
    }

    private(set) var phase: Phase = .loading
    private(set) var friendIds: Set<String> = []
    private(set) var leaderboard: [LeaderboardEntry] = []
    private(set) var prompt: DailyPrompt?
    private(set) var posts: [Post] = []
    private(set) var likedPostIds: Set<String> = []
    private(set) var togglingPostIds: Set<String> = []
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?
    var leaderboardScope: LeaderboardScope = .friends

    private var loadedUid: String?

    func load(uid: String, language: String, today: String, service: FirestoreService, force: Bool = false) async {
        guard force || loadedUid != uid else { return }
        phase = .loading
        errorMessage = nil

        do {
            async let friendRequest = service.friends(uid: uid)
            async let leaderboardRequest = service.leaderboard(
                language: language,
                weekId: ProgressRules.weekId(forKey: today) ?? ProgressRules.weekId()
            )
            async let contentDayRequest = service.contentDay(language: language, today: today)

            let fetchedFriends = try await friendRequest
            let friends = fetchedFriends.filter { $0.status == "accepted" }
            let ids = friends.map(\.friendId)
            let feedRequest = service.friendPosts(authorIds: ids)
            let leaderboard = try await leaderboardRequest
            let fetchedPosts = try await feedRequest
            let contentDay = try await contentDayRequest

            self.friendIds = Set(ids)
            self.leaderboard = leaderboard
            self.posts = fetchedPosts.filter { $0.language == language }
            if let contentDay {
                self.prompt = try await service.dailyPrompt(language: language, day: contentDay)
            } else {
                self.prompt = nil
            }

            var liked = Set<String>()
            for post in self.posts {
                guard let postId = post.id else { continue }
                if try await service.hasLiked(postId: postId, uid: uid) { liked.insert(postId) }
            }
            likedPostIds = liked
            loadedUid = uid
            phase = .loaded
        } catch {
            phase = .failed("Couldn't load Friends: \(error.localizedDescription)")
        }
    }

    func visibleLeaderboard(currentUserId: String) -> [LeaderboardEntry] {
        guard leaderboardScope == .friends else { return leaderboard }
        return leaderboard.filter { $0.userId == currentUserId || friendIds.contains($0.userId) }
    }

    func submitPromptResponse(_ answer: String, uid: String, user: AppUser, service: FirestoreService) async -> Bool {
        let answer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty, let prompt else { return false }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let completedText = prompt.text.replacingOccurrences(of: "________", with: answer)
        do {
            let post = try await service.createPromptPost(uid: uid, user: user, prompt: prompt, text: completedText)
            posts.insert(post, at: 0)
            return true
        } catch {
            errorMessage = "Couldn't share your response: \(error.localizedDescription)"
            return false
        }
    }

    func toggleLike(postId: String, uid: String, service: FirestoreService) async {
        guard !togglingPostIds.contains(postId), posts.contains(where: { $0.id == postId }) else { return }
        togglingPostIds.insert(postId)
        errorMessage = nil
        defer { togglingPostIds.remove(postId) }

        let wasLiked = likedPostIds.contains(postId)
        do {
            let isLiked = try await service.toggleLike(postId: postId, uid: uid)
            if isLiked {
                likedPostIds.insert(postId)
            } else {
                likedPostIds.remove(postId)
            }
            if isLiked != wasLiked, let index = posts.firstIndex(where: { $0.id == postId }) {
                posts[index].likesCount = max(0, posts[index].likesCount + (isLiked ? 1 : -1))
            }
        } catch {
            errorMessage = "Couldn't update this like: \(error.localizedDescription)"
        }
    }
}
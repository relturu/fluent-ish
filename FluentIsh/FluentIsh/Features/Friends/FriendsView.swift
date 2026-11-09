//
//  FriendsView.swift
//  FluentIsh
//

import SwiftUI

struct FriendsView: View {
    @Environment(AppState.self) private var appState
    @State private var model = FriendsModel()
    @State private var response = ""

    var body: some View {
        TabPage(title: "Friends", spacing: 24) {
            AppStreakIndicator()
        } content: {
            content
        }
        .task { await load() }
        .refreshable { await load(force: true) }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView("Loading Friends…")
                .frame(maxWidth: .infinity, minHeight: 220)
                .tint(Color.flame)
        case .failed(let message):
            TodayCard {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.jakarta(14, 600))
                    .foregroundStyle(Color.inkMuted)
                Button("Try Again") { Task { await load(force: true) } }
                    .buttonStyle(.tactile(.primary, size: .small))
            }
        case .loaded:
            if let message = model.errorMessage {
                Text(message)
                    .font(.jakarta(12, 600))
                    .foregroundStyle(Color.coral)
            }

            LeaderboardSection(
                entries: model.visibleLeaderboard(currentUserId: appState.uid ?? ""),
                currentUserId: appState.uid,
                scope: $model.leaderboardScope
            )

            if let prompt = model.prompt {
                DailyPromptCard(
                    prompt: prompt,
                    response: $response,
                    isSubmitting: model.isSubmitting,
                    errorMessage: model.errorMessage,
                    onSubmit: submitResponse
                )
            }

            FriendHighlightsSection(
                posts: model.posts,
                likedPostIds: model.likedPostIds,
                togglingPostIds: model.togglingPostIds,
                onLike: toggleLike
            )
        }
    }

    private func load(force: Bool = false) async {
        guard let uid = appState.uid else { return }
        await model.load(uid: uid, language: appState.language, today: appState.today,
                         service: appState.service, force: force)
    }

    private func submitResponse() {
        guard let uid = appState.uid, let user = appState.user else { return }
        Task {
            if await model.submitPromptResponse(response, uid: uid, user: user, service: appState.service) {
                response = ""
            }
        }
    }

    private func toggleLike(_ post: Post) {
        guard let uid = appState.uid, let postId = post.id else { return }
        Task { await model.toggleLike(postId: postId, uid: uid, service: appState.service) }
    }
}

private struct LeaderboardSection: View {
    let entries: [LeaderboardEntry]
    let currentUserId: String?
    @Binding var scope: FriendsModel.LeaderboardScope

    private var podiumEntries: [LeaderboardEntry] { Array(entries.prefix(3)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Leaderboard").textStyle(.h2)
                Spacer()
                Text("WEEKLY CUP")
                    .font(.jakarta(10, 800))
                    .foregroundStyle(Color.flame)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.flame.opacity(0.1), in: Capsule())
            }

            HStack(spacing: 3) {
                ForEach(FriendsModel.LeaderboardScope.allCases, id: \.self) { option in
                    Button {
                        scope = option
                    } label: {
                        Text(option.rawValue)
                            .font(.jakarta(12, 700))
                            .foregroundStyle(scope == option ? Color.white : Color.inkMuted)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 40)
                            .background {
                                if scope == option {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.flame)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(scope == option ? .isSelected : [])
                }
            }
            .padding(4)
            .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            TodayCard {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No scores this week",
                        systemImage: "trophy",
                        description: Text("Finish a game or lesson to join the Weekly Cup.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                } else {
                    if podiumEntries.count == 1 {
                        PodiumPlayer(entry: podiumEntries[0], rank: 1, isCurrentUser: podiumEntries[0].userId == currentUserId)
                            .frame(maxWidth: .infinity)
                    } else {
                        HStack(alignment: .bottom, spacing: 6) {
                            ForEach(podiumOrder, id: \.self) { rankIndex in
                                let entry = podiumEntries[rankIndex]
                                PodiumPlayer(entry: entry, rank: rankIndex + 1, isCurrentUser: entry.userId == currentUserId)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    if entries.count > 3 {
                        Rectangle().fill(Color.hairline).frame(height: 1).padding(.top, 4)
                        ForEach(entries.dropFirst(3)) { entry in
                            let rank = (entries.firstIndex(where: { $0.id == entry.id }) ?? 3) + 1
                            LeaderboardRow(entry: entry, rank: rank, isCurrentUser: entry.userId == currentUserId)
                            if entry.id != entries.last?.id {
                                Rectangle().fill(Color.hairline).frame(height: 1)
                            }
                        }
                    }
                }
            }
        }
    }

    private var podiumOrder: [Int] {
        podiumEntries.count == 3 ? [1, 0, 2] : Array(podiumEntries.indices)
    }
}

private struct PodiumPlayer: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool

    private var accent: Color {
        switch rank {
        case 1: .sunny
        case 2: Color(light: 0xDCE3EA, dark: 0x49465F)
        default: .flame
        }
    }

    private var podiumHeight: CGFloat {
        switch rank {
        case 1: 108
        case 2: 78
        default: 64
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.sunny)
                .frame(height: 22)
                .opacity(rank == 1 ? 1 : 0)

            Text(entry.progress.avatarInitials)
                .font(.jakarta(17, 800))
                .foregroundStyle(rank == 2 ? Color.ink : Color.white)
                .frame(width: 56, height: 56)
                .background(accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(entry.progress.displayName + (isCurrentUser ? " (You)" : ""))
                .font(.jakarta(12, 700))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)

            Text("\(entry.progress.weeklyXP) XP")
                .font(.jakarta(12, 700))
                .foregroundStyle(rank == 1 ? Color.flame : Color.connPurple)
                .lineLimit(1)

            VStack(spacing: 2) {
                Text("\(rank)").font(.jakarta(22, 800))
                Text(rankTitle).font(.jakarta(10, 800))
            }
            .foregroundStyle(rank == 2 ? Color.inkMuted : Color.ink)
            .frame(maxWidth: .infinity)
            .frame(height: podiumHeight)
            .background(accent.opacity(rank == 1 ? 0.9 : 0.7),
                        in: UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(entry.progress.displayName), \(entry.progress.weeklyXP) XP")
    }

    private var rankTitle: String {
        switch rank {
        case 1: "GOLD"
        case 2: "SILVER"
        default: "BRONZE"
        }
    }
}

private struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.jakarta(13, 800))
                .foregroundStyle(Color.inkMuted)
                .frame(width: 20)
            Text(entry.progress.avatarInitials)
                .font(.jakarta(11, 800))
                .foregroundStyle(Color.ink)
                .frame(width: 36, height: 36)
                .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.progress.displayName + (isCurrentUser ? " (You)" : ""))
                    .font(.jakarta(13, 700))
                    .foregroundStyle(Color.ink)
                Text("Level \(entry.progress.level)")
                    .font(.jakarta(11, 500))
                    .foregroundStyle(Color.inkMuted)
            }
            Spacer(minLength: 4)
            Text("\(entry.progress.weeklyXP) XP")
                .font(.jakarta(13, 800))
                .foregroundStyle(Color.ink)
                .monospacedDigit()
        }
        .frame(minHeight: 52)
    }
}

private struct DailyPromptCard: View {
    let prompt: DailyPrompt
    @Binding var response: String
    let isSubmitting: Bool
    let errorMessage: String?
    let onSubmit: () -> Void

    var body: some View {
        TodayCard {
            HStack {
                Text("DAILY \(prompt.language.uppercased()) PROMPT")
                    .font(.jakarta(11, 800))
                    .foregroundStyle(Color.flame)
                Spacer(minLength: 8)
                Text(prompt.theme)
                    .font(.jakarta(12, 700))
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(1)
            }

            Text(prompt.text)
                .font(.jakarta(16, 700))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                TextField("e.g., buen café, risas…", text: $response, axis: .vertical)
                    .font(.jakarta(13, 500))
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.canvas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.hairline))
                    .accessibilityLabel("Your response to the daily prompt")

                Button(action: onSubmit) {
                    Label(isSubmitting ? "Sharing" : "Share", systemImage: "paperplane")
                }
                .buttonStyle(.tactile(.primary, size: .large))
                .disabled(response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.jakarta(11, 600))
                    .foregroundStyle(Color.coral)
            }
        }
    }
}

private struct FriendHighlightsSection: View {
    let posts: [Post]
    let likedPostIds: Set<String>
    let togglingPostIds: Set<String>
    let onLike: (Post) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friend Highlights").textStyle(.h2)
            if posts.isEmpty {
                TodayCard {
                    Text("Your friends’ recent activity will show up here.")
                        .font(.jakarta(14, 500))
                        .foregroundStyle(Color.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                }
            } else {
                ForEach(posts) { post in
                    FriendPostCard(
                        post: post,
                        isLiked: post.id.map(likedPostIds.contains) ?? false,
                        isUpdatingLike: post.id.map(togglingPostIds.contains) ?? false,
                        onLike: { onLike(post) }
                    )
                }
            }
        }
    }
}

private struct FriendPostCard: View {
    let post: Post
    let isLiked: Bool
    let isUpdatingLike: Bool
    let onLike: () -> Void

    private var initials: String {
        post.authorName.split(separator: " ").prefix(2).map { String($0.prefix(1)) }.joined()
    }

    private var avatarColor: Color {
        [Color.aqua, .connPurple, .flame][avatarIndex]
    }

    private var avatarIndex: Int {
        post.authorId.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 3
    }

    private var relativeTime: String {
        RelativeDateTimeFormatter().localizedString(for: post.createdAt, relativeTo: Date())
            .replacingOccurrences(of: " ago", with: "")
    }

    var body: some View {
        TodayCard {
            HStack(spacing: 10) {
                Text(initials)
                    .font(.jakarta(13, 800))
                    .foregroundStyle(avatarIndex == 0 ? Color.ink : Color.white)
                    .frame(width: 42, height: 42)
                    .background(avatarColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.authorName)
                        .font(.jakarta(14, 700))
                        .foregroundStyle(Color.ink)
                    Text("@\(post.authorHandle) · \(relativeTime)")
                        .font(.jakarta(12, 500))
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if let badge = post.badge, !badge.isEmpty {
                    Text(badge)
                        .font(.jakarta(9, 800))
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            Text(post.text)
                .font(.jakarta(15, 500))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            Rectangle().fill(Color.hairline).frame(height: 1)

            HStack {
                Button(action: onLike) {
                    Label("\(post.likesCount)", systemImage: isLiked ? "heart.fill" : "heart")
                        .font(.jakarta(13, 700))
                        .foregroundStyle(isLiked ? Color.coral : Color.inkMuted)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isUpdatingLike)
                .accessibilityLabel(isLiked ? "Unlike post, \(post.likesCount) likes" : "Like post, \(post.likesCount) likes")

                Spacer()

                ShareLink(item: post.text) {
                    Label("Card", systemImage: "square.and.arrow.up")
                        .font(.jakarta(13, 700))
                        .foregroundStyle(Color.inkMuted)
                        .frame(minHeight: 44)
                }
                .accessibilityLabel("Share post")
            }
        }
    }
}

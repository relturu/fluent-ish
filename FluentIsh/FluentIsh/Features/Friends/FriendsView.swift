//
//  FriendsView.swift
//  FluentIsh
//
//  Friends tab: filler until Sean builds it (screenshots 12.12.08 / 12.12.14).
//
//  Already in place: onboarding adds u_maya, u_lucas and u_elena as friends;
//  the leaderboard and feed queries (and their indexes) are proven in
//  Debug/DataSmokeTest.swift; Services/AzureTranslator.swift does translate
//  and detect.
//

import SwiftUI

struct FriendsView: View {
    var body: some View {
        TabPage(title: "Friends", spacing: 14) {
            AppStreakIndicator()
        } content: {
            FillerTabHeader(text: "Leaderboards, prompts and your friends' posts will live here.",
                            owner: "Sean", mood: .celebrating)
            FillerSection(title: "Weekly Cup", summary: "Friends and global leaderboard by weekly XP",
                          owner: "Sean", icon: "trophy", color: .sunnyEdge)
            FillerSection(title: "Daily Spanish Prompt", summary: "Answer today's prompt and share it",
                          owner: "Sean", icon: "text.bubble", color: .flame)
            FillerSection(title: "Friend Highlights", summary: "Your friends' posts, likes and translations",
                          owner: "Sean", icon: "person.2", color: .aqua)
        }
    }
}

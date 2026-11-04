//
//  FriendsView.swift
//  FluentIsh
//
//  Friends tab. Step 15 builds the Weekly Cup leaderboard, the Daily Spanish
//  Prompt and Friend Highlights.
//

import SwiftUI

struct FriendsView: View {
    var body: some View {
        TabPage(title: "Friends") {
            AppStreakIndicator()
        } content: {
            ComingSoon(step: 15, text: "Leaderboard, Daily Prompt\nand Friend Highlights")
        }
    }
}

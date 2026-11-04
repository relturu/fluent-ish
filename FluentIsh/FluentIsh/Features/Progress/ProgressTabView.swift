//
//  ProgressTabView.swift
//  FluentIsh
//
//  Progress tab: filler until Sai builds it (screenshots 12.11.55 / 12.12.01).
//  (Named ProgressTabView so it doesn't clash with SwiftUI's ProgressView.)
//
//  Data that already exists for it:
//  - appState.progress: xp, wordsLearned, recallRate, currentStreak, longestStreak
//  - appState.service.recentLogs(...): the last 28 dailyLogs (Quest Path)
//  - appState.service.allWordProgress(...): every word seen (Word Log)
//

import SwiftUI

struct ProgressTabView: View {
    var body: some View {
        TabPage(title: "Progress", spacing: 14) {
            HStack(spacing: 12) {
                PillButton(title: "Rules") {}
                AppStreakIndicator()
            }
        } content: {
            FillerTabHeader(text: "Your stats, quest and word log will live here.", owner: "Sai", mood: .proud)
            FillerSection(title: "Player Stats", summary: "Level progress, words learned, recall %, streak",
                          owner: "Sai", icon: "chart.bar", color: .connPurple)
            FillerSection(title: "Quest Path", summary: "28-day map built from your daily logs",
                          owner: "Sai", icon: "map", color: .aqua)
            FillerSection(title: "Word Log", summary: "Every word you've seen, with search and category chips",
                          owner: "Sai", icon: "text.book.closed", color: .flame)
        }
    }
}

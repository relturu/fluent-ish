//
//  TodayView.swift
//  FluentIsh
//
//  Today tab. Step 4: top bar only. Step 7 builds the greeting, Daily Vocab
//  card, game cards and Skill Exercises.
//

import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabPage(title: "Today") {
            HStack(spacing: 14) {
                LevelPill(flag: "🇪🇸", level: appState.level.name)
                AppStreakIndicator()
            }
        } content: {
            if let error = appState.errorMessage {
                Text(error).textStyle(.body).foregroundStyle(Color.coral)
            }
            Text(appState.firstName.isEmpty ? "¡Hola!" : "¡Hola, \(appState.firstName)!")
                .textStyle(.serifHero)
                .foregroundStyle(Color.ink)
            ComingSoon(step: 7, text: "Daily Vocab, Today's Games\nand Skill Exercises")
        }
    }
}

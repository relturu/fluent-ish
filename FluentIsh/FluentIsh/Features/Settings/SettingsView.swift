//
//  SettingsView.swift
//  FluentIsh
//
//  Settings tab: filler until Jessica builds it (screenshots 12.12.20 / 12.12.24).
//  The Dark Mode switch already works (it's device-only, @AppStorage).
//
//  Notes for the real screen:
//  - Daily Goal writes users/{uid}.settings.dailyGoalMinutes.
//  - "Replay onboarding" must NOT call FirestoreService.createProfile: that
//    overwrites progress (XP, streak).
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
        TabPage(title: "Settings", spacing: 14) {
            AppStreakIndicator()
        } content: {
            FillerTabHeader(text: "Your profile and preferences will live here.", owner: "Jessica", mood: .waving)

            HStack {
                IconTile(systemName: darkMode ? "moon.fill" : "sun.max.fill", color: .connPurple, size: 44)
                Text("Dark Mode").textStyle(.h3).foregroundStyle(Color.ink)
                Spacer()
                Button(darkMode ? "On" : "Off") { darkMode.toggle() }
                    .buttonStyle(.tactile(darkMode ? .aqua : .outline, size: .small))
                    .frame(width: 80)
            }
            .padding(16)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline))

            FillerSection(title: "Profile", summary: "Name, avatar and username",
                          owner: "Jessica", icon: "person.crop.circle", color: .flame)
            FillerSection(title: "Daily Goal", summary: "Minutes per day (5, 10, 15 or 20)",
                          owner: "Jessica", icon: "clock", color: .connPurple)
            FillerSection(title: "Language", summary: "Spanish now; French, Italian and Portuguese later",
                          owner: "Jessica", icon: "globe", color: .aqua)
            FillerSection(title: "Audio & Reminders", summary: "Sound effects and a daily reminder notification",
                          owner: "Jessica", icon: "bell", color: .sunnyEdge)
        }
    }
}

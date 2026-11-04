//
//  SettingsView.swift
//  FluentIsh
//
//  Settings tab. Step 16 builds the profile card, Daily Goal, Language and
//  Preferences. The Dark Mode toggle is here early so the shell can be
//  checked in both colour schemes.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
        TabPage(title: "Settings") {
            AppStreakIndicator()
        } content: {
            HStack {
                Text("Dark Mode").textStyle(.h3).foregroundStyle(Color.ink)
                Spacer()
                Button(darkMode ? "On" : "Off") { darkMode.toggle() }
                    .buttonStyle(.tactile(darkMode ? .aqua : .outline, size: .small))
                    .frame(width: 80)
            }
            .padding(18)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.hairline))

            ComingSoon(step: 16, text: "Profile, Daily Goal, Language\nand Preferences")
        }
    }
}

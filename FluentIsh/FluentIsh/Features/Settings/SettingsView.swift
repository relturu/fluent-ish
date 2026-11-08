//
//  SettingsView.swift
//  FluentIsh
//
//  Settings tab, translated from Page04Settings.tsx
//

import SwiftUI

struct SettingsView: View {

    @Environment(AppState.self) private var appState

    // MARK: - Preferences (persisted on device)

    @AppStorage("dailyGoalMinutes") private var dailyGoalMinutes = 10
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("spanishAudio") private var spanishAudio = true
    @AppStorage("dailyReminder") private var dailyReminder = true
    @AppStorage("activeLanguage") private var activeLanguage = "Spanish"

    // MARK: - Local state

    @State private var pendingLanguage: String?
    @State private var savedNotice: String?
    @State private var showOnboarding = false

    // MARK: - Data

    private let goalOptions = [5, 10, 15, 20]

    private let languages: [(name: String, code: String)] = [
        ("Spanish", "ES"),
        ("French", "FR"),
        ("Italian", "IT"),
        ("Portuguese", "PT")
    ]

    // Darker bottom edges for the chunky buttons
    private let flameEdge = Color(red: 0.80, green: 0.36, blue: 0.16)
    private let aquaEdge = Color(red: 0.25, green: 0.60, blue: 0.55)
    private let neutralEdge = Color(red: 0.78, green: 0.76, blue: 0.85)

    // TODO: hook these up to your real data
    private var streakDays: Int { 0 }                       // e.g. from appState / todayLog
    private var streakCountedToday: Bool { false }          // e.g. from appState / todayLog
    private var levelLabel: String { appState.level.name }  // shown in the purple pill

    // MARK: - Body

    var body: some View {
        TabPage(title: "Settings", spacing: 16) {
            AppStreakIndicator()
        } content: {

            if let savedNotice {
                HStack {
                    Text(savedNotice)
                        .font(.jakarta(12, 700))
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .heavy))
                }
                .foregroundStyle(Color.white)
                .padding(12)
                .background(Color.flame, in: RoundedRectangle(cornerRadius: 16))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            profileCard
            dailyGoalCard
            languageCard
            preferencesCard
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isReplay: true, onClose: { showOnboarding = false })
        }
        .alert(
            "Switch to \(pendingLanguage ?? "")?",
            isPresented: Binding(
                get: { pendingLanguage != nil },
                set: { if !$0 { pendingLanguage = nil } }
            )
        ) {
            Button("Keep \(activeLanguage)", role: .cancel) {
                pendingLanguage = nil
            }
            Button("Switch & Reset", role: .destructive) {
                confirmLanguageSwitch()
            }
        } message: {
            Text("Changing your language will reset your current \(activeLanguage) progress and streak.")
        }
    }

    // MARK: - Profile

    private var initials: String {
        let name = appState.firstName
        return name.isEmpty ? "?" : String(name.prefix(2)).uppercased()
    }

    private var profileCard: some View {
        HStack(spacing: 14) {

            Text(initials)
                .font(.jakarta(18, 800))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(Color.flame, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 3) {
                Text(appState.firstName.isEmpty ? "Player" : appState.firstName)
                    .font(.jakarta(18, 800))
                    .foregroundStyle(Color.ink)

                Text("\(activeLanguage) · \(streakDays)d streak (\(streakCountedToday ? "Counted Today ✓" : "Pending"))")
                    .font(.jakarta(13, 500))
                    .foregroundStyle(Color.inkMuted)
            }

            Spacer(minLength: 0)

            Text("LEVEL \(levelLabel)".uppercased())
                .font(.jakarta(11, 800))
                .tracking(0.6)
                .foregroundStyle(Color.connPurple)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.connPurple.opacity(0.15), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.connPurple.opacity(0.3)))
        }
        .settingsCard()
    }

    // MARK: - Daily Goal

    private var dailyGoalCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack(alignment: .firstTextBaseline) {
                Text("Daily Goal")
                    .font(.jakarta(22, 800))
                    .foregroundStyle(Color.ink)
                Spacer()
                Text("\(dailyGoalMinutes) min")
                    .font(.jakarta(13, 800))
                    .foregroundStyle(Color.flame)
            }

            HStack(spacing: 10) {
                ForEach(goalOptions, id: \.self) { mins in
                    let selected = dailyGoalMinutes == mins
                    Button {
                        Haptics.tap()
                        dailyGoalMinutes = mins
                    } label: {
                        Text("\(mins)m")
                            .font(.jakarta(15, 800))
                            .foregroundStyle(selected ? Color.white : Color.inkMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                    .buttonStyle(
                        ChunkyButtonStyle(
                            face: selected ? Color.flame : Color.card,
                            edge: selected ? flameEdge : Color.clear,
                            border: selected ? nil : Color.hairline,
                            cornerRadius: 14,
                            depth: selected ? 4 : 0
                        )
                    )
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
        .settingsCard()
    }

    // MARK: - Language

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Language")
                .font(.jakarta(22, 800))
                .foregroundStyle(Color.ink)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2),
                spacing: 10
            ) {
                ForEach(languages, id: \.name) { language in
                    let isCurrent = activeLanguage == language.name
                    Button {
                        if !isCurrent { pendingLanguage = language.name }
                    } label: {
                        HStack {
                            Text(language.name)
                                .font(.jakarta(15, isCurrent ? 800 : 600))
                                .foregroundStyle(isCurrent ? Color.ink : Color.inkMuted)
                            Spacer(minLength: 4)
                            Text(isCurrent ? "Active" : language.code)
                                .font(.jakarta(12, 800))
                                .foregroundStyle(Color.flame)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(
                            isCurrent ? Color.flame.opacity(0.1) : Color.card,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isCurrent ? Color.flame : Color.hairline, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isCurrent ? .isSelected : [])
                }
            }
        }
        .settingsCard()
    }

    // MARK: - Preferences

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 4) {

            Text("Preferences")
                .font(.jakarta(22, 800))
                .foregroundStyle(Color.ink)
                .padding(.bottom, 8)

            preferenceRow(
                title: "Dark Mode",
                icon: darkMode ? "moon" : "sun.max",
                iconColor: darkMode ? Color.connPurple : Color.flame
            ) {
                toggleButton(isOn: $darkMode)
            }

            Divider().overlay(Color.hairline)

            preferenceRow(title: "Spanish Audio") {
                toggleButton(isOn: $spanishAudio, onColor: Color.aqua, onEdge: aquaEdge)
            }

            Divider().overlay(Color.hairline)

            preferenceRow(title: "Daily Reminder") {
                toggleButton(isOn: $dailyReminder, onColor: Color.aqua, onEdge: aquaEdge)
            }

            Divider().overlay(Color.hairline)

            preferenceRow(
                title: "Onboarding Tour",
                subtitle: "Revisit setup questions & mascot welcome"
            ) {
                Button {
                    showOnboarding = true
                } label: {
                    Text("Replay")
                        .font(.jakarta(14, 800))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 18)
                        .frame(height: 38)
                }
                .buttonStyle(
                    ChunkyButtonStyle(
                        face: Color.card,
                        edge: neutralEdge,
                        border: Color.hairline,
                        cornerRadius: 14,
                        depth: 3
                    )
                )
            }
        }
        .settingsCard()
    }

    // MARK: - Row helpers

    private func preferenceRow<Trailing: View>(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        iconColor: Color = .flame,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.jakarta(16, 700))
                    .foregroundStyle(Color.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.jakarta(12, 500))
                        .foregroundStyle(Color.inkMuted)
                }
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.vertical, 12)
    }

    private func toggleButton(
        isOn: Binding<Bool>,
        onColor: Color = Color.flame,
        onEdge: Color? = nil
    ) -> some View {
        let on = isOn.wrappedValue
        let edge = onEdge ?? flameEdge

        return Button {
            Haptics.tap()
            isOn.wrappedValue.toggle()
        } label: {
            Text(on ? "On" : "Off")
                .font(.jakarta(14, 800))
                .foregroundStyle(on ? Color.white : Color.ink)
                .frame(minWidth: 52)
                .padding(.horizontal, 10)
                .frame(height: 38)
        }
        .buttonStyle(
            ChunkyButtonStyle(
                face: on ? onColor : Color.card,
                edge: on ? edge : neutralEdge,
                border: on ? nil : Color.hairline,
                cornerRadius: 14,
                depth: 3
            )
        )
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: - Actions

    private func confirmLanguageSwitch() {
        guard let language = pendingLanguage else { return }
        activeLanguage = language
        pendingLanguage = nil

        // TODO: reset the player's progress here (needs an AppState method).

        withAnimation { savedNotice = "Switched to \(language). Progress reset." }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { savedNotice = nil }
        }
    }
}

// MARK: - Card styling

private extension View {
    func settingsCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.hairline, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

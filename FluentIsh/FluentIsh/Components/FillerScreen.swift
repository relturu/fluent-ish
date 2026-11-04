//
//  FillerScreen.swift
//  FluentIsh
//
//  Styled placeholders for screens a teammate is building (see the handoff
//  table in docs/plan.md). Each one names its owner, so it's clear where
//  their work plugs in.
//
//  DEBUG: "Finish (test)" saves the activity as if it had been played, so XP,
//  the streak and the Today previews can be tested before the real screen
//  exists. Replace the whole FillerScreen with the real screen; keep the
//  `appState.record(...)` call it shows you.
//

import SwiftUI

struct FillerScreen: View {
    let title: String
    let owner: String
    var mood: MascotMood = .quest
    let summary: String
    /// What "Finish (test)" saves. nil hides the button.
    var testAction: (() async throws -> ActivityOutcome)? = nil

    @State private var celebration: String?
    @State private var error: String?
    @State private var saving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MascotView(mood: mood, size: .lg)
                    .padding(.top, 24)
                Text(title)
                    .textStyle(.serifTitle)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                OwnerChip(owner: owner)
                Text(summary)
                    .font(.jakarta(14, 500))
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                #if DEBUG
                if let testAction {
                    VStack(spacing: 8) {
                        Button {
                            run(testAction)
                        } label: {
                            Label(saving ? "Saving…" : "Finish (test)", systemImage: "checkmark.seal")
                        }
                        .buttonStyle(.tactile(.secondary, fullWidth: true))
                        .disabled(saving)
                        Text("DEBUG only: saves this activity as played, to test XP and streak.")
                            .font(.jakarta(11, 600))
                            .foregroundStyle(Color.inkMuted)
                            .multilineTextAlignment(.center)
                        if let error {
                            Text(error).textStyle(.body).foregroundStyle(Color.coral)
                        }
                    }
                    .padding(.top, 12)
                }
                #endif
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .background(Color.canvas)
        .safeAreaInset(edge: .top, spacing: 0) {
            GameHeaderBar(title: title, subtitle: "Coming soon")
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay {
            if let celebration {
                CelebrationOverlay(message: celebration) { self.celebration = nil }
            }
        }
    }

    private func run(_ action: @escaping () async throws -> ActivityOutcome) {
        saving = true
        error = nil
        Task {
            do {
                let outcome = try await action()
                celebration = outcome.xpAwarded > 0
                    ? "+\(outcome.xpAwarded) XP!"
                    : "+0 XP (already done today)"
                Haptics.success()
            } catch {
                self.error = "Couldn't save: \(error.localizedDescription)"
                Haptics.error()
            }
            saving = false
        }
    }
}

/// "Owner: Sai" in the purple pill style.
struct OwnerChip: View {
    let owner: String

    var body: some View {
        Text("Owner: \(owner)")
            .font(.jakarta(12, 800))
            .foregroundStyle(Color.connPurple)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.connPurple.opacity(0.12), in: Capsule())
    }
}

/// A section card on a filler tab: what will go there and who builds it.
struct FillerSection: View {
    let title: String
    let summary: String
    let owner: String
    var icon: String = "square.dashed"
    var color: Color = .connPurple

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemName: icon, color: color, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).textStyle(.h3).foregroundStyle(Color.ink)
                Text(summary).textStyle(.body).foregroundStyle(Color.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Coming soon · \(owner)")
                    .font(.jakarta(11, 700))
                    .foregroundStyle(Color.connPurple)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
        }
        .accessibilityElement(children: .combine)
    }
}

/// Header for a filler tab: Churro + who owns the tab.
struct FillerTabHeader: View {
    let text: String
    let owner: String
    var mood: MascotMood = .thinking

    var body: some View {
        HStack(spacing: 12) {
            MascotView(mood: mood, size: .md)
            VStack(alignment: .leading, spacing: 6) {
                Text(text).font(.jakarta(15, 700)).foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                OwnerChip(owner: owner)
            }
            Spacer(minLength: 0)
        }
    }
}

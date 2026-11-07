//
//  ExerciseView.swift
//  FluentIsh
//
//  One Skill Exercise from the `exercises` collection, opened from Today's
//  Skill Exercises rows. It plays the items one by one, then saves with
//  `appState.record(.exercise(id:))` and shows the recap.
//
//  Design: design/ai-studio/src/pages/GamesAndExercises.tsx lines 1107–1553,
//  docs/design_screenshots/fill-blank-playing.png. plan.md overrides the
//  mockup: +10 XP per exercise (once a day), hints are free in V1, wrong
//  answers can be retried, accuracy counts first tries only.
//
//  The three item views (ExerciseItemViews.swift) report back with
//  `onDone(firstTry:)`; this view owns the header, progress and saving.
//

import SwiftUI

struct ExerciseView: View {
    let exercise: Exercise

    @Environment(AppState.self) private var appState

    @State private var index = 0
    @State private var firstTryCorrect = 0
    @State private var hintsUsed = 0
    /// Bumped by the header's "!" button; the item view reacts to it.
    @State private var hintRequest = 0
    @State private var showHowTo = false
    @State private var startedAt = Date()
    @State private var phase = Phase.playing
    @State private var celebration: String?

    enum Phase {
        case playing
        case saving
        case failed(String)
        case done(ActivityOutcome)
    }

    private var isMatch: Bool { exercise.type == "definitionMatch" }
    /// Definition Match is one board; the others are one screen per item.
    private var screens: Int { isMatch ? 1 : exercise.items.count }
    private var isLastScreen: Bool { index >= screens - 1 }

    var body: some View {
        Group {
            switch phase {
            case .playing:
                playing
            case .saving:
                ProgressView("Saving…").frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                failed(message)
            case .done(let outcome):
                ExerciseRecap(exercise: exercise, outcome: outcome, hintsUsed: hintsUsed,
                              accuracy: ExerciseRules.accuracyPercent(firstTry: firstTryCorrect,
                                                                       total: exercise.items.count))
            }
        }
        .background(Color.canvas)
        .safeAreaInset(edge: .top, spacing: 0) {
            GameHeaderBar(title: exercise.title, subtitle: subtitle,
                          onHowToPlay: isPlaying ? { showHowTo = true } : nil,
                          onHint: isPlaying ? { hintsUsed += 1; hintRequest += 1 } : nil)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showHowTo) {
            HowToPlaySheet(title: exercise.title, steps: Self.howTo(exercise.type))
        }
        .overlay {
            if let celebration {
                CelebrationOverlay(message: celebration) { self.celebration = nil }
            }
        }
    }

    private var isPlaying: Bool {
        if case .playing = phase { true } else { false }
    }

    private var subtitle: String {
        let level = exercise.difficulty.capitalized
        guard isPlaying else { return level }
        return isMatch ? "\(level) · \(exercise.items.count) pairs" : "\(level) · \(index + 1) of \(screens)"
    }

    // MARK: Playing

    @ViewBuilder
    private var playing: some View {
        switch exercise.type {
        case "fillBlank":
            FillBlankItemView(item: exercise.items[index], number: index + 1, total: screens,
                              isLast: isLastScreen, hintRequest: hintRequest, onDone: advance)
                .id(index)              // fresh state for each item
        case "sentenceBuilder":
            SentenceBuilderItemView(item: exercise.items[index], number: index + 1, total: screens,
                                    isLast: isLastScreen, hintRequest: hintRequest, onDone: advance)
                .id(index)
        default:
            DefinitionMatchView(items: exercise.items, hintRequest: hintRequest) { firstTryPairs in
                firstTryCorrect = firstTryPairs
                finish()
            }
        }
    }

    private func advance(firstTry: Bool) {
        if firstTry { firstTryCorrect += 1 }
        if isLastScreen {
            finish()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { index += 1 }
        }
    }

    // MARK: Saving

    private func finish() {
        guard let id = exercise.id else {
            phase = .failed("This exercise has no ID, so it can't be saved.")
            return
        }
        phase = .saving
        let minutes = ExerciseRules.minutes(from: startedAt, to: Date())
        Task {
            do {
                let outcome = try await appState.record(.exercise(id: id), minutes: minutes)
                Haptics.success()
                celebration = outcome.xpAwarded > 0 ? "+\(outcome.xpAwarded) XP!" : "¡Bien hecho!"
                phase = .done(outcome)
            } catch {
                Haptics.error()
                phase = .failed("Couldn't save: \(error.localizedDescription)")
            }
        }
    }

    private func failed(_ message: String) -> some View {
        VStack(spacing: 14) {
            MascotView(mood: .thinking, size: .md)
            Text(message).textStyle(.body).foregroundStyle(Color.ink).multilineTextAlignment(.center)
            Button("Try again") { finish() }
                .buttonStyle(.tactile(.primary, size: .small))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: How to play (from the prototype's GameAssistModal, plus plan.md's rules)

    static func howTo(_ type: String) -> [String] {
        switch type {
        case "fillBlank":
            ["Read the sentence and its English meaning.",
             "Tap the Spanish word that fills the blank.",
             "Wrong? Try again. Stuck? Tap ! to see the answer (free)."]
        case "sentenceBuilder":
            ["Read the English sentence.",
             "Tap the Spanish words in order. Tap a placed word to send it back.",
             "Tap Check. Stuck? Tap ! to place the next word (free)."]
        default:
            ["Tap a Spanish word on the left, then its English meaning on the right.",
             "Matched pairs fade out. Match them all to finish.",
             "Stuck? Tap ! to match the next pair (free)."]
        }
    }
}

// MARK: - How to play sheet

struct HowToPlaySheet: View {
    let title: String
    let steps: [String]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("HOW TO PLAY")
                        .font(.jakarta(10, 800)).tracking(0.8)
                        .foregroundStyle(Color.flame)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.flame.opacity(0.15), in: Capsule())
                    Text(title).font(.fraunces(21, 700)).foregroundStyle(Color.ink)
                }
                Spacer()
                CloseButton { dismiss() }
            }
            ForEach(Array(steps.enumerated()), id: \.offset) { number, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(number + 1)")
                        .font(.jakarta(13, 800)).foregroundStyle(Color.flame)
                        .frame(width: 26, height: 26)
                        .background(Color.flame.opacity(0.15), in: Circle())
                    Text(step).font(.jakarta(14, 600)).foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            Button("Got it") { dismiss() }
                .buttonStyle(.tactile(.primary, fullWidth: true))
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.modal)
        .presentationCornerRadius(28)
    }
}

// MARK: - Recap

/// The end-of-exercise summary. Sean's Session Review (porting-guide.md,
/// GamesAndExercises.tsx lines 217–445) replaces this when it exists; keep
/// passing it the same numbers.
struct ExerciseRecap: View {
    let exercise: Exercise
    let outcome: ActivityOutcome
    let hintsUsed: Int
    let accuracy: Int

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                MascotView(mood: .proud, size: .lg).padding(.top, 24)
                VStack(spacing: 6) {
                    Text(accuracy == 100 ? "¡Perfecto!" : "¡Bien hecho!")
                        .textStyle(.serifTitle).foregroundStyle(Color.ink)
                    Text("\(exercise.title) · \(exercise.difficulty.capitalized)")
                        .textStyle(.body).foregroundStyle(Color.inkMuted)
                }

                HStack(spacing: 10) {
                    stat(value: "\(accuracy)%", label: "First try", color: .aqua)
                    stat(value: "+\(outcome.xpAwarded)", label: "XP", color: .flame)
                    stat(value: "\(hintsUsed)", label: hintsUsed == 1 ? "Hint" : "Hints", color: .connPurple)
                }

                if outcome.leveledUp {
                    Label("You reached \(appState.level.name)!", systemImage: "sparkles")
                        .font(.jakarta(14, 800)).foregroundStyle(Color.flame)
                } else if outcome.xpAwarded == 0 {
                    Text("Already done today, so no extra XP. Your minutes still count.")
                        .textStyle(.body).foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                }

                Button("Back to Today") { dismiss() }
                    .buttonStyle(.tactile(.primary, size: .large, fullWidth: true))
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func stat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.jakarta(22, 800)).foregroundStyle(color)
            Text(label.uppercased()).textStyle(.caption).foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.hairline))
        .accessibilityElement(children: .combine)
    }
}

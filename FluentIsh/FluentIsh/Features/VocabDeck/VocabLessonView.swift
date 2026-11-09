//
//  VocabLessonView.swift
//  FluentIsh
//
//  Daily Spanish vocabulary cards and their session review.
//

import SwiftUI

struct VocabLessonView: View {
    private enum Mode: Equatable {
        case cards
        case list
    }

    private enum Phase {
        case studying
        case saving
        case failed(String, retryable: Bool)
        case review(ActivityOutcome)
    }

    let words: [TodayModel.DeckWord]
    let lessonTitle: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var mode = Mode.cards
    @State private var index = 0
    @State private var startedAt = Date()
    @State private var phase = Phase.studying
    @State private var showLevelUp = false
    @State private var sessionMinutes = 1

    private var currentWord: TodayModel.DeckWord? {
        words.indices.contains(index) ? words[index] : nil
    }

    var body: some View {
        Group {
            switch phase {
            case .studying:
                studying
            case .saving:
                ProgressView("Saving lesson…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message, let retryable):
                failed(message, retryable: retryable)
            case .review(let outcome):
                VocabSessionReviewView(
                    words: words,
                    lessonTitle: lessonTitle,
                    outcome: outcome,
                    minutesSpent: sessionMinutes,
                    onBack: { dismiss() }
                )
            }
        }
        .background(Color.canvas)
        .safeAreaInset(edge: .top, spacing: 0) {
            GameHeaderBar(
                title: isReviewing ? "Session Review" : "Daily Vocab Lesson",
                subtitle: isReviewing ? lessonTitle : "Words & Definitions"
            ) {
                if !isReviewing {
                    modePicker
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showLevelUp) {
            if case .review(let outcome) = phase {
                VocabLevelUpSheet(outcome: outcome)
            }
        }
        .onAppear {
            guard words.isEmpty else { return }
            phase = .failed("Today's vocabulary isn't available yet. Go back and try loading the lesson again.",
                            retryable: false)
        }
    }

    private var isReviewing: Bool {
        if case .review = phase { true } else { false }
    }

    private var studying: some View {
        VStack(spacing: 0) {
            if words.isEmpty {
                failed("Today's vocabulary isn't available yet. Go back and try loading the lesson again.")
            } else {
                lessonProgress
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 12)

                ScrollView {
                    if mode == .cards {
                        if let currentWord {
                            VocabWordCard(deckWord: currentWord)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                    } else {
                        VStack(spacing: 14) {
                            ForEach(Array(words.enumerated()), id: \.element.id) { _, deckWord in
                                VocabWordCard(deckWord: deckWord)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)

                lessonControls
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var lessonProgress: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(mode == .cards ? "Word \(index + 1) of \(words.count)" : "\(words.count) words")
                    .font(.jakarta(13, 700))
                    .foregroundStyle(Color.inkMuted)
                Spacer()
                if mode == .cards, let currentWord {
                    Text(currentWord.isReview ? "Review" : "New")
                        .font(.jakarta(13, 800))
                        .foregroundStyle(currentWord.isReview ? Color.aqua : Color.flame)
                } else {
                    Text("\(reviewCount) review · \(words.count - reviewCount) new")
                        .font(.jakarta(12, 700))
                        .foregroundStyle(Color.inkMuted)
                }
            }
            HStack(spacing: 3) {
                ForEach(Array(words.enumerated()), id: \.element.id) { wordIndex, word in
                    Capsule()
                        .fill(mode == .list || wordIndex <= index
                              ? (word.isReview ? Color.aqua : Color.flame)
                              : Color.segmentTrack)
                        .frame(height: 7)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(mode == .cards ? "Word \(index + 1) of \(words.count)" : "All \(words.count) words")
        }
    }

    private var reviewCount: Int { words.filter(\.isReview).count }

    private var lessonControls: some View {
        HStack(spacing: 12) {
            if mode == .cards {
                Button {
                    Haptics.tap()
                    index = max(0, index - 1)
                } label: {
                    Label("Prev", systemImage: "chevron.left")
                }
                .buttonStyle(.tactile(.outline))
                .disabled(index == 0)

                Button {
                    Haptics.tap()
                    if index == words.count - 1 {
                        completeLesson()
                    } else {
                        index += 1
                    }
                } label: {
                    Label(index == words.count - 1 ? "Finish Lesson" : "Next Word",
                          systemImage: index == words.count - 1 ? "checkmark" : "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.tactile(.primary, fullWidth: true))
            } else {
                Button {
                    Haptics.tap()
                    completeLesson()
                } label: {
                    Label("Complete Lesson", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.tactile(.primary, fullWidth: true))
            }
        }
        .disabled(isSaving)
    }

    private var isSaving: Bool {
        if case .saving = phase { true } else { false }
    }

    private var modePicker: some View {
        HStack(spacing: 2) {
            modeButton(.cards, title: "Cards", symbol: "square.stack")
            modeButton(.list, title: "List", symbol: "list.bullet")
        }
        .padding(3)
        .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Lesson view mode")
    }

    private func modeButton(_ selection: Mode, title: String, symbol: String) -> some View {
        let selected = mode == selection
        return Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.18)) { mode = selection }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(selected ? Color.white : Color.inkMuted)
                .frame(width: 34, height: 34)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.flame)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) view")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func failed(_ message: String, retryable: Bool = false) -> some View {
        VStack(spacing: 16) {
            MascotView(mood: .thinking, size: .md)
            Text(message)
                .textStyle(.body)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
            if retryable {
                Button("Try Again", action: completeLesson)
                    .buttonStyle(.tactile(.primary, fullWidth: true))
            }
            Button("Back to Today") { dismiss() }
                .buttonStyle(.tactile(retryable ? .outline : .primary, fullWidth: true))
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func completeLesson() {
        guard !isSaving else { return }
        guard let uid = appState.uid, words.allSatisfy({ $0.word.id != nil }) else {
            phase = .failed("This lesson is missing a word ID or signed-in user, so it can't be saved.",
                            retryable: false)
            return
        }

        phase = .saving
        let answers = words.compactMap { deckWord in
            deckWord.word.id.map { VocabAnswer(wordId: $0, correct: true) }
        }
        let minutes = ExerciseRules.minutes(from: startedAt, to: Date())
        sessionMinutes = minutes
        Task {
            do {
                let outcome = try await appState.service.completeVocabLesson(
                    answers,
                    minutes: minutes,
                    uid: uid,
                    language: appState.language,
                    today: appState.today
                )
                Haptics.success()
                phase = .review(outcome)
                if outcome.leveledUp { showLevelUp = true }
            } catch {
                Haptics.error()
                phase = .failed("Couldn't save today's lesson: \(error.localizedDescription)",
                                retryable: true)
            }
        }
    }
}

private struct VocabWordCard: View {
    let deckWord: TodayModel.DeckWord
    private var word: Word { deckWord.word }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Text(word.category.uppercased())
                            .font(.jakarta(11, 800))
                            .tracking(0.35)
                            .foregroundStyle(Color.inkMuted)
                        Text(deckWord.isReview ? "REVIEW" : "NEW")
                            .font(.jakarta(9, 800))
                            .foregroundStyle(deckWord.isReview ? Color.chipReviewText : Color.chipNewText)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(deckWord.isReview ? Color.chipReviewBg : Color.chipNewBg,
                                        in: Capsule())
                    }
                    Text(word.term)
                        .font(.jakarta(27, 800))
                        .tracking(-0.7)
                        .foregroundStyle(Color.flame)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        if let phonetic = word.phonetic {
                            Text(phonetic)
                                .font(.jakarta(14, 500))
                                .foregroundStyle(Color.inkMuted)
                        } else {
                            Text("IPA transcription unavailable")
                                .font(.jakarta(12, 600))
                                .foregroundStyle(Color.coral)
                        }
                        Text(word.partOfSpeech.capitalized)
                            .font(.jakarta(10, 800))
                            .foregroundStyle(Color.ink)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.segmentTrack, in: Capsule())
                    }
                }
                Spacer(minLength: 0)
                AudioButton(text: word.term)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("DEFINITION", systemImage: "book.closed")
                    .font(.jakarta(12, 800))
                    .foregroundStyle(Color.chipReviewText)
                Text(word.definitionEn)
                    .font(.jakarta(16, 800))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(light: 0xFFF8EC, dark: 0x17143A),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.aqua.opacity(0.18))
            }

            Rectangle().fill(Color.hairline).frame(height: 1)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(word.example ?? "Example not available.")
                        .font(.jakarta(15, 600).italic())
                        .foregroundStyle(Color.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(word.exampleEn ?? "Translation not available.")
                        .font(.jakarta(13, 500))
                        .foregroundStyle(Color.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if let example = word.example {
                    AudioButton(text: example)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.hairline)
        }
        .shadow(color: Color.indigo.opacity(0.05), radius: 3, y: 2)
    }
}

private struct VocabSessionReviewView: View {
    let words: [TodayModel.DeckWord]
    let lessonTitle: String
    let outcome: ActivityOutcome
    let minutesSpent: Int
    let onBack: () -> Void

    private var scorePoints: Int {
        ProgressRules.vocabScorePoints(score: outcome.log.vocabScore ?? 0)
    }

    private var activeToday: Bool { outcome.progress.lastActiveDate == outcome.log.date }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                MascotView(mood: .proud, size: .lg)
                    .padding(.top, 24)

                VStack(spacing: 5) {
                    Text("¡Increíble!")
                        .textStyle(.serifTitle)
                        .foregroundStyle(Color.ink)
                    Text("Daily Vocab Lesson · \(lessonTitle)")
                        .textStyle(.body)
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    stat(value: outcome.xpAwarded > 0 ? "+\(outcome.xpAwarded)" : "+0",
                         label: "XP Earned", color: .flame)
                    stat(value: "\(scorePoints) Pts", label: "Score", color: .aqua)
                }

                HStack(spacing: 0) {
                    stat(value: "\(ProgressRules.vocabScorePoints(score: outcome.log.vocabScore ?? 0))%",
                         label: "Accuracy", color: .success)
                    stat(value: "\(minutesSpent)m", label: "Time", color: .ink)
                }

                VStack(spacing: 12) {
                    HStack {
                        Label("Daily Streak", systemImage: "flame.fill")
                            .font(.jakarta(14, 800))
                            .foregroundStyle(Color.flame)
                        Spacer()
                        Text(activeToday ? "Active ✓" : "Not counted")
                            .font(.jakarta(13, 700))
                            .foregroundStyle(activeToday ? Color.success : Color.inkMuted)
                    }
                    HStack {
                        Text("Level \(ProgressRules.level(forXP: outcome.progress.xp).name)")
                            .font(.jakarta(13, 800))
                            .foregroundStyle(Color.connPurple)
                        Spacer()
                        let level = ProgressRules.level(forXP: outcome.progress.xp)
                        Text(level.nextName.map { "\(level.xpToNext) XP to \($0)" } ?? "Top level")
                            .font(.jakarta(12, 700))
                            .foregroundStyle(Color.inkMuted)
                    }
                }
                .padding(16)
                .background(Color.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.hairline)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("WORDS PRACTICED")
                        .textStyle(.caption)
                        .foregroundStyle(Color.inkMuted)
                    ForEach(words) { deckWord in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(deckWord.word.term)
                                .font(.jakarta(14, 800))
                                .foregroundStyle(Color.ink)
                            Spacer(minLength: 8)
                            Text(deckWord.word.definitionEn)
                                .font(.jakarta(12, 500))
                                .foregroundStyle(Color.inkMuted)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, 6)
                        if deckWord.id != words.last?.id {
                            Rectangle().fill(Color.hairline).frame(height: 1)
                        }
                    }
                }
                .padding(16)
                .background(Color.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.hairline)
                }

                if outcome.xpAwarded == 0 {
                    Text("You already completed today's lesson. Review is always welcome!")
                        .font(.jakarta(12, 600))
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                }

                Button("Back to Today", action: onBack)
                    .buttonStyle(.tactile(.primary, fullWidth: true))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    private func stat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.jakarta(20, 800))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label.uppercased())
                .font(.jakarta(10, 800))
                .tracking(0.4)
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.hairline)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct VocabLevelUpSheet: View {
    let outcome: ActivityOutcome

    @Environment(\.dismiss) private var dismiss

    private var level: ProgressRules.LevelInfo {
        ProgressRules.level(forXP: outcome.progress.xp)
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.connPurple)
            Text("Level Up!")
                .font(.fraunces(24, 700))
                .foregroundStyle(Color.ink)
            Text("You reached \(level.name) with \(outcome.progress.xp.formatted()) XP.")
                .font(.jakarta(14, 600))
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
            Button("Keep Going") { dismiss() }
                .buttonStyle(.tactile(.primary, fullWidth: true))
        }
        .padding(24)
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.modal)
        .presentationCornerRadius(28)
    }
}

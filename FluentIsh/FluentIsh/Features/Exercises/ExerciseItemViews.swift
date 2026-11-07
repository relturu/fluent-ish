//
//  ExerciseItemViews.swift
//  FluentIsh
//
//  The three exercise boards. Each one checks its own answers, shakes on a
//  miss, applies a hint when `hintRequest` changes, and calls `onDone`
//  when the player moves on. A hinted item never counts as a first try.
//
//  Prototype: GamesAndExercises.tsx, Fill in the Blank 1107–1254,
//  Sentence Builder 1255–1388, Definition Match 1389–1553.
//

import SwiftUI

// MARK: - Fill in the Blank

struct FillBlankItemView: View {
    let item: ExerciseItem
    let number: Int
    let total: Int
    let isLast: Bool
    let hintRequest: Int
    let onDone: (_ firstTry: Bool) -> Void

    @State private var wrong: Set<String> = []
    @State private var solved = false
    @State private var hinted = false
    @State private var misses = 0

    private var options: [String] { item.choices ?? [item.answer] }

    var body: some View {
        ExerciseLayout(isLast: isLast, canContinue: solved, continueLabel: nil) {
            onDone(wrong.isEmpty && !hinted)
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(number) / \(total)").textStyle(.caption).foregroundStyle(Color.flame)
                    Spacer()
                    AudioButton(text: ExerciseRules.filledSentence(item))
                }
                sentence
                    .font(.jakarta(24, 800))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let english = item.promptEn {
                    Text(english).font(.jakarta(13, 500)).foregroundStyle(Color.ink.opacity(0.6))
                }
            }

            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    OptionRow(text: option, state: state(of: option)) { choose(option) }
                }
            }
            .shake(misses)
        }
        .onChange(of: hintRequest) {
            guard !solved else { return }
            hinted = true
            solved = true
        }
    }

    /// "Yo ______ café." with the blank (or the right answer) in orange.
    private var sentence: Text {
        let fill = Text(solved ? item.answer : "______")
            .foregroundStyle(Color.flame)
            .underline(color: .flame)
        guard let parts = ExerciseRules.blankParts(item.prompt) else { return Text(item.prompt) }
        return Text("\(parts.before)\(fill)\(parts.after)")
    }

    private func state(of option: String) -> OptionRow.State {
        if solved && option == item.answer { return .correct }
        if wrong.contains(option) { return .wrong }
        return solved ? .disabled : .idle
    }

    private func choose(_ option: String) {
        guard !solved, !wrong.contains(option) else { return }
        if option == item.answer {
            Haptics.success()
            withAnimation(.spring(duration: 0.25)) { solved = true }
        } else {
            Haptics.error()
            wrong.insert(option)
            misses += 1
        }
    }
}

/// One answer row: white, then indigo with a green ✓ when right, faded
/// with a red × when wrong.
struct OptionRow: View {
    enum State { case idle, correct, wrong, disabled }

    let text: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text).font(.jakarta(15, 700))
                Spacer()
                switch state {
                case .correct: Image(systemName: "checkmark").foregroundStyle(Color.success)
                case .wrong: Image(systemName: "xmark").foregroundStyle(Color.coral)
                default: EmptyView()
                }
            }
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(state == .correct ? Color.canvas : Color.ink)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(state == .correct ? Color.ink : Color.card,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(state == .wrong ? Color.coral.opacity(0.6) : Color.hairline, lineWidth: 1.5)
            }
            .opacity(state == .wrong || state == .disabled ? 0.55 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(state == .correct ? "correct" : state == .wrong ? "wrong" : "")
    }
}

// MARK: - Sentence Builder

struct SentenceBuilderItemView: View {
    let item: ExerciseItem
    let number: Int
    let total: Int
    let isLast: Bool
    let hintRequest: Int
    let onDone: (_ firstTry: Bool) -> Void

    /// Indices into `tiles`, in the order placed (a word can be on two tiles).
    @State private var picked: [Int] = []
    @State private var solved = false
    @State private var missed = false
    @State private var hinted = false
    @State private var misses = 0

    private var tiles: [String] { ExerciseRules.tiles(for: item) }
    private var pickedWords: [String] { picked.map { tiles[$0] } }

    var body: some View {
        ExerciseLayout(isLast: isLast, canContinue: solved || !picked.isEmpty,
                       continueLabel: solved ? nil : "Check") {
            if solved { onDone(!missed && !hinted) } else { check() }
        } content: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Translate · \(number) / \(total)").textStyle(.caption).foregroundStyle(Color.flame)
                    Spacer()
                    AudioButton(text: item.answer)
                }
                Text("“\(item.prompt)”")
                    .font(.jakarta(24, 800)).foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Drop area: tap a placed word to send it back.
            FlowLayout(spacing: 8) {
                if picked.isEmpty {
                    Text("Tap words below in order…")
                        .font(.jakarta(13, 700)).foregroundStyle(Color.ink.opacity(0.4))
                }
                ForEach(picked, id: \.self) { index in
                    Button(tiles[index]) { unpick(index) }
                        .buttonStyle(.tactile(solved ? .aqua : .primary, size: .small))
                        .disabled(solved)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(solved ? Color.success : Color.ink.opacity(0.25),
                                  style: StrokeStyle(lineWidth: 2, dash: solved ? [] : [7, 5]))
            }
            .shake(misses)

            // Word bank: used tiles stay as faint placeholders so nothing jumps.
            FlowLayout(spacing: 8) {
                ForEach(tiles.indices, id: \.self) { index in
                    let used = picked.contains(index)
                    Button(tiles[index]) { pick(index) }
                        .buttonStyle(.tactile(.outline, size: .small))
                        .opacity(used ? 0.25 : 1)
                        .disabled(used || solved)
                }
            }
        }
        .onChange(of: hintRequest) {
            guard !solved else { return }
            hinted = true
            withAnimation(.spring(duration: 0.25)) {
                picked = ExerciseRules.hintPlacement(picked: picked, tiles: tiles, answer: item.answer)
            }
            if ExerciseRules.isCorrectSentence(picked: pickedWords, answer: item.answer) { solved = true }
        }
    }

    private func pick(_ index: Int) {
        Haptics.tap()
        withAnimation(.spring(duration: 0.25)) { picked.append(index) }
    }

    private func unpick(_ index: Int) {
        Haptics.tap()
        withAnimation(.spring(duration: 0.25)) { picked.removeAll { $0 == index } }
    }

    private func check() {
        if ExerciseRules.isCorrectSentence(picked: pickedWords, answer: item.answer) {
            Haptics.success()
            withAnimation(.spring(duration: 0.25)) { solved = true }
        } else {
            Haptics.error()
            missed = true
            misses += 1
        }
    }
}

// MARK: - Definition Match

struct DefinitionMatchView: View {
    let items: [ExerciseItem]
    let hintRequest: Int
    let onDone: (_ firstTryPairs: Int) -> Void

    /// The English column, shuffled once.
    @State private var englishOrder: [Int] = []
    @State private var pickedSpanish: Int?
    @State private var pickedEnglish: Int?
    @State private var matched: Set<Int> = []
    /// Pairs that had a miss or were given by a hint: not first tries.
    @State private var notFirstTry: Set<Int> = []
    @State private var misses = 0

    private var allMatched: Bool { matched.count == items.count }

    var body: some View {
        ExerciseLayout(isLast: true, canContinue: allMatched, continueLabel: nil) {
            onDone(items.count - notFirstTry.count)
        } content: {
            Text("Match each Spanish word with its meaning.")
                .font(.jakarta(14, 600)).foregroundStyle(Color.ink.opacity(0.7))

            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 8) {
                    ForEach(items.indices, id: \.self) { index in
                        MatchTile(text: items[index].prompt, isSpanish: true,
                                  selected: pickedSpanish == index, matched: matched.contains(index)) {
                            Speech.speak(items[index].prompt)
                            pickedSpanish = index
                            check()
                        }
                    }
                }
                VStack(spacing: 8) {
                    ForEach(englishOrder, id: \.self) { index in
                        MatchTile(text: items[index].answer, isSpanish: false,
                                  selected: pickedEnglish == index, matched: matched.contains(index)) {
                            pickedEnglish = index
                            check()
                        }
                    }
                }
            }
            .shake(misses)
        }
        .onAppear {
            if englishOrder.isEmpty { englishOrder = Array(items.indices).shuffled() }
        }
        .onChange(of: hintRequest) {
            guard let next = items.indices.first(where: { !matched.contains($0) }) else { return }
            notFirstTry.insert(next)
            pickedSpanish = nil
            pickedEnglish = nil
            withAnimation(.easeOut(duration: 0.25)) { _ = matched.insert(next) }
        }
    }

    private func check() {
        guard let spanish = pickedSpanish, let english = pickedEnglish else {
            Haptics.tap()
            return
        }
        pickedSpanish = nil
        pickedEnglish = nil
        if spanish == english {
            Haptics.success()
            withAnimation(.easeOut(duration: 0.25)) { _ = matched.insert(spanish) }
        } else {
            Haptics.error()
            notFirstTry.insert(spanish)
            misses += 1
        }
    }
}

/// A Definition Match card: orange when a Spanish card is picked, indigo
/// for English, faded once matched.
private struct MatchTile: View {
    let text: String
    let isSpanish: Bool
    let selected: Bool
    let matched: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.jakarta(isSpanish ? 14 : 13, isSpanish ? 800 : 700))
                .foregroundStyle(selected ? (isSpanish ? Color.white : Color.canvas) : Color.ink)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .padding(.horizontal, 12)
                .background(selected ? (isSpanish ? Color.flame : Color.ink) : Color.card,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.hairline))
                .opacity(matched ? 0.25 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(matched)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityValue(matched ? "matched" : "")
    }
}

// MARK: - Shared layout

/// Scrolling content with the big button pinned to the bottom.
private struct ExerciseLayout<Content: View>: View {
    let isLast: Bool
    let canContinue: Bool
    /// nil means "Next", or "Finish" on the last screen.
    let continueLabel: String?
    let onContinue: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) { content }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button(continueLabel ?? (isLast ? "Finish" : "Next"), action: onContinue)
                .buttonStyle(.tactile(.primary, size: .large, fullWidth: true))
                .disabled(!canContinue)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
    }
}

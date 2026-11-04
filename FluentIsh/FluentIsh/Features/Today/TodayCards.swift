//
//  TodayCards.swift
//  FluentIsh
//
//  The building blocks of the Today tab (screenshots 12.11.08 / 12.11.14):
//  the white card, the (i) button, the small Play pill, and the three game
//  previews, which draw real progress from today's dailyLog.
//

import SwiftUI

// MARK: - Card container

struct TodayCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline))
            .shadow(color: Color.indigo.opacity(0.04), radius: 2, y: 1)
    }
}

/// The round serif "i" that opens an info sheet.
struct InfoButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("i")
                .font(.fraunces(13, 700).italic())
                .foregroundStyle(Color.inkMuted)
                .frame(width: 26, height: 26)
                .overlay(Circle().strokeBorder(Color.inkMuted.opacity(0.45)))
                .frame(width: 36, height: 36)        // bigger tap target
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About \(label)")
    }
}

/// The compact Play / Continue / Solved button on each game card.
struct PlayPill: View {
    enum Kind { case play, resume, solved, done }

    let kind: Kind
    var style: Style = .indigo

    enum Style { case indigo, orange }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(kind == .solved ? Color.success : .white)
            Text(title).font(.jakarta(13, 700))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(fill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var title: String {
        switch kind {
        case .play: style == .orange ? "Start" : "Play"
        case .resume: "Continue"
        case .solved: "Solved"
        case .done: "Review"
        }
    }

    private var icon: String {
        switch kind {
        case .play, .resume: "play.fill"
        case .solved, .done: "checkmark"
        }
    }

    private var fill: Color {
        style == .orange ? .flame : Color(light: 0x1F1B4D, dark: 0x151238)
    }
}

extension PlayPill.Kind {
    /// The pill for a game, from its saved result.
    init(_ result: GameResult?) {
        switch result?.status {
        case .completed: self = (result?.score ?? 0) > 0 ? .solved : .done
        case .inProgress: self = .resume
        default: self = .play
        }
    }
}

/// Title + (i) + Play, the header row of every game card. A nil route
/// means the game isn't in V1 yet: it shows a muted "Soon" pill instead.
struct GameCardHeader: View {
    let title: String
    let kind: PlayPill.Kind
    let onInfo: () -> Void
    let route: TodayRoute?

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.jakarta(20, 800))
                .tracking(-0.3)
                .foregroundStyle(Color.ink)
            Spacer()
            InfoButton(label: title, action: onInfo)
            if let route {
                NavigationLink(value: route) { PlayPill(kind: kind) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(kindLabel) \(title)")
            } else {
                Text("Soon")
                    .font(.jakarta(13, 700))
                    .foregroundStyle(Color.inkMuted)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .accessibilityLabel("\(title) coming soon")
            }
        }
    }

    private var kindLabel: String {
        switch kind {
        case .play: "Play"
        case .resume: "Continue"
        case .solved, .done: "Review"
        }
    }
}

// MARK: - Connections preview

/// 4×4 pills. Solved groups fill whole rows in their colour, in the order
/// they were solved; the rest stay grey.
struct ConnectionsPreview: View {
    let groups: [ConnectionsGroup]
    let solvedGroups: [Int]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { _ in
                        Text("···")
                            .font(.jakarta(10, 800))
                            .tracking(1)
                            .foregroundStyle(color(row: row) == nil ? Color.inkMuted : Color.white.opacity(0.9))
                            .frame(maxWidth: .infinity)
                            .frame(height: 22)
                            .background(color(row: row) ?? Color.segmentTrack,
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(solvedGroups.count) of 4 groups solved")
    }

    private func color(row: Int) -> Color? {
        guard row < solvedGroups.count, solvedGroups[row] < groups.count else { return nil }
        return ConnectionsPalette.color(difficulty: groups[solvedGroups[row]].difficulty)
    }
}

enum ConnectionsPalette {
    /// Difficulty 1 (easiest) … 4 (trickiest).
    static func color(difficulty: Int) -> Color {
        switch difficulty {
        case 1: .sunny
        case 2: .success
        case 3: .aqua
        default: .connPurple
        }
    }
}

// MARK: - Word Guess preview

/// One row of empty tiles, or the latest guess's colours (letters hidden,
/// so the preview never spoils the answer).
struct WordGuessPreview: View {
    let length: Int
    let answer: String
    let guesses: [String]

    var body: some View {
        let feedback = guesses.last.map { GameRules.feedback(guess: $0, answer: answer) }
        HStack(spacing: 6) {
            ForEach(0..<length, id: \.self) { i in
                let result = feedback.flatMap { i < $0.count ? $0[i] : nil }
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(fill(result))
                    .overlay {
                        if result == nil {
                            RoundedRectangle(cornerRadius: 7, style: .continuous).strokeBorder(Color.ink, lineWidth: 2)
                        }
                    }
                    .frame(width: 30, height: 30)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(guesses.isEmpty ? "\(length)-letter word, not started"
                                            : "\(guesses.count) of 6 guesses used")
    }

    private func fill(_ result: GameRules.LetterResult?) -> Color {
        switch result {
        case .correct: .success
        case .present: .sunny
        case .absent: .inkMuted.opacity(0.5)
        case nil: .card
        }
    }
}

// MARK: - Crossword preview

/// The real 5×5 grid shape. White squares turn aqua once it's solved.
struct CrosswordPreview: View {
    let solution: [String]
    let completed: Bool

    var body: some View {
        let black = GameRules.blackSquares(solution)
        let cell: CGFloat = 19
        VStack(spacing: 0) {
            ForEach(black.indices, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(black[r].indices, id: \.self) { c in
                        Rectangle()
                            .fill(black[r][c] ? Color(light: 0x1F1B4D, dark: 0x120F32)
                                              : (completed ? Color.aqua.opacity(0.35) : Color(light: 0xFFFFFF, dark: 0x2A2566)))
                            .frame(width: cell, height: cell)
                            .overlay(Rectangle().strokeBorder(Color(light: 0xD1C9BC, dark: 0x3E3880), lineWidth: 0.5))
                    }
                }
            }
        }
        .overlay(Rectangle().strokeBorder(Color(light: 0xC7C0B2, dark: 0x3E3880)))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(completed ? "Crossword solved" : "5 by 5 crossword")
    }
}

// MARK: - Vocab chips

struct VocabChip: View {
    let term: String
    let isReview: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isReview ? Color.aqua : Color.flame)
                .frame(width: 6, height: 6)
            Text(term).font(.jakarta(13, 700))
        }
        .foregroundStyle(isReview ? Color.chipReviewText : Color.chipNewText)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(isReview ? Color.chipReviewBg : Color.chipNewBg,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder((isReview ? Color.aqua : Color.flame).opacity(0.35))
        }
        .accessibilityLabel("\(term), \(isReview ? "review" : "new")")
    }
}

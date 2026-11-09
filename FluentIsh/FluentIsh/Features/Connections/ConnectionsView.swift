//
//  ConnectionsView.swift
//  FluentIsh
//
//  Created by Jessica Zheng on 11/8/26.
//

import SwiftUI

// MARK: - Chunky "3D" button style (tiles + bottom buttons)

struct ChunkyButtonStyle: ButtonStyle {
    var face: Color
    var edge: Color
    var border: Color? = nil
    var cornerRadius: CGFloat = 14
    var depth: CGFloat = 4
    var dimmed: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
            .background {
                ZStack {
                    // Bottom edge
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(edge)
                        .offset(y: pressed ? 0 : depth)

                    // Face
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(face)

                    if let border {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(border, lineWidth: 1.5)
                    }
                }
            }
            .offset(y: pressed ? depth : 0)
            .padding(.bottom, depth)
            .compositingGroup()
            .opacity(dimmed ? 0.45 : 1)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

// MARK: - Connections View

struct ConnectionsView: View {

    // MARK: - Environment

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    // MARK: - Game State

    @State private var model: ConnectionsModel

    @State private var showInstructions = false
    @State private var message = ""
    @State private var saveError: String?

    // Encouragement toast (wrong guesses) and win celebration
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var showCelebration = false

    @State private var showHint = false
    // MARK: - Initialization

    init(puzzle: ConnectionsPuzzle) {
        _model = State(initialValue: ConnectionsModel(puzzle: puzzle))
    }

    // MARK: - Colors

    private let groupColors: [Color] = [
        .sunny,
        .success,
        .aqua,
        .connPurple
    ]

    // Darker purple used for the bottom edge of selected tiles and Submit
    private let purpleEdge = Color(red: 0.36, green: 0.25, blue: 0.80)

    // Gray-lavender bottom edge used for white tiles and Deselect All
    private let neutralEdge = Color(red: 0.78, green: 0.76, blue: 0.85)

    // Space to keep the bottom buttons clear of the tab bar
    private let tabBarClearance: CGFloat = 84

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 0) {

            header

            Rectangle()
                .fill(Color.hairline)
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 14) {

                    infoRow

                    solvedGroups

                    wordGrid

                    feedbackMessage

                    if model.isFinished {
                        gameResult
                    }

                    if let saveError {
                        Text(saveError)
                            .font(.jakarta(12, 500))
                            .foregroundStyle(Color.coral)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, model.isFinished ? tabBarClearance : 12)
            }

            if !model.isFinished {
                gameButtons
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, tabBarClearance)
                    .background(Color.canvas)
            }
        }
        .background(Color.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showInstructions) {
            instructionsSheet
        }
        .sheet(isPresented: $showHint) {
            hintSheet
        }
        .overlay(alignment: .bottom) {
            if let toast {
                MascotToast(message: toast, onTap: hideToast)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            if showCelebration {
                CelebrationOverlay { showCelebration = false }
            }
        }
    }

    // MARK: - Hint Sheet

    @State private var hintSheetHeight: CGFloat = 260

    private var hintSheet: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack(spacing: 8) {
                Text("!")
                    .font(.jakarta(13, 800))
                    .foregroundStyle(Color.white)
                    .frame(width: 28, height: 28)
                    .background(Color.flame, in: Circle())
                Text("Hint · Connections")
                    .font(.jakarta(16, 700))
                    .foregroundStyle(Color.ink)
            }
            .accessibilityElement(children: .combine)

            Divider().overlay(Color.hairline)

            if let index = model.nextHintGroupIndex {
                let group = model.puzzle.groups[index]

                Text("\(group.category) group: \(group.words.map { $0.uppercased() }.joined(separator: ", ")).")
                    .font(.jakarta(14, 500))
                    .foregroundStyle(Color.ink.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                Button("Auto-Solve Group") {
                    autoSolveHint()
                }
                .buttonStyle(.tactile(.primary, size: .small, fullWidth: true))
            }

            Button("Close") { showHint = false }
                .buttonStyle(.tactile(.outline, size: .small, fullWidth: true))
        }
        .padding(20)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hintSheetHeight = $0 }
        .presentationDetents([.height(hintSheetHeight)])
        .presentationBackground(Color.modal)
    }
    
    private func autoSolveHint() {
        guard let result = model.autoSolveHintGroup() else { return }
        showHint = false

        if result == .won {
            message = "¡Excelente! You found all four groups!"
            showCelebration = true
        } else {
            message = "¡Correcto! Group solved with a hint."
        }
        saveGameInBackground()
    }

    private func saveGameInBackground() {
        Task { await saveGame() }
    }
    // MARK: - Header

    private var header: some View {
        ZStack {

            // Centered title
            Text("Connections")
                .font(.jakarta(17, 800))
                .foregroundStyle(Color.ink)

            HStack {

                // Back
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back")
                            .font(.jakarta(15, 600))
                    }
                    .foregroundStyle(Color.ink.opacity(0.75))
                }
                .accessibilityLabel("Back")

                Spacer()

                // Help + alert buttons
                HStack(spacing: 8) {

                    Button {
                        showInstructions = true
                    } label: {
                        Text("?")
                            .font(.jakarta(14, 800))
                            .foregroundStyle(Color.ink)
                            .frame(width: 32, height: 32)
                            .background(Color.card, in: RoundedRectangle(cornerRadius: 10))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.hairline, lineWidth: 1)
                            }
                    }
                    .accessibilityLabel("How to play")

                    Button {
                        if model.revealHint() {
                            showHint = true
                            saveGameInBackground()   // keep the hint count saved even if they leave
                        }
                    } label: {
                        Text("!")
                            .font(.jakarta(14, 800))
                            .foregroundStyle(Color.flame)
                            .frame(width: 32, height: 32)
                            .background(
                                Color.flame.opacity(0.15),
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(Color.flame.opacity(0.3), lineWidth: 1)
                            }
                    }
                    .disabled(!model.canUseHint)
                    .opacity(model.canUseHint ? 1 : 0.4)
                    .accessibilityLabel("Hint")
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Info Row ("Find groups of 4 words" + mistakes)

    private var infoRow: some View {
        HStack {

            Text("Find groups of 4 words")
                .font(.jakarta(14, 700))
                .foregroundStyle(Color.ink.opacity(0.7))

            Spacer()

            HStack(spacing: 6) {

                Text("Mistakes:")
                    .font(.jakarta(14, 700))
                    .foregroundStyle(Color.inkMuted)

                HStack(spacing: 5) {
                    ForEach(0..<model.maxMistakes, id: \.self) { index in
                        Circle()
                            .fill(
                                index < model.remainingMistakes
                                ? Color.flame
                                : Color.hairline
                            )
                            .frame(width: 9, height: 9)
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Mistakes remaining: \(model.remainingMistakes)")
        }
    }

    // MARK: - Solved Groups

    private var solvedGroups: some View {
        VStack(spacing: 8) {

            ForEach(model.solvedGroupIndices.sorted(), id: \.self) { index in

                let group = model.puzzle.groups[index]

                VStack(spacing: 4) {

                    Text(group.category.uppercased())
                        .font(.jakarta(13, 800))
                        .tracking(0.8)
                        .foregroundStyle(Color.ink)

                    Text(group.words.joined(separator: "  ·  "))
                        .font(.jakarta(12, 600))
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.vertical, 6)
                .background(
                    groupColors[index % groupColors.count],
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: model.solvedGroupIndices)
    }

    // MARK: - Word Grid

    private var wordGrid: some View {

        let columns = Array(
            repeating: GridItem(.flexible(), spacing: 8),
            count: 4
        )

        return LazyVGrid(columns: columns, spacing: 6) {

            ForEach(model.remainingWords, id: \.self) { word in

                let isSelected = model.selectedWords.contains(word)

                Button {
                    model.toggleSelection(word)
                    message = ""
                } label: {
                    Text(word.uppercased())
                        .font(.jakarta(12, 800))
                        .foregroundStyle(isSelected ? Color.white : Color.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(
                    ChunkyButtonStyle(
                        face: isSelected ? Color.connPurple : Color.card,
                        edge: isSelected ? purpleEdge : neutralEdge,
                        border: isSelected ? nil : Color.hairline
                    )
                )
                .disabled(model.isFinished)
                .accessibilityLabel(word)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(.snappy, value: model.remainingWords)
    }

    // MARK: - Feedback

    @ViewBuilder
    private var feedbackMessage: some View {
        if !message.isEmpty {
            Text(message)
                .font(.jakarta(14, 700))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
    }

    // MARK: - Bottom Buttons (Deselect All + Submit)

    private var gameButtons: some View {

        let canDeselect = !model.selectedWords.isEmpty
        let canSubmit = model.selectedWords.count == 4

        return HStack(spacing: 12) {

            Button {
                model.deselectAll()
                message = ""
            } label: {
                Text("Deselect All")
                    .font(.jakarta(15, 800))
                    .foregroundStyle(canDeselect ? Color.ink : Color.inkMuted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(
                ChunkyButtonStyle(
                    face: Color.canvas,
                    edge: neutralEdge,
                    border: Color.hairline,
                    cornerRadius: 16
                )
            )
            .disabled(!canDeselect)

            Button {
                checkAnswer()
            } label: {
                Text("Submit")
                    .font(.jakarta(15, 800))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(
                ChunkyButtonStyle(
                    face: Color.connPurple,
                    edge: purpleEdge,
                    cornerRadius: 16,
                    dimmed: !canSubmit
                )
            )
            .disabled(!canSubmit)
        }
    }

    // MARK: - Toast

    private func showToast(_ text: String) {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.3)) { toast = text }
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.4))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) { toast = nil }
        }
    }

    private func hideToast() {
        toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { toast = nil }
    }

    // MARK: - Check Answer

    private func checkAnswer() {

        let result = model.submitGuess()

        switch result {
        case .correct:
            message = "¡Correcto! You found a group!"
        case .incorrect:
            message = ""
            showToast(Cheers.encouraging.randomElement()!)
        case .oneAway:
            message = ""
            showToast("¡Cerca! Una más · So close! 🎯")
        case .won:
            message = "¡Excelente! You found all four groups!"
            showCelebration = true
        case .gameOver:
            message = "Game over! Better luck next time."
        case .notEnoughSelected:
            message = "Select four words before submitting."
        }

        // Save the current game progress to Firebase.
        Task {
            saveGameInBackground()
        }
    }

    // MARK: - Save Game

    private func saveGame() async {

        let status: GameStatus = model.isFinished ? .completed : .inProgress

        let score: Double? = status == .completed
            ? ProgressRules.connectionsScore(mistakes: model.mistakes)
            : nil

        let result = GameResult(
            status: status,
            score: score,
            mistakes: model.mistakes,
            solvedGroups: model.solvedGroupIndices.sorted(),
            guesses: nil,
            filledCells: nil,
            hintsUsed: model.hintsUsed
        )

        do {
            try await appState.record(
                .game(key: "connections", result: result),
                minutes: model.minutesElapsed
            )
        } catch {
            saveError = "Couldn't save your progress. Please try again."
        }
    }

    // MARK: - Game Result

    private var gameResult: some View {

        VStack(spacing: 12) {

            Text(model.isWon ? "¡Excelente!" : "¡Buen intento!")
                .textStyle(.serifTitle)
                .foregroundStyle(Color.ink)

            Text(
                model.isWon
                ? "You found all four groups!"
                : "You found \(model.solvedGroupIndices.count) of 4 groups."
            )
            .textStyle(.body)
            .foregroundStyle(Color.inkMuted)

            Text("Mistakes: \(model.mistakes)/4")
                .font(.jakarta(14, 700))
                .foregroundStyle(Color.ink)

            if model.isWon {
                let score = ProgressRules.connectionsScore(mistakes: model.mistakes)
                let xp = ProgressRules.gameXP(score: score, hintsUsed: model.hintsUsed)

                Text("+\(xp) XP")
                    .font(.jakarta(16, 800))
                    .foregroundStyle(Color.flame)

                if model.hintsUsed > 0 {
                    Text("Includes −\(ProgressRules.hintPenaltyXP * model.hintsUsed) XP for \(model.hintsUsed) hint\(model.hintsUsed == 1 ? "" : "s").")
                        .font(.jakarta(12, 600))
                        .foregroundStyle(Color.inkMuted)
                }
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.tactile(.primary, size: .large, fullWidth: true))
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Instructions Sheet

    private var instructionsSheet: some View {

        VStack(spacing: 18) {

            Text("How to Play")
                .textStyle(.serifTitle)
                .foregroundStyle(Color.ink)

            Text("Find four groups of four words that share a common connection.")
                .textStyle(.body)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                Label("Select four words that belong together.", systemImage: "square.grid.2x2")
                Label("Submit your answer to check the group.", systemImage: "checkmark.circle")
                Label("You can make up to four mistakes.", systemImage: "heart")
                Label("Find all four groups to win!", systemImage: "trophy")
            }
            .font(.jakarta(14, 600))
            .foregroundStyle(Color.ink)

            Button("Got it!") {
                showInstructions = false
            }
            .buttonStyle(.tactile(.primary, size: .large, fullWidth: true))
        }
        .padding(24)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

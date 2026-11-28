//
//  WordCookiesView.swift
//  FluentIsh
//
//  The Word Cookies screen (docs/plan.md "Word Cookies", step 4). There's no
//  AI Studio design for it; it uses the same pieces as the other games.
//
//  Layout, top to bottom: GameHeaderBar, the slot board (the base word on
//  top, the other words in two columns), the word being spelled, and the
//  pan of letter tiles with round Shuffle / Hint buttons in its bottom
//  corners. When every word is found, an end card replaces the pan.
//  It uses the app's own pieces, not cookie art: the pan is the indigo of
//  the "Play" buttons, and tiles and buttons have the tactile 3D edge.
//  The board never scrolls: it takes whatever height is left and sizes its
//  slots to fit (WordCookiesBoard). A found word's English shows in the word
//  pill (tap the word to see it again), and the end card lists them all.
//  All the rules live in WordCookiesGame; this view only draws its state and
//  forwards drags and taps to it.
//
//  Spelling: one DragGesture covers the whole circle. Dragging over a tile
//  adds it; dragging back onto the previous tile removes the last one;
//  letting go submits the word. With VoiceOver on, each tile is a button
//  instead, plus Submit and Clear buttons.
//
//  Screen text stays language-neutral ("Spell words using these letters"),
//  so a new language only needs a puzzle in the seed, not code.
//
//  Saving: `onSave` is called with the game's GameResult after every found
//  word and every hint: `.inProgress` mid-game, `.completed` once all words
//  are found. TodayDestination passes in the real `appState.record(...)`
//  call. The view doesn't read AppState itself, so the previews work without
//  Firebase. This is the same pattern as WordGuessView, written separately
//  so Word Guess can be deleted later without touching this file.
//

import SwiftUI

struct WordCookiesView: View {
    let puzzle: WordCookiesPuzzle
    /// Saves the game (mid-game or finished); returns what `appState.record`
    /// returns (XP awarded etc., used by the end card). nil in previews.
    var onSave: ((GameResult, _ minutes: Int) async throws -> ActivityOutcome)? = nil

    /// The whole game. @State keeps it alive while the screen is shown.
    @State private var game: WordCookiesGame
    /// Tiles in the word being spelled, in order (positions in `game.tiles`).
    @State private var selection: [Int] = []
    /// Where the finger is during a drag, for the line to it. nil otherwise.
    @State private var dragPoint: CGPoint?
    /// The message under the grid after a submit ("Not on the list" …).
    /// Cleared when the next word starts.
    @State private var feedback: Feedback?
    /// Bumped on a rejected word (in `showRejected`): the shared `.shake(_:)`
    /// helper wiggles the word pill whenever it changes.
    @State private var misses = 0
    /// The letters of a word that was just rejected. They stay in the pill
    /// in coral, shake, then fade out to the message. Empty otherwise.
    @State private var rejected: [String] = []
    /// The row found (or re-found) last, briefly highlighted in the grid.
    @State private var highlighted: String?
    /// How many times each row has flashed (re-spelled or tapped). A row
    /// flashes whenever its own count goes up, so no other row moves.
    @State private var flashes: [String: Int] = [:]
    /// Which "i" / "?" popup is open, if any.
    @State private var assist: AssistMode?
    /// Confetti message when the last word is found; nil hides the overlay.
    @State private var celebration: String?
    /// When the screen opened, for the minutes added to the daily goal.
    @State private var startedAt = Date()
    /// Shown above the grid if saving fails (e.g. offline).
    @State private var saveError: String?
    /// What `record` returned (XP awarded, level up), for the end card.
    @State private var outcome: ActivityOutcome?
    @State private var saving = false
    /// Guards `save()` so the finished game is recorded exactly once. Reset
    /// only if saving fails, so "Retry save" can try again. Starts true for a
    /// finished game that was restored: it's already saved.
    @State private var hasSaved: Bool
    /// Minutes already sent to `record` during this visit. `record` adds up
    /// whatever it's given, so each save only sends the new minutes.
    @State private var minutesRecorded = 0
    /// The latest save. Each save waits for the one before it, so they reach
    /// Firestore in order and an older result can't overwrite a newer one.
    @State private var saveTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    /// Height of the custom tab bar in MainTabView (see WordGuessView for
    /// how it's worked out). The bar stays visible on game screens but its
    /// safe-area inset doesn't reach pushed screens, so leave room for it.
    private let tabBarHeight: CGFloat = 57

    /// Height below the header, measured, so the circle can shrink a little
    /// on short phones and leave the board room.
    @State private var screenHeight: CGFloat = 0
    /// The board's measured size, for working out the slot size.
    @State private var boardSize: CGSize = .zero

    /// Space between the board's edge and its slots.
    private let boardPadding: CGFloat = 14

    /// Circle of tiles: overall size and the size of one tile.
    private var circleSide: CGFloat { WordCookiesBoard.circleSide(forHeight: screenHeight) }
    /// 20% of the circle leaves ~17pt between neighbours with 9 letters, so
    /// dragging to the tile after next doesn't clip the one in between.
    private var tileSide: CGFloat { circleSide * 0.2 }
    /// A drag picks up a tile only this close to its center (70% of its
    /// radius), so passing beside a tile doesn't add it.
    private var hitRadius: CGFloat { tileSide / 2 * 0.7 }

    /// `saved` restores a game started (or finished) earlier today.
    ///
    /// SwiftUI only uses a @State starting value the first time the view
    /// appears, so later calls with a newer `saved` (after each save) don't
    /// reset the game on screen.
    init(puzzle: WordCookiesPuzzle, saved: GameResult? = nil,
         onSave: ((GameResult, _ minutes: Int) async throws -> ActivityOutcome)? = nil) {
        self.puzzle = puzzle
        self.onSave = onSave
        let game = WordCookiesGame(puzzle: puzzle, restoring: saved)
        _game = State(initialValue: game)
        _hasSaved = State(initialValue: game.isOver)
    }

    var body: some View {
        VStack(spacing: 12) {
            if let saveError {
                Text(saveError).textStyle(.body).foregroundStyle(Color.coral)
            }
            // The board takes the height the rest doesn't use.
            slotBoard

            if game.isOver {
                endCard
            } else {
                wordPill
                playArea
                if voiceOverEnabled { voiceOverButtons }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12 + tabBarHeight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { screenHeight = $0 }
        .background(Color.canvas)
        .safeAreaInset(edge: .top, spacing: 0) {
            GameHeaderBar(title: "Word Cookies",
                          subtitle: "\(game.foundWords.count) of \(game.rows.count) words",
                          onHowToPlay: { assist = .howToPlay },
                          onHint: game.isOver ? nil : { assist = .hint })
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $assist) { mode in
            AssistSheet(mode: mode, game: game, onRevealLetter: revealLetter)
        }
        .overlay {
            if let celebration {
                CelebrationOverlay(message: celebration) { self.celebration = nil }
            }
        }
    }

    // MARK: Slot board

    /// A card laid out like the real Word Cookies: the base word centered on
    /// top, the other words in two columns below (left column against the
    /// left edge, right column against the right). It fills the height it's
    /// given, and the slots are sized so everything fits inside it.
    private var slotBoard: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        let arrangement = WordCookiesBoard.arrange(rowCount: game.rows.count, top: baseRowIndex)
        let inside = CGSize(width: boardSize.width - 2 * boardPadding,
                            height: boardSize.height - 2 * boardPadding)
        let side = WordCookiesBoard.slotSide(for: arrangement, lengths: game.rows.map(\.word.count), in: inside)
        return VStack(spacing: WordCookiesBoard.rowGap) {
            if let top = arrangement.top {
                slotRow(top, side: side)
            }
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: WordCookiesBoard.rowGap) {
                    ForEach(arrangement.left, id: \.self) { slotRow($0, side: side) }
                }
                Spacer(minLength: WordCookiesBoard.columnGap)
                VStack(alignment: .trailing, spacing: WordCookiesBoard.rowGap) {
                    ForEach(arrangement.right, id: \.self) { slotRow($0, side: side) }
                }
            }
        }
        .padding(boardPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.card, in: shape)
        .overlay(shape.strokeBorder(Color.hairline))
        .onGeometryChange(for: CGSize.self) { $0.size } action: { boardSize = $0 }
    }

    /// Row `index` of `game.rows`. A found word can be tapped to see its
    /// English again (VoiceOver already reads it in the row's label).
    private func slotRow(_ index: Int, side: CGFloat) -> some View {
        let row = game.rows[index]
        let found = game.isFound(row.word)
        return SlotRow(row: row,
                       found: found,
                       revealed: game.revealedIndices(in: row.word),
                       highlighted: highlighted == row.word,
                       flashes: flashes[row.word, default: 0],
                       side: side)
            .onTapGesture { if found { showMeaning(of: row) } }
    }

    /// Shows a found word's English in the word pill, like when it was found.
    /// Not while spelling (the pill shows the letters then) or once the game
    /// is over (the end card lists every meaning).
    private func showMeaning(of row: WordCookiesGame.Row) {
        guard selection.isEmpty, !game.isOver else { return }
        Haptics.tap()
        highlighted = row.word
        flashes[row.word, default: 0] += 1
        feedback = .found(row.display, en: row.en)
    }

    // MARK: Word being spelled

    /// The letters being spelled (as small flame tiles), a rejected word (in
    /// coral, shaking), or the result of the last word, or a prompt. A fixed
    /// height so the circle doesn't jump.
    private var wordPill: some View {
        Group {
            if !selection.isEmpty {
                let letters = selection.map { game.tiles[$0] }
                letterChips(letters, face: .flame, edge: .flameEdge)
                    .animation(.spring(duration: 0.2), value: selection)
                    .accessibilityLabel("Spelling \(letters.joined())")
            } else if !rejected.isEmpty {
                letterChips(rejected, face: .coral, edge: Self.coralEdge)
                    .transition(.opacity)
                    .accessibilityHidden(true)      // VoiceOver hears the message instead
            } else {
                messagePill
                    .transition(.opacity)
            }
        }
        // On the whole pill, not the coral chips: they appear in the same
        // update that bumps `misses`, so they'd never see it change.
        .shake(misses)
    }

    /// A row of small tactile letter chips, centered in the pill's height.
    private func letterChips(_ letters: [String], face: Color, edge: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(letters.enumerated()), id: \.offset) { _, letter in
                TactileDisc(shape: RoundedRectangle(cornerRadius: 8, style: .continuous),
                            face: face, edge: edge, depth: 3) {
                    Text(letter)
                        .font(.jakarta(16, 800))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 30, height: 30)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 36)
        .accessibilityElement(children: .ignore)
    }

    /// Shows a rejected word's letters in coral while they shake, then fades
    /// them out to the message. A newer miss restarts this, so the older
    /// task leaves the letters alone.
    private func showRejected(_ letters: [String]) {
        rejected = letters
        misses += 1
        let miss = misses
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard misses == miss, !rejected.isEmpty else { return }
            withAnimation(.easeOut(duration: 0.25)) { rejected = [] }
        }
    }

    /// The pill's text: the last word's result or the prompt.
    private var messagePill: some View {
        let text: String
        let color: Color
        if let feedback {
            text = feedback.message
            color = feedback.color
        } else {
            text = "Spell words using these letters"
            color = .inkMuted
        }
        return Text(text)
            .font(.jakarta(15, 800))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
    }

    // MARK: Play area

    /// The pan of tiles, with Shuffle in the bottom-left corner and Hint in
    /// the bottom-right, like the real game. The buttons sit in the corners
    /// of the pan's square, outside the circle itself.
    private var playArea: some View {
        ZStack(alignment: .bottom) {
            tileCircle
            HStack(alignment: .bottom) {
                Button {
                    selection = []
                    withAnimation(.spring(duration: 0.3)) { game.shuffle() }
                } label: {
                    Image(systemName: "shuffle")
                }
                .buttonStyle(RoundTactileButtonStyle(kind: .plain))
                .accessibilityLabel("Shuffle letters")

                Spacer(minLength: 0)

                Button {
                    assist = .hint
                } label: {
                    Image(systemName: "lightbulb.fill")
                }
                .buttonStyle(RoundTactileButtonStyle(kind: .hint))
                .overlay(alignment: .topTrailing) { hintBadge }
                .accessibilityLabel("Hint, \(hintsLeft) of \(WordCookiesGame.maxHints) left")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var hintsLeft: Int { max(0, WordCookiesGame.maxHints - game.hintsUsed) }

    /// How many hints are left, on the Hint button's corner.
    private var hintBadge: some View {
        Text("\(hintsLeft)")
            .font(.jakarta(11, 800))
            .foregroundStyle(Color.white)
            .frame(width: 20, height: 20)
            .background(hintsLeft > 0 ? Color.flame : Color.inkMuted, in: Circle())
            .overlay(Circle().strokeBorder(Color.canvas, lineWidth: 2))
            .offset(x: 4, y: -4)
            .accessibilityHidden(true)
    }

    // MARK: Tile circle

    /// How far the pan's darker edge shows below it.
    private let panDepth: CGFloat = 6

    private var tileCircle: some View {
        ZStack {
            // The pan: same colours as the indigo "Play" buttons, with the
            // darker edge peeking out below, and a faint inner rim.
            Circle()
                .fill(Self.panEdge)
                .offset(y: panDepth)
            Circle()
                .fill(Self.panFace)
            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 2)
                .padding(10)

            // The line through the selected tiles, then on to the finger.
            Path { path in
                let points = selection.map(center(of:)) + (dragPoint.map { [$0] } ?? [])
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() { path.addLine(to: point) }
            }
            .stroke(Color.flame.opacity(0.85),
                    style: StrokeStyle(lineWidth: tileSide * 0.22, lineCap: .round, lineJoin: .round))

            ForEach(game.tiles.indices, id: \.self) { index in
                LetterTile(letter: game.tiles[index], selected: selection.contains(index), side: tileSide)
                    .position(center(of: index))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(game.tiles[index])
                    .accessibilityValue(selection.contains(index) ? "selected" : "")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { toggle(index) }
            }
        }
        .frame(width: circleSide, height: circleSide)
        .padding(.bottom, panDepth)          // room for the pan's edge
        .contentShape(Circle())
        // One gesture for the whole circle, so a single drag can pass over
        // many tiles. minimumDistance 0 starts it as soon as a finger lands.
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { dragChanged(to: $0.location) }
                .onEnded { _ in dragEnded() }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Letter tiles")
    }

    /// Where tile `index` sits: evenly round the circle, the first at the top.
    private func center(of index: Int) -> CGPoint {
        let count = max(1, game.tiles.count)
        let radius = (circleSide - tileSide) / 2 - 4
        let angle = 2 * Double.pi * Double(index) / Double(count) - Double.pi / 2
        return CGPoint(x: circleSide / 2 + radius * cos(angle),
                       y: circleSide / 2 + radius * sin(angle))
    }

    /// The tile under `point`, if any.
    private func tileIndex(at point: CGPoint) -> Int? {
        game.tiles.indices.first { index in
            let c = center(of: index)
            return hypot(point.x - c.x, point.y - c.y) <= hitRadius
        }
    }

    private func dragChanged(to point: CGPoint) {
        guard !game.isOver else { return }
        if selection.isEmpty { feedback = nil; rejected = [] }
        dragPoint = point
        guard let index = tileIndex(at: point), selection.last != index else { return }
        if selection.count >= 2, selection[selection.count - 2] == index {
            // Back onto the previous tile: undo the last letter.
            selection.removeLast()
            Haptics.tap()
        } else if !selection.contains(index) {
            selection.append(index)
            Haptics.tap()
        }
    }

    private func dragEnded() {
        dragPoint = nil
        // A lone tap isn't a word attempt: just let it go.
        if selection.count < 2 {
            selection = []
            return
        }
        submitSelection()
    }

    /// VoiceOver: activating a tile adds it, or removes it if it's the last one.
    private func toggle(_ index: Int) {
        guard !game.isOver else { return }
        if selection.isEmpty { feedback = nil; rejected = [] }
        if selection.last == index {
            selection.removeLast()
        } else if !selection.contains(index) {
            selection.append(index)
        }
    }

    /// Sends the spelled word to the game and reacts to the answer.
    private func submitSelection() {
        let tiles = selection
        let word = game.spelled(tiles)
        let letters = tiles.map { game.tiles[$0] }
        selection = []
        switch game.submit(tiles) {
        case .found:
            Haptics.success()
            highlighted = word
            let row = game.rows.first { $0.word == word }
            feedback = .found(row?.display ?? word, en: row?.en ?? "")
            if game.isComplete {
                celebration = "All words found!"
            }
            // Every found word saves: .inProgress mid-game, .completed at the end.
            save()
        case .alreadyFound:
            Haptics.warning()
            highlighted = word
            flashes[word, default: 0] += 1      // show which row it is
            feedback = .alreadyFound
        case .notInList:
            Haptics.error()
            feedback = .notInList
            showRejected(letters)
        case .tooShort:
            Haptics.error()
            feedback = .tooShort
            showRejected(letters)
        case .ignored:
            break
        }
    }

    // MARK: Buttons

    /// VoiceOver can't drag across tiles, so it gets explicit buttons.
    private var voiceOverButtons: some View {
        HStack(spacing: 8) {
            Button("Clear") { selection = [] }
                .buttonStyle(.tactile(.outline, size: .small, fullWidth: true))
            Button("Submit", action: submitSelection)
                .buttonStyle(.tactile(.primary, size: .small, fullWidth: true))
                .disabled(selection.isEmpty)
        }
    }

    /// The pan's colours: the indigo "Play" button (`.tactile(.secondary)`).
    private static let panFace = Color(light: 0x1F1B4D, dark: 0x292461)
    private static let panEdge = Color(light: 0x120F32, dark: 0x1A1646)
    /// Darker edge under the coral chips of a rejected word.
    private static let coralEdge = Color(hex: 0xD63A4B)

    // MARK: Hints

    /// The hint popup's button: reveal one letter, save (so the hint is kept
    /// and paid for if the player leaves), then close the popup.
    private func revealLetter() {
        if let cell = game.nextHintCell, game.revealHint() {
            Haptics.tap()
            highlighted = cell.word
            save()
        }
        assist = nil
    }

    // MARK: Saving

    /// Saves the game as it is right now: `.inProgress` mid-game, or
    /// `.completed` once it's over (only once, see `hasSaved`).
    private func save() {
        guard let onSave else { return }
        let isFinal = game.isOver
        if isFinal {
            guard !hasSaved else { return }
            hasSaved = true
            saving = true
            saveError = nil
        }
        // Copy what to save now, before the player changes the game again.
        let result = game.result()
        let minutes = WordCookiesGame.minutesToRecord(secondsOnScreen: Date().timeIntervalSince(startedAt),
                                                      alreadyRecorded: minutesRecorded)
        minutesRecorded += minutes
        let previous = saveTask
        saveTask = Task {
            // Wait for the previous save so the saves arrive in order.
            await previous?.value
            do {
                let saved = try await onSave(result, minutes)
                if isFinal { outcome = saved }
                saveError = nil
            } catch {
                minutesRecorded -= minutes          // not saved, so the next save sends them
                if isFinal {
                    saveError = "Couldn't save your game: \(error.localizedDescription)"
                    hasSaved = false                // let "Retry save" try again
                    Haptics.error()
                } else if !game.isOver {
                    saveError = "Couldn't save your progress: \(error.localizedDescription)"
                }
            }
            if isFinal { saving = false }
        }
    }

    // MARK: End card

    /// Where the base word is in `game.rows`: the row with the puzzle's
    /// baseWordId, else the last (longest) row. It goes on top of the board.
    private var baseRowIndex: Int? {
        game.rows.firstIndex { $0.wordId == puzzle.baseWordId } ?? game.rows.indices.last
    }

    private var baseRow: WordCookiesGame.Row? {
        baseRowIndex.map { game.rows[$0] }
    }

    private var endCard: some View {
        EndCard(
            baseWord: baseRow?.display ?? "",
            meaning: baseRow?.en ?? "",
            otherWords: game.rows.enumerated().filter { $0.offset != baseRowIndex }.map(\.element),
            wordsFound: game.foundWords.count,
            wordCount: game.rows.count,
            hintsUsed: game.hintsUsed,
            outcome: outcome,
            // Reopened after finishing: no record call this visit, so show
            // the XP worked out from the saved result instead.
            restoredXP: outcome == nil && hasSaved && !saving ? game.xpEarned : nil,
            saving: saving,
            canSave: onSave != nil,
            saveFailed: saveError != nil,
            onRetry: save,
            onDone: { dismiss() })
    }
}

// MARK: - Feedback

/// What happened to the last word, shown in the word pill.
private enum Feedback: Equatable {
    case found(String, en: String)  // as written + English, e.g. "área", "area"
    case alreadyFound
    case notInList
    case tooShort

    var message: String {
        switch self {
        case .found(let word, let en): en.isEmpty ? "Found \(word)!" : "\(word): \(en)"
        case .alreadyFound: "Already found"
        case .notInList: "Not on the list"
        case .tooShort: "Words need \(WordCookiesGame.minWordLength)+ letters"
        }
    }

    var color: Color {
        switch self {
        case .found: .successEdge
        case .alreadyFound: .inkMuted
        case .notInList, .tooShort: .coral
        }
    }
}

// MARK: - Hint and how-to-play popup

/// Which popup "i" or "?" opened. Identifiable so `.sheet(item:)` can use it.
private enum AssistMode: String, Identifiable {
    case howToPlay, hint
    var id: String { rawValue }
}

/// Same look as Word Guess's popup: a round "i" or "?" badge, a title, the
/// content and an outlined Close, sized to its content.
private struct AssistSheet: View {
    let mode: AssistMode
    let game: WordCookiesGame
    let onRevealLetter: () -> Void

    @Environment(\.dismiss) private var dismiss
    /// Measured content height, so the sheet is only as tall as it needs.
    @State private var height: CGFloat = 320

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider().overlay(Color.hairline)
            switch mode {
            case .howToPlay: steps
            case .hint: hintBody
            }
            Button("Close") { dismiss() }
                .buttonStyle(.tactile(.outline, size: .small, fullWidth: true))
        }
        .padding(20)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .presentationDetents([.height(height)])
        .presentationBackground(Color.modal)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: mode == .hint ? "questionmark" : "info")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(mode == .hint ? Color.white : Color.offWhite)
                .frame(width: 28, height: 28)
                .background(mode == .hint ? Color.flame : Color.indigo, in: Circle())
            Text("\(mode == .hint ? "Hint" : "How to Play") · Word Cookies")
                .font(.jakarta(16, 700))
                .foregroundStyle(Color.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private var steps: some View {
        let lines = [
            "Drag across the letters to spell a word, then let go. Each letter can be used once per word.",
            "The board shows how many words there are and how long each is. Today's deck word is on top.",
            "When you find a word, its English shows above the letters. Tap a found word to see it again.",
            "Accents don't matter: á counts as A. Letters like Ñ have their own tile.",
            "The bottom-left button shuffles the letters. The lightbulb (or \"?\") reveals one letter for \(ProgressRules.hintPenaltyXP) XP, up to \(WordCookiesGame.maxHints) times.",
        ]
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.jakarta(11, 800))
                        .foregroundStyle(Color.flame)
                        .frame(width: 20, height: 20)
                        .background(Color.flame.opacity(0.15), in: Circle())
                    Text(line)
                        .font(.jakarta(13, 500))
                        .foregroundStyle(Color.ink.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var hintBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reveal one letter of a word you haven't found yet. Each hint costs \(ProgressRules.hintPenaltyXP) XP from this game's reward. A hint never gives away a whole word.")
                .font(.jakarta(13, 500))
                .foregroundStyle(Color.ink.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Text("Hints used: \(game.hintsUsed)/\(WordCookiesGame.maxHints)"
                 + (game.hintsUsed > 0 ? " (−\(ProgressRules.hintPenaltyXP * game.hintsUsed) XP)" : ""))
                .font(.jakarta(12, 600))
                .foregroundStyle(Color.inkMuted)

            Button("Reveal a letter (−\(ProgressRules.hintPenaltyXP) XP)", action: onRevealLetter)
                .buttonStyle(.tactile(.primary, size: .small, fullWidth: true))
                .disabled(!game.canUseHint)

            if !game.canUseHint {
                Text(reasonNoHint)
                    .font(.jakarta(12, 600))
                    .foregroundStyle(Color.inkMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var reasonNoHint: String {
        if game.isOver { return "The game is over." }
        if game.hintsUsed >= WordCookiesGame.maxHints { return "You've used all \(WordCookiesGame.maxHints) hints." }
        return "Every word left is one letter away. Those are yours!"
    }
}

// MARK: - Pieces

/// One row of the board: a slot per letter, centered. `side` comes from
/// WordCookiesBoard.slotSide, so every row fits on the board.
private struct SlotRow: View {
    let row: WordCookiesGame.Row
    let found: Bool
    let revealed: Set<Int>
    let highlighted: Bool
    /// Goes up each time this row should flash (see `flashes` in the view).
    let flashes: Int
    let side: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The flash: brightness blinks twice while the row bounces once.
    private struct Flash {
        var glow = 0.0
        var scale = 1.0
    }

    var body: some View {
        HStack(spacing: WordCookiesBoard.slotGap) {
            ForEach(Array(row.word.enumerated()), id: \.offset) { index, letter in
                SlotCell(letter: letter, index: index, found: found,
                         revealed: revealed.contains(index), side: side)
            }
        }
        .keyframeAnimator(initialValue: Flash(), trigger: flashes) { content, flash in
            content
                .brightness(flash.glow)
                .scaleEffect(flash.scale)
        } keyframes: { _ in
            KeyframeTrack(\.glow) {
                LinearKeyframe(0.25, duration: 0.1)
                LinearKeyframe(0, duration: 0.12)
                LinearKeyframe(0.25, duration: 0.1)
                LinearKeyframe(0, duration: 0.2)
            }
            // Brightness isn't motion, so only the bounce goes with Reduce Motion.
            KeyframeTrack(\.scale) {
                SpringKeyframe(reduceMotion ? 1 : 1.08, duration: 0.15, spring: .snappy)
                SpringKeyframe(1, duration: 0.35, spring: .bouncy)
            }
        }
        .scaleEffect(highlighted && found ? 1.04 : 1)
        .animation(.spring(duration: 0.25), value: found)
        .animation(.spring(duration: 0.25), value: highlighted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    /// e.g. "5 letters, found: tarea, homework" or "4 letters, hint: A at 1".
    private var accessibilityText: String {
        let length = "\(row.word.count) letters"
        if found { return "\(length), found: \(row.display), \(row.en)" }
        let letters = Array(row.word)
        let hints = revealed.sorted().map { "\(letters[$0]) at \($0 + 1)" }
        return hints.isEmpty ? "\(length), not found" : "\(length), hint: " + hints.joined(separator: ", ")
    }
}

/// One slot of a row. When its word is found it turns green and pops, a
/// little after the slot to its left, so the word fills in left to right.
/// A hinted letter pops on its own when it's revealed. A game restored as
/// already found starts green and doesn't animate.
private struct SlotCell: View {
    let letter: Character
    let index: Int
    let found: Bool
    let revealed: Bool
    let side: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Time between one slot popping and the next.
    private let stagger = 0.06

    /// 0 empty, 1 hinted, 2 found. The pop runs whenever this goes up, so a
    /// hinted slot pops again with the rest when its word is found.
    private var stage: Int { found ? 2 : (revealed ? 1 : 0) }

    /// Only a found word waits its turn; a hint pops straight away.
    private var delay: Double { found && !reduceMotion ? Double(index) * stagger : 0 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: side * 0.24, style: .continuous)
        Text(found || revealed ? String(letter) : "")
            .font(.jakarta(side * 0.5, 800))
            .foregroundStyle(found ? Color.indigo : Color.flame)
            .frame(width: side, height: side)
            .background(found ? Color.success : Color.raised, in: shape)
            .overlay(shape.strokeBorder(found ? Color.successEdge : Color.ink.opacity(revealed ? 0 : 0.08)))
            .overlay(shape.strokeBorder(Color.flame.opacity(revealed && !found ? 0.5 : 0), lineWidth: 1.5))
            // The colour and letter change at this slot's turn, not all at once.
            .animation(.easeOut(duration: 0.15).delay(delay), value: stage)
            .keyframeAnimator(initialValue: 1.0, trigger: stage) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                // Wait for this slot's turn, grow, then spring back. The wait
                // is never exactly 0: a 0-second keyframe makes the scale NaN
                // and the slot disappears (the builder doesn't allow `if`).
                KeyframeTrack {
                    LinearKeyframe(1.0, duration: max(delay, 0.001))
                    SpringKeyframe(reduceMotion ? 1.0 : 1.22, duration: 0.12, spring: .snappy)
                    SpringKeyframe(1.0, duration: 0.3, spring: .bouncy)
                }
            }
    }
}

/// One round letter tile in the pan, chunky like the tactile buttons:
/// off-white with a grey edge, flame orange while it's part of the word
/// being spelled.
private struct LetterTile: View {
    let letter: String
    let selected: Bool
    let side: CGFloat

    var body: some View {
        TactileDisc(shape: Circle(),
                    face: selected ? .flame : .offWhite,
                    edge: selected ? .flameEdge : Color(hex: 0xB9B6C8),
                    depth: 4) {
            Text(letter)
                .font(.jakarta(side * 0.46, 800))
                .foregroundStyle(selected ? Color.white : Color.indigo)
                .contentTransition(.opacity)
        }
        .frame(width: side, height: side)
        .scaleEffect(selected ? 1.1 : 1)
        .animation(.spring(duration: 0.15), value: selected)
    }
}

/// A face with a darker edge peeking out below it: the same 3D look as
/// TactileButtonStyle, for things that aren't buttons (tiles, letter chips).
/// The edge fits inside the frame, so the face is `depth` shorter.
private struct TactileDisc<S: Shape, Content: View>: View {
    let shape: S
    let face: Color
    let edge: Color
    let depth: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(face, in: shape)
            .padding(.bottom, depth)
            .background(alignment: .bottom) {
                shape.fill(edge).padding(.top, depth)
            }
    }
}

/// Round 52pt icon button for the pan's corners, pressed in like
/// TactileButtonStyle: the face slides down onto its darker edge.
private struct RoundTactileButtonStyle: ButtonStyle {
    enum Kind {
        case plain   // card face, grey edge: Shuffle
        case hint    // yellow, like the yellow tactile button
    }

    let kind: Kind

    func makeBody(configuration: Configuration) -> some View {
        RoundTactileButtonBody(configuration: configuration, kind: kind)
    }
}

/// A separate View so it can read the environment, like TactileButtonBody.
private struct RoundTactileButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: RoundTactileButtonStyle.Kind

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    private let side: CGFloat = 52
    private let depth: CGFloat = 4
    private var pressed: Bool { configuration.isPressed && isEnabled }

    var body: some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(colors.text)
            .frame(width: side, height: side - depth)
            .background(colors.face, in: Circle())
            .background { Circle().fill(colors.edge).offset(y: pressed ? 0 : depth) }
            .offset(y: pressed ? depth : 0)
            .padding(.bottom, depth)
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(Circle())
            .animation(.easeOut(duration: 0.1), value: pressed)
            .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, isDown in isDown }
    }

    private var colors: (face: Color, edge: Color, text: Color) {
        switch kind {
        case .plain:
            colorScheme == .dark ? (.card, Color.white.opacity(0.3), .offWhite)
                                 : (.card, Color(hex: 0xB9B6C8), .indigo)
        case .hint:
            (.sunny, .sunnyEdge, .indigo)
        }
    }
}

/// Shown in place of the circle when every word is found: the base word
/// (with audio) and its meaning, the other words with their English, words
/// found, hints, and the XP that `record` actually awarded.
private struct EndCard: View {
    let baseWord: String
    let meaning: String
    /// Every word except the base word, in board order, for the meanings list.
    let otherWords: [WordCookiesGame.Row]
    let wordsFound: Int
    let wordCount: Int
    let hintsUsed: Int
    /// nil until saving finishes (or in previews, where nothing is saved).
    let outcome: ActivityOutcome?
    /// XP for a finished game reopened later (WordCookiesGame.xpEarned).
    let restoredXP: Int?
    let saving: Bool
    let canSave: Bool
    let saveFailed: Bool
    let onRetry: () -> Void
    let onDone: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                MascotView(mood: .celebrating, size: .sm)
                VStack(alignment: .leading, spacing: 4) {
                    Text("All words found!")
                        .textStyle(.serifCard)
                        .foregroundStyle(Color.ink)
                    HStack(spacing: 8) {
                        Text(baseWord)
                            .font(.jakarta(15, 800))
                            .foregroundStyle(Color.ink)
                        AudioButton(text: baseWord)
                    }
                    Text(meaning)
                        .font(.jakarta(13, 500))
                        .foregroundStyle(Color.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if !otherWords.isEmpty {
                wordList
            }

            HStack(spacing: 8) {
                StatBox(label: "Words", value: Text("\(wordsFound)/\(wordCount)"))
                StatBox(label: "Hints", value: Text("\(hintsUsed)/\(WordCookiesGame.maxHints)"))
                StatBox(label: "XP", value: xpText, loading: saving)
            }

            ForEach(notes, id: \.self) { note in
                Text(note)
                    .font(.jakarta(12, 600))
                    .foregroundStyle(Color.inkMuted)
            }

            if let outcome, outcome.leveledUp {
                Text("Level up! You're now \(outcome.level.name)")
                    .font(.jakarta(12, 800))
                    .foregroundStyle(Color.connPurple)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color.connPurple.opacity(0.12), in: Capsule())
            }

            if saveFailed {
                Button("Retry save", action: onRetry)
                    .buttonStyle(.tactile(.outline, size: .small, fullWidth: true))
            }
            Button("Back to Today", action: onDone)
                .buttonStyle(.tactile(.primary, fullWidth: true))
        }
        .padding(16)
        .background(Color.card, in: shape)
        .overlay(shape.strokeBorder(Color.hairline))
    }

    /// "área  area" for each other word: one line each, the Spanish in bold.
    private var wordList: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(otherWords, id: \.word) { row in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(row.display)
                        .font(.jakarta(13, 800))
                        .foregroundStyle(Color.ink)
                    Text(row.en)
                        .font(.jakarta(13, 500))
                        .foregroundStyle(Color.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    /// The real XP from `record`, the worked-out XP for a reopened game,
    /// or a dash when there's nothing saved.
    private var xpText: Text {
        if let outcome { return Text("+\(outcome.xpAwarded)") }
        if let restoredXP { return Text("+\(restoredXP)") }
        return Text(canSave && !saveFailed ? "…" : "–")
    }

    /// Small explanations under the stats, only when they apply.
    private var notes: [String] {
        var lines: [String] = []
        if hintsUsed > 0 {
            lines.append("Includes −\(ProgressRules.hintPenaltyXP * hintsUsed) XP for \(hintsUsed) hint\(hintsUsed == 1 ? "" : "s").")
        }
        // record gives 0 XP if Word Cookies was already finished today.
        if let outcome, outcome.xpAwarded == 0,
           ProgressRules.gameXP(score: ProgressRules.wordCookiesScore(), hintsUsed: hintsUsed) > 0 {
            lines.append("Already finished today, so no XP this time.")
        }
        return lines
    }
}

/// One stat in the end card: a big value over a small label.
private struct StatBox: View {
    let label: String
    let value: Text
    var loading = false

    var body: some View {
        VStack(spacing: 2) {
            if loading {
                ProgressView().frame(height: 22)
            } else {
                value
                    .font(.jakarta(17, 800))
                    .foregroundStyle(Color.ink)
                    .contentTransition(.numericText())
            }
            Text(label.uppercased())
                .textStyle(.caption)
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.raised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews (sample data lives here only; the app passes in today's puzzle)

/// Sunday's puzzle from the seed.
private let samplePuzzle = WordCookiesPuzzle(
    baseWordId: "w_regatear", letters: "REGATEAR",
    words: [
        WordCookiesWord(word: "área", en: "area"),
        WordCookiesWord(word: "arte", en: "art"),
        WordCookiesWord(word: "rata", en: "rat"),
        WordCookiesWord(word: "tarea", en: "homework, task"),
        WordCookiesWord(word: "tragar", en: "to swallow"),
        WordCookiesWord(word: "regatear", en: "to haggle", wordId: "w_regatear"),
    ])

#Preview("New game") {
    WordCookiesView(puzzle: samplePuzzle)
}

#Preview("Halfway, one hint") {
    WordCookiesView(puzzle: samplePuzzle, saved: GameResult(
        status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
        guesses: nil, filledCells: nil, hintsUsed: 1,
        foundWords: ["AREA", "RATA", "TAREA"], revealedLetters: ["ARTE:0"]))
}

#Preview("Finished") {
    WordCookiesView(puzzle: samplePuzzle, saved: GameResult(
        status: .completed, score: 1, mistakes: nil, solvedGroups: nil,
        guesses: nil, filledCells: nil, hintsUsed: 1,
        foundWords: ["AREA", "ARTE", "RATA", "TAREA", "TRAGAR", "REGATEAR"],
        revealedLetters: ["ARTE:0"]))
}

#Preview("Dark mode") {
    WordCookiesView(puzzle: samplePuzzle, saved: GameResult(
        status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
        guesses: nil, filledCells: nil, hintsUsed: 0,
        foundWords: ["ARTE", "TRAGAR"], revealedLetters: []))
        .preferredColorScheme(.dark)
}

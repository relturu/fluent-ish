//
//  WordGuessView.swift
//  FluentIsh
//
//  Ported from design/ai-studio/src/pages/GamesAndExercises.tsx
//  (Word Guess, lines 682–908). Screenshot: docs/design_screenshots/
//  word-guess-1-playing.png.
//
//  Layout, top to bottom: GameHeaderBar, the clue line, the board (6 rows ×
//  word length), the Spanish QWERTY keyboard (with Ñ and ⌫), and a
//  full-width Submit button.
//  All the rules live in WordGuessGame; this view only draws its state and
//  forwards key presses to it.
//
//  What changed from the prototype, and why (docs/porting-guide.md §2):
//  - The board starts empty and has 6 rows, not 5 pre-filled ones.
//  - Word length comes from the puzzle instead of a hard-coded 6.
//  - Colours come from GameRules.feedback, which counts repeated letters
//    properly (the prototype's `TARGET_WORD.includes(letter)` doesn't).
//  - No "Solve CHARLA" link or button. "!" opens a hint popup that reveals
//    one letter for 5 XP instead (rules in WordGuessGame).
//  - No audio button during play (it would say the answer out loud). The
//    end card has one, using the app's on-device AudioButton.
//  - The prototype's "Continue to Review" goes to Session Review (Sean's
//    screen). Here the end card shows the score and XP in place, with
//    "Back to Today".
//  - Every `darkMode ? … : …` is gone: the colour tokens switch by themselves.
//  - No ENTER key: its label didn't fit in the third row. A full-width
//    Submit button under the keyboard does the same job, and stays
//    disabled until the row is full.
//
//  Saving: `onSave` is called with the game's GameResult after every guess
//  and every hint: `.inProgress` mid-game, `.completed` once it's won or
//  lost. TodayDestination passes in the real `appState.record(...)` call.
//  The view doesn't read AppState itself, so the previews work without
//  Firebase. Mid-game saves are safe: `record` gives 0 XP and doesn't touch
//  the streak or "games done" until the status is `.completed`.
//
//  Restoring: TodayDestination passes today's saved result as `saved`
//  (from appState.todayLog). WordGuessGame rebuilds the guesses and hints
//  from it, so leaving and coming back continues the same game, and a
//  finished game reopens on its end card.
//

import SwiftUI

struct WordGuessView: View {
    let puzzle: WordGuessPuzzle
    /// Saves the game (mid-game or finished); returns what `appState.record`
    /// returns (XP awarded etc., used by the end card). nil in previews.
    var onSave: ((GameResult, _ minutes: Int) async throws -> ActivityOutcome)? = nil

    /// The whole game. @State keeps it alive while the screen is shown;
    /// changing it (typing, Submit) redraws the board.
    @State private var game: WordGuessGame
    /// One shake counter per board row. A rejected Submit bumps only the
    /// current row's counter, and the shared `.shake(_:)` helper wiggles a
    /// row whenever its counter changes. Counters never go down, so a row
    /// can't wiggle by accident later (e.g. when it stops being the
    /// current row after an accepted guess).
    @State private var rowShakes = Array(repeating: 0, count: WordGuessGame.maxGuesses)
    /// When the screen opened, for the minutes added to the daily goal.
    @State private var startedAt = Date()
    /// Shown under the clue if saving fails (e.g. offline).
    @State private var saveError: String?
    /// Which "?" / "!" popup is open, if any.
    @State private var assist: AssistMode?
    /// Confetti message after a win; nil hides the overlay.
    @State private var celebration: String?
    /// What `record` returned (XP awarded, level up), for the end card.
    @State private var outcome: ActivityOutcome?
    @State private var saving = false
    /// Guards `save()` so the finished game is recorded exactly once, not on
    /// every redraw. Reset only if saving fails, so "Retry" can try again.
    /// Starts true for a finished game that was restored: it's already saved.
    @State private var hasSaved: Bool
    /// Minutes already sent to `record` during this visit. `record` adds up
    /// whatever it's given, so each save only sends the new minutes.
    @State private var minutesRecorded = 0
    /// The latest save. Each save waits for the one before it, so they
    /// reach Firestore in order and an older result can't overwrite a newer one.
    @State private var saveTask: Task<Void, Never>?

    @Environment(\.dismiss) private var dismiss
    /// Height of the custom tab bar in MainTabView. Update this if the tab bar changes.
    /// The bar stays visible on game screens (as in the screenshot), but its
    /// safe-area inset doesn't reach screens pushed inside a NavigationStack,
    /// so the keyboard has to leave this much room itself.
    /// From TabBar's layout: indicator 3 + spacing 5 + icon 24 + spacing 5
    /// + label line height 15.1 (Plus Jakarta Sans at 12pt) + bottom padding 4
    /// = 56.1pt, rounded up. In previews (no tab bar) this just adds space.
    private let tabBarHeight: CGFloat = 57

    /// `saved` restores a game started (or finished) earlier today.
    ///
    /// SwiftUI only uses a @State starting value the first time the view
    /// appears. Every save updates appState.todayLog, which makes
    /// TodayDestination call this init again with the new `saved`, but the
    /// game already on screen is kept, so nothing resets mid-play.
    init(puzzle: WordGuessPuzzle, saved: GameResult? = nil,
         onSave: ((GameResult, _ minutes: Int) async throws -> ActivityOutcome)? = nil) {
        self.puzzle = puzzle
        self.onSave = onSave
        let game = WordGuessGame(answer: puzzle.answer, length: puzzle.length, restoring: saved)
        // A @State property can't be set directly in init, so we set its
        // starting value through the underscore-prefixed storage.
        _game = State(initialValue: game)
        _hasSaved = State(initialValue: game.isOver)
    }

    var body: some View {
        VStack(spacing: 12) {
            clueLine
            if let saveError {
                Text(saveError).textStyle(.body).foregroundStyle(Color.coral)
            }
            // The board gets all the height the clue and keyboard don't use.
            // GeometryReader tells us that space, so the tiles can shrink to
            // fit a small phone. Because it fills the space, it also pushes
            // the keyboard down to the bottom.
            GeometryReader { space in
                board(tileSide: tileSide(fitting: space.size))
                    .frame(maxWidth: .infinity)         // centred left-right, top-aligned
            }
            // When the game ends, the result card replaces the keyboard
            // and the Submit button.
            if game.isOver {
                endCard
            } else {
                keyboard
            }
        }
        .padding(.horizontal, 16)                       // px-4
        .padding(.top, 16)
        .padding(.bottom, 12 + tabBarHeight)            // keep the keyboard above the tab bar
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.canvas)
        .safeAreaInset(edge: .top, spacing: 0) {
            // GameHeaderBar's own slots: "?" = how to play, "!" = hint
            // (hidden once the game is over, when hints no longer apply).
            GameHeaderBar(title: "Word Guess",
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

    // MARK: Clue

    /// "Clue: …" from the puzzle's English meaning (text-[12px] font-bold opacity-70).
    private var clueLine: some View {
        Text("Clue: \(puzzle.definitionEn)")
            .font(.jakarta(12, 700))
            .foregroundStyle(Color.inkMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)                    // px-1
    }

    // MARK: Board

    private static let tileGap: CGFloat = 6             // gap-1.5 / space-y-1.5

    /// Tiles are 44pt (h-11) when there's room. They shrink so that all
    /// `length` columns fit the width and all 6 rows fit the height left
    /// over, whichever is tighter (small phones, long words).
    private func tileSide(fitting space: CGSize) -> CGFloat {
        let columns = CGFloat(max(1, puzzle.length))
        let rows = CGFloat(WordGuessGame.maxGuesses)
        let byWidth = (space.width - Self.tileGap * (columns - 1)) / columns
        let byHeight = (space.height - Self.tileGap * (rows - 1)) / rows
        return max(0, min(44, byWidth, byHeight).rounded(.down))
    }

    private func board(tileSide: CGFloat) -> some View {
        VStack(spacing: Self.tileGap) {
            ForEach(0..<WordGuessGame.maxGuesses, id: \.self) { row in
                HStack(spacing: Self.tileGap) {
                    ForEach(0..<puzzle.length, id: \.self) { column in
                        LetterTile(letter: letter(row: row, column: column),
                                   state: tileState(row: row, column: column),
                                   side: tileSide)
                    }
                }
                // Each row reads its own counter (see `rowShakes`). Only the
                // row being typed ever has its counter bumped. The shared
                // helper skips the wiggle when Reduce Motion is on.
                .shake(rowShakes[row])
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(row: row))
            }
        }
    }

    /// The letter to show in one tile: a submitted guess, the row being
    /// typed, or nothing.
    private func letter(row: Int, column: Int) -> Character? {
        let word: String
        if row < game.guesses.count {
            word = game.guesses[row]
        } else if row == game.guesses.count {
            word = game.current
        } else {
            return nil
        }
        let letters = Array(word)
        return column < letters.count ? letters[column] : nil
    }

    private func tileState(row: Int, column: Int) -> LetterTile.State {
        if row < game.guesses.count {
            let feedback = game.feedback(for: game.guesses[row])
            return column < feedback.count ? .scored(feedback[column]) : .empty
        }
        if letter(row: row, column: column) != nil { return .typed }
        // A letter revealed by a hint shows faded in the row being typed.
        // It's only a guide: it isn't typed for you, and a typed letter
        // covers it (the branch above wins).
        if row == game.guesses.count, !game.isOver,
           column < game.revealedLetters.count, let hint = game.revealedLetters[column] {
            return .hint(hint)
        }
        return .empty
    }

    /// VoiceOver reads a whole row at once, e.g.
    /// "Guess 1: C correct, A in the word, M not in the word…".
    private func accessibilityLabel(row: Int) -> String {
        if row < game.guesses.count {
            let guess = game.guesses[row]
            let parts = zip(guess, game.feedback(for: guess)).map { letter, result in
                switch result {
                case .correct: "\(letter) correct"
                case .present: "\(letter) in the word"
                case .absent: "\(letter) not in the word"
                }
            }
            return "Guess \(row + 1): " + parts.joined(separator: ", ")
        }
        if row == game.guesses.count, !game.isOver {
            let typed = game.current.isEmpty ? "empty" : game.current.map(String.init).joined(separator: " ")
            let hints = game.revealedPositions.sorted().compactMap { position in
                game.revealedLetters[position].map { "\($0) in position \(position + 1)" }
            }
            return "Typing: \(typed)" + (hints.isEmpty ? "" : ". Hints: " + hints.joined(separator: ", "))
        }
        return "Guess \(row + 1): empty"
    }

    // MARK: Keyboard

    private enum Key: Hashable {
        case letter(String)
        case delete
    }

    /// Spanish QWERTY: Ñ sits where it does on a Spanish keyboard, after L.
    /// The third row has no ENTER key (the Submit button below replaces it).
    /// Letter keys use `maxWidth: .infinity`, so Z–M share out the space
    /// ENTER used to take and ⌫ keeps its own width at the end.
    private static let rows: [[Key]] = [
        "QWERTYUIOP".map { .letter(String($0)) },
        "ASDFGHJKLÑ".map { .letter(String($0)) },
        "ZXCVBNM".map { .letter(String($0)) } + [.delete],
    ]

    /// The 3 key rows, then the full-width Submit button.
    ///
    /// Height (fixed): 3 rows × 38 + 2 gaps × 6 = 126pt of keys,
    /// + 10 gap + 46 Submit = 182pt. The board's GeometryReader takes
    /// whatever height is left, so adding Submit just makes the tiles a bit
    /// smaller on short screens. Nothing scrolls.
    private var keyboard: some View {
        VStack(spacing: 10) {
            VStack(spacing: 6) {                        // space-y-1.5
                ForEach(Self.rows, id: \.self) { row in
                    HStack(spacing: 4) {                // gap-1
                        ForEach(row, id: \.self) { key in
                            keyButton(key)
                        }
                    }
                }
            }

            // Disabled until the row has every letter. TactileButtonStyle
            // reads `isEnabled` and fades the button to 40%, so the player
            // can see it isn't ready yet.
            Button("Submit", action: submitGuess)
                .buttonStyle(.tactile(.primary, fullWidth: true))
                .disabled(!game.canSubmit)
                .accessibilityLabel("Submit guess")
                .accessibilityHint(game.canSubmit ? "" : "Type all \(puzzle.length) letters first")
        }
        .disabled(game.isOver)
    }

    @ViewBuilder
    private func keyButton(_ key: Key) -> some View {
        switch key {
        case .letter(let letter):
            Button(letter) { press(key) }
                .buttonStyle(KeyboardKeyStyle())
        case .delete:
            Button { press(key) } label: {
                Image(systemName: "delete.left").font(.system(size: 15, weight: .bold))
            }
            .buttonStyle(.tactile(.yellow, size: .small))
            .accessibilityLabel("Delete letter")
        }
    }

    /// Sends one key to the game. The game decides what's allowed, so
    /// this only adds feedback (haptics, shake).
    private func press(_ key: Key) {
        switch key {
        case .letter(let letter):
            if game.type(letter) { Haptics.tap() }
        case .delete:
            game.deleteLast()
        }
    }

    /// The Submit button: exactly what the old ENTER key did.
    private func submitGuess() {
        switch game.submit() {
        case .tooShort:
            // The button is disabled until the row is full, so this
            // shouldn't happen. It's kept as a safety net: if it ever does,
            // the player still gets the shake instead of nothing.
            Haptics.error()
            // The row that was rejected is the one being typed, whose index
            // is the number of guesses already made. The bounds check is
            // just to be safe; a rejected row is always on the board.
            let row = game.guesses.count
            if rowShakes.indices.contains(row) { rowShakes[row] += 1 }
        case .accepted:
            if game.isWon {
                Haptics.success()
                celebration = "¡Palabra encontrada!"
            } else if game.isLost {
                Haptics.warning()
            }
            // Every accepted guess saves: .inProgress mid-game, .completed
            // when this guess ended it.
            save()
        case .gameOver:
            break
        }
    }

    /// Saves the game as it is right now: `.inProgress` mid-game, or
    /// `.completed` once it's over (only once, see `hasSaved`). A Task is
    /// needed because saving is async (it waits for Firestore) but a button
    /// action isn't.
    private func save() {
        guard let onSave else { return }
        let isFinal = game.isOver
        if isFinal {
            guard !hasSaved else { return }
            hasSaved = true
            saving = true
            saveError = nil                         // the end card only reflects this save
        }
        // Copy what to save now, before the player changes the game again.
        let result = game.result()
        let minutes = WordGuessGame.minutesToRecord(secondsOnScreen: Date().timeIntervalSince(startedAt),
                                                    alreadyRecorded: minutesRecorded)
        // Count the minutes as sent straight away, so a save started while
        // this one is still running doesn't send them again.
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
                    // Mid-game: the next guess or hint saves everything
                    // again. Skipped if the game has ended since, because
                    // then the end card shows the final save's result instead.
                    saveError = "Couldn't save your progress: \(error.localizedDescription)"
                }
            }
            if isFinal { saving = false }
        }
    }

    /// The hint popup's button: reveal one letter, save (so the hint is
    /// kept and paid for if the player leaves), then close the popup (as the
    /// prototype does after applying a hint).
    private func revealLetter() {
        if game.useHint() {
            Haptics.tap()
            save()
        }
        assist = nil
    }

    // MARK: End card

    private var endCard: some View {
        EndCard(
            // A score above 0 only comes from solving it, so this also
            // covers a game saved as completed earlier.
            won: game.isWon || game.score > 0,
            word: puzzle.answer,
            meaning: puzzle.definitionEn,
            guessesUsed: game.guesses.count,
            score: game.score,
            hintsUsed: game.hintsUsed,
            outcome: outcome,
            // Reopened after finishing: no record call this visit, so
            // show the XP worked out from the saved result instead.
            restoredXP: outcome == nil && hasSaved && !saving ? game.xpEarned : nil,
            saving: saving,
            canSave: onSave != nil,
            saveFailed: saveError != nil,
            onRetry: save,
            onDone: { dismiss() })
    }
}

// MARK: - Hint and how-to-play popup

/// Which popup "?" or "!" opened. Identifiable so `.sheet(item:)` can use it.
private enum AssistMode: String, Identifiable {
    case howToPlay, hint
    var id: String { rawValue }
}

/// Ported from GameAssistModal (HiFiElements.tsx ~line 920): a round "?" or
/// "!" badge with a title, the content, an orange action and an outlined
/// Close. Shown as a native sheet sized to its content, like InfoSheet.
/// Unlike the prototype there's no "Solve" button: a hint reveals one letter.
private struct AssistSheet: View {
    let mode: AssistMode
    let game: WordGuessGame
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
            Text(mode == .hint ? "!" : "?")
                .font(.jakarta(13, 800))
                .foregroundStyle(mode == .hint ? Color.white : Color.offWhite)
                .frame(width: 28, height: 28)
                .background(mode == .hint ? Color.flame : Color.indigo, in: Circle())
            Text("\(mode == .hint ? "Hint" : "How to Play") · Palabra del Día")
                .font(.jakarta(16, 700))
                .foregroundStyle(Color.ink)
        }
        .accessibilityElement(children: .combine)
    }

    private var steps: some View {
        let lines = [
            "Guess the \(game.length)-letter Spanish word in \(WordGuessGame.maxGuesses) tries.",
            "Green = right letter, right spot. Yellow = in the word, wrong spot. Grey = not in the word.",
            "You don't need accents: á counts as a. Ñ is its own letter.",
            "Stuck? \"!\" reveals one letter in its spot for \(ProgressRules.hintPenaltyXP) XP.",
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
            Text("Reveal one letter of today's word in its correct spot. Each hint costs \(ProgressRules.hintPenaltyXP) XP from this game's reward.")
                .font(.jakarta(13, 500))
                .foregroundStyle(Color.ink.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            if game.hintsUsed > 0 {
                // e.g. "C _ _ _ _ _", plus how many hints were taken.
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.revealedLetters.map { $0.map(String.init) ?? "_" }.joined(separator: " "))
                        .font(.jakarta(18, 800))
                        .foregroundStyle(Color.flame)
                        .accessibilityLabel("Revealed so far: " + revealedDescription)
                    Text("Hints used: \(game.hintsUsed) (−\(ProgressRules.hintPenaltyXP * game.hintsUsed) XP)")
                        .font(.jakarta(12, 600))
                        .foregroundStyle(Color.inkMuted)
                }
            }

            Button("Reveal a letter (−\(ProgressRules.hintPenaltyXP) XP)", action: onRevealLetter)
                .buttonStyle(.tactile(.primary, size: .small, fullWidth: true))
                .disabled(!game.canUseHint)

            if !game.canUseHint {
                Text(game.isOver ? "The game is over." : "Only one letter is left to find. That one's yours!")
                    .font(.jakarta(12, 600))
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }

    /// For VoiceOver: "C in position 1, H in position 2".
    private var revealedDescription: String {
        game.revealedPositions.sorted().compactMap { position in
            game.revealedLetters[position].map { "\($0) in position \(position + 1)" }
        }.joined(separator: ", ")
    }
}

// MARK: - Pieces

/// One square on the board (h-11 rounded-xl text-[17px] font-extrabold).
private struct LetterTile: View {
    enum State: Equatable {
        case empty                              // nothing typed yet
        case typed                              // typed, not submitted
        case hint(Character)                    // revealed by a hint, not typed: faded
        case scored(GameRules.LetterResult)     // submitted: green / yellow / grey
    }

    let letter: Character?
    let state: State
    let side: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        Text(shownLetter.map(String.init) ?? "")
            .font(.jakarta(17, 800))
            .foregroundStyle(colors.text)
            .frame(width: side, height: side)
            .background(colors.fill, in: shape)
            .overlay(shape.strokeBorder(colors.border, lineWidth: 2))      // border-2
            // A small pop when a letter is typed into the tile.
            .scaleEffect(state == .typed ? 1.04 : 1)
            .animation(.spring(duration: 0.15), value: state)
    }

    /// A typed or guessed letter, or else the faded hint letter.
    private var shownLetter: Character? {
        if case .hint(let hint) = state { return hint }
        return letter
    }

    /// Green and yellow use fixed dark text (`indigo`) because their fills
    /// are bright in both light and dark mode, as in the prototype.
    private var colors: (fill: Color, border: Color, text: Color) {
        switch state {
        case .empty:              (.card, Color.ink.opacity(0.15), .ink)
        case .typed:              (.card, Color.ink.opacity(0.4), .ink)
        case .hint:               (.card, Color.flame.opacity(0.35), Color.flame.opacity(0.55))
        case .scored(.correct):   (.success, .successEdge, .indigo)
        case .scored(.present):   (.sunny, .sunnyEdge, .indigo)
        case .scored(.absent):    (Color.ink.opacity(0.1), Color.ink.opacity(0.05), Color.ink.opacity(0.4))
        }
    }
}

/// Shown in place of the keyboard when the game ends. The same card for a
/// win and a loss: the word (with audio) and its meaning, the score from
/// ProgressRules.wordGuessScore, and the XP that `record` actually awarded.
private struct EndCard: View {
    let won: Bool
    let word: String
    let meaning: String
    let guessesUsed: Int
    let score: Double
    let hintsUsed: Int
    /// nil until saving finishes (or in previews, where nothing is saved).
    let outcome: ActivityOutcome?
    /// XP for a finished game reopened later (WordGuessGame.xpEarned).
    /// Used only when there's no `outcome` from this visit.
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
                MascotView(mood: won ? .celebrating : .encouraging, size: .sm)
                VStack(alignment: .leading, spacing: 4) {
                    Text(won ? "¡Palabra encontrada!" : "¡Casi! So close")
                        .textStyle(.serifCard)
                        .foregroundStyle(Color.ink)
                    HStack(spacing: 8) {
                        Text(won ? word : "The word was \(word)")
                            .font(.jakarta(15, 800))
                            .foregroundStyle(Color.ink)
                        // On-device Spanish speech (Components/AudioButton).
                        // Lowercase, so the voice says the word instead of
                        // spelling out capitals.
                        AudioButton(text: word.lowercased())
                    }
                    Text(meaning)
                        .font(.jakarta(13, 500))
                        .foregroundStyle(Color.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                StatBox(label: "Score", value: Text("\(Int((score * 100).rounded()))%"))
                StatBox(label: "Guesses", value: Text("\(guessesUsed)/\(WordGuessGame.maxGuesses)"))
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
        // record gives 0 XP if Word Guess was already finished today.
        if let outcome, outcome.xpAwarded == 0,
           ProgressRules.gameXP(score: score, hintsUsed: hintsUsed) > 0 {
            lines.append("Already finished today, so no XP this time.")
        }
        if !won { lines.append("A new word tomorrow.") }
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

/// A white letter key with a darker 2pt bottom edge, pushed in when pressed
/// (h-10 rounded-xl border-b-2). Same idea as the shared `.tactile` style,
/// which has no card-coloured variant at this size.
private struct KeyboardKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        let depth: CGFloat = 2
        configuration.label
            .font(.jakarta(12, 800))
            .foregroundStyle(Color.ink)
            .frame(maxWidth: .infinity)                 // flex-1
            .frame(height: 38 - depth)                  // same height as .tactile(size: .small)
            .background(Color.card, in: shape)
            .overlay(shape.strokeBorder(Color.ink.opacity(0.1)))
            .background { shape.fill(Color.ink.opacity(0.2)).offset(y: configuration.isPressed ? 0 : depth) }
            .offset(y: configuration.isPressed ? depth : 0)
            .padding(.bottom, depth)
            .contentShape(Rectangle())
    }
}

// MARK: - Previews (sample data lives here only; the app passes in today's puzzle)

private let samplePuzzle = WordGuessPuzzle(answer: "CHARLA", length: 6, definitionEn: "a chat, a talk")

#Preview("Empty board") {
    WordGuessView(puzzle: samplePuzzle)
}

#Preview("Two guesses (like the screenshot)") {
    WordGuessView(puzzle: samplePuzzle, saved: GameResult(
        status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
        guesses: ["CAMINO", "CORTAR"], filledCells: nil, hintsUsed: 0))
}

#Preview("Won with a hint") {
    WordGuessView(puzzle: samplePuzzle, saved: GameResult(
        status: .completed, score: 5.0 / 6, mistakes: nil, solvedGroups: nil,
        guesses: ["CAMINO", "CHARLA"], filledCells: nil, hintsUsed: 1))
}

#Preview("Lost") {
    WordGuessView(puzzle: samplePuzzle, saved: GameResult(
        status: .completed, score: 0, mistakes: nil, solvedGroups: nil,
        guesses: ["CAMINO", "CORTAR", "CERCAR", "CANTAR", "CHARCO", "CHARLO"],
        filledCells: nil, hintsUsed: 0))
}

#Preview("Dark mode") {
    WordGuessView(puzzle: samplePuzzle, saved: GameResult(
        status: .inProgress, score: nil, mistakes: nil, solvedGroups: nil,
        guesses: ["CAMINO", "CORTAR"], filledCells: nil, hintsUsed: 0))
        .preferredColorScheme(.dark)
}

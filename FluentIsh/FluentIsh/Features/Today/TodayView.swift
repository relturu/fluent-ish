//
//  TodayView.swift
//  FluentIsh
//
//  Today tab (screenshots 12.11.08 / 12.11.14): greeting, Daily Vocab card,
//  Today's Games with live previews, Skill Exercises. Content comes from
//  TodayModel; progress (solved games, lesson done, 0/3) comes live from
//  `appState.todayLog`, so finishing a game updates this screen by itself.
//
//  Play / Start push filler screens until teammates build the real ones
//  (TodayDestination below). The Mini Crossword is V2: its card shows the
//  grid with a "Soon" pill, and the counter is x/2.
//
//  DEBUG: `-todaySheet vocab|connections|wordGuess|crossword|fillBlank|level`
//  opens a sheet at launch; `-todayOpen vocab|connections|wordGuess|exercise`
//  opens a filler screen (for screenshots).
//

import SwiftUI

struct TodayView: View {
    @Environment(AppState.self) private var appState
    @State private var model = TodayModel()
    @AppStorage("exerciseDifficulty") private var difficulty = "medium"

    @State private var info: InfoContent?
    @State private var showLevel = false
    @State private var pushed: TodayRoute?

    var body: some View {
        TabPage(title: "Today", spacing: 14) {
            HStack(spacing: 14) {
                LevelPill(flag: "🇪🇸", level: appState.level.name) { showLevel = true }
                AppStreakIndicator()
            }
        } content: {
            if let error = appState.errorMessage {
                Text(error).textStyle(.body).foregroundStyle(Color.coral)
            }
            greeting
            switch model.phase {
            case .loading:
                loadingCard
            case .failed(let message):
                failedCard(message)
            case .loaded:
                vocabCard
                gamesSection
                exercisesSection
            }
        }
        .navigationDestination(for: TodayRoute.self) { TodayDestination(route: $0, puzzle: model.puzzle) }
        .navigationDestination(item: $pushed) { TodayDestination(route: $0, puzzle: model.puzzle) }
        .sheet(item: $info) { content in
            InfoSheet(content: content) { route in pushed = route }
        }
        .sheet(isPresented: $showLevel) {
            LevelProgressSheet(flag: "🇪🇸", level: appState.level)
        }
        .task(id: appState.uid) { await load() }
        .onAppear(perform: openDebugSheet)
    }

    private func load() async {
        guard let uid = appState.uid else { return }
        await model.load(uid: uid, language: appState.language, today: appState.today, service: appState.service)
    }

    private var log: DailyLog? { appState.todayLog }

    // MARK: Greeting

    private var greeting: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                SpeechBubble(text: ChurroGreetings.forDay(appState.today), maxWidth: 140, fontSize: 12)
                MascotView(mood: .waving, size: .sm)
            }
            .frame(width: 140)
            Text(appState.firstName.isEmpty ? "¡Hola!" : "¡Hola, \(appState.firstName)!")
                .textStyle(.serifHero)
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
            Spacer(minLength: 0)
        }
    }

    // MARK: Daily Vocab

    private var vocabDone: Bool { log?.vocabCompleted ?? false }

    private var vocabCard: some View {
        TodayCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily Vocab").textStyle(.serifCard).foregroundStyle(Color.ink)
                    Text("\(model.lesson?.title ?? "Today") · \(model.deck.count) words")
                        .font(.jakarta(13, 500))
                        .foregroundStyle(Color.inkMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(vocabDone ? "✓ Done" : "+\(ProgressRules.vocabLessonXP) XP")
                        .font(.jakarta(12, 800))
                        .foregroundStyle(vocabDone ? Color.success : Color.flame)
                    HStack(spacing: 2) {
                        InfoButton(label: "Daily Vocab") { info = TodayInfo.vocab(model) }
                        NavigationLink(value: TodayRoute.vocab) {
                            PlayPill(kind: vocabDone ? .done : .play, style: .orange)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(vocabDone ? "Review Daily Vocab" : "Start Daily Vocab")
                    }
                }
            }
            VocabChipRow(deck: model.deck)
        }
    }

    // MARK: Today's Games

    private var gamesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("TODAY'S GAMES").textStyle(.caption).foregroundStyle(Color.inkMuted)
                Spacer()
                Text("\(V1Games.completed(in: log))/\(V1Games.keys.count)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.inkMuted)
                    .accessibilityLabel("\(V1Games.completed(in: log)) of \(V1Games.keys.count) games done")
            }
            .padding(.top, 6)

            if let puzzle = model.puzzle {
                let games = log?.games ?? [:]
                TodayCard {
                    GameCardHeader(title: "Connections", kind: .init(games["connections"]),
                                   onInfo: { info = TodayInfo.connections }, route: .connections)
                    ConnectionsPreview(groups: puzzle.connections.groups,
                                       solvedGroups: games["connections"]?.solvedGroups ?? [])
                }
                TodayCard {
                    GameCardHeader(title: "Word Guess", kind: .init(games["wordGuess"]),
                                   onInfo: { info = TodayInfo.wordGuess(puzzle) }, route: .wordGuess)
                    WordGuessPreview(length: puzzle.wordGuess.length, answer: puzzle.wordGuess.answer,
                                     guesses: games["wordGuess"]?.guesses ?? [])
                }
                TodayCard {
                    GameCardHeader(title: "Mini Crossword", kind: .init(games["crossword"]),
                                   onInfo: { info = TodayInfo.crossword }, route: nil)
                    CrosswordPreview(solution: puzzle.crossword.solution,
                                     completed: games["crossword"]?.status == .completed)
                        .padding(.bottom, 4)
                }
            }
        }
    }

    // MARK: Skill Exercises

    private static let exerciseTypes = [
        ("fillBlank", "Fill in the Blank"),
        ("sentenceBuilder", "Sentence Builder"),
        ("definitionMatch", "Definition Match"),
    ]

    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                // The title wraps to two lines on narrow phones, as in the mockup;
                // the picker always keeps its full width.
                Text("Skill Exercises").textStyle(.serifTitle).foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                DifficultyPicker(selection: $difficulty)
                    .fixedSize()
            }
            .padding(.top, 10)

            VStack(spacing: 0) {
                ForEach(Array(Self.exerciseTypes.enumerated()), id: \.offset) { index, item in
                    if index > 0 { Divider().overlay(Color.hairline) }
                    exerciseRow(type: item.0, title: item.1)
                }
            }
            .background(Color.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Color.hairline))
        }
    }

    @ViewBuilder
    private func exerciseRow(type: String, title: String) -> some View {
        let exercise = model.exercise(type: type, difficulty: difficulty)
        let done = exercise.flatMap(\.id).map { log?.exercisesCompleted.contains($0) ?? false } ?? false
        HStack {
            NavigationLink(value: TodayRoute.exercise(id: exercise?.id ?? type)) {
                HStack(spacing: 8) {
                    Text(title).font(.jakarta(16, 700)).foregroundStyle(Color.ink)
                    if done {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.success)
                            .accessibilityLabel("done today")
                    }
                    Spacer()
                }
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(exercise == nil)

            Button {
                info = TodayInfo.exercise(type: type, title: title, exercise: exercise)
            } label: {
                HStack(spacing: 3) {
                    Text("About")
                    Image(systemName: "arrow.up.right").font(.system(size: 11, weight: .semibold))
                }
                .font(.jakarta(14, 500))
                .foregroundStyle(Color.inkMuted)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About \(title)")
        }
        .padding(.horizontal, 18)
    }

    // MARK: Loading and errors

    private var loadingCard: some View {
        TodayCard {
            HStack(spacing: 12) {
                ProgressView()
                Text("Loading today's lesson…").textStyle(.body).foregroundStyle(Color.inkMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private func failedCard(_ message: String) -> some View {
        TodayCard {
            VStack(spacing: 12) {
                MascotView(mood: .thinking, size: .md)
                Text(message).textStyle(.body).foregroundStyle(Color.ink).multilineTextAlignment(.center)
                Button("Try again") { Task { await load() } }
                    .buttonStyle(.tactile(.primary, size: .small))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func openDebugSheet() {
        #if DEBUG
        switch UserDefaults.standard.string(forKey: "todayOpen") {
        case "vocab": pushed = .vocab
        case "connections": pushed = .connections
        case "wordGuess": pushed = .wordGuess
        case "exercise": pushed = .exercise(id: "fillBlank")
        default: break
        }
        switch UserDefaults.standard.string(forKey: "todaySheet") {
        case "level": showLevel = true
        case "connections": info = TodayInfo.connections
        case "crossword": info = TodayInfo.crossword
        case "fillBlank": info = TodayInfo.exercise(type: "fillBlank", title: "Fill in the Blank", exercise: nil)
        case "vocab", "wordGuess":
            // Needs loaded content; wait for it.
            Task {
                while model.phase == .loading { try? await Task.sleep(for: .milliseconds(200)) }
                if UserDefaults.standard.string(forKey: "todaySheet") == "vocab" {
                    info = TodayInfo.vocab(model)
                } else if let puzzle = model.puzzle {
                    info = TodayInfo.wordGuess(puzzle)
                }
            }
        default: break
        }
        #endif
    }
}

// MARK: - Pieces

/// Review (aqua) and new (orange) words, scrolling sideways. The chevron
/// jumps three chips along and wraps back to the start.
private struct VocabChipRow: View {
    let deck: [TodayModel.DeckWord]
    @State private var position: String?

    var body: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(deck) { VocabChip(term: $0.word.term, isReview: $0.isReview).id($0.id) }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollPosition(id: $position, anchor: .leading)

            Button(action: advance) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.inkMuted)
                    .frame(width: 28, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More words")
        }
    }

    private func advance() {
        guard !deck.isEmpty else { return }
        let current = deck.firstIndex { $0.id == position } ?? 0
        let next = current + 3 < deck.count ? current + 3 : 0
        withAnimation(.easeInOut) { position = deck[next].id }
    }
}

/// Easy · Medium · Hard, orange when selected.
private struct DifficultyPicker: View {
    @Binding var selection: String

    var body: some View {
        HStack(spacing: 2) {
            ForEach(["easy", "medium", "hard"], id: \.self) { level in
                let active = selection == level
                Button {
                    Haptics.tap()
                    withAnimation(.spring(duration: 0.25)) { selection = level }
                } label: {
                    Text(level.capitalized)
                        .font(.jakarta(13, active ? 700 : 600))
                        .foregroundStyle(active ? Color.white : Color.ink.opacity(0.7))
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background {
                            if active { RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.flame) }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.segmentTrack, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Where Play / Start goes: a filler screen naming the teammate who builds
/// it. Each test action is the exact `record` call the real screen should
/// make when the player finishes.
struct TodayDestination: View {
    let route: TodayRoute
    let puzzle: DailyPuzzle?

    @Environment(AppState.self) private var appState

    var body: some View {
        switch route {
        case .vocab:
            FillerScreen(title: "Daily Vocab", owner: "Sean", mood: .encouraging,
                         summary: "Flip cards and list view for today's 70/30 deck, with pronunciation. Finishing calls service.completeVocabLesson(...) with one answer per card.") {
                try await appState.record(.vocab(score: 1), minutes: 3)
            }
        case .connections:
            FillerScreen(title: "Connections", owner: "Jessica", mood: .thinking,
                         summary: "Find the four groups of four. Score with ProgressRules.connectionsScore(mistakes:); save partial progress with record(.game(...)) as status .inProgress.") {
                try await appState.record(.game(key: "connections", result: GameResult(
                    status: .completed, score: ProgressRules.connectionsScore(mistakes: 0), mistakes: 0,
                    solvedGroups: [0, 1, 2, 3], guesses: nil, filledCells: nil, hintsUsed: nil)), minutes: 3)
            }
        case .wordGuess:
            FillerScreen(title: "Word Guess", owner: "Sai", mood: .quest,
                         summary: "Six tries at today's word. Colour each guess with GameRules.feedback(guess:answer:); score with ProgressRules.wordGuessScore.") {
                let answer = puzzle?.wordGuess.answer ?? "PRECIO"
                return try await appState.record(.game(key: "wordGuess", result: GameResult(
                    status: .completed, score: ProgressRules.wordGuessScore(guessesUsed: 1, solved: true),
                    mistakes: nil, solvedGroups: nil, guesses: [answer], filledCells: nil, hintsUsed: nil)), minutes: 2)
            }
        case .exercise(let id):
            FillerScreen(title: "Skill Exercise", owner: "Arielle", mood: .proud,
                         summary: "Fill in the Blank, Sentence Builder and Definition Match, from the exercises collection. Finishing calls record(.exercise(id:)).") {
                try await appState.record(.exercise(id: id), minutes: 2)
            }
        }
    }
}

// MARK: - Info sheet copy

/// From the prototype, with the XP numbers changed to plan.md's rules.
enum TodayInfo {
    static func vocab(_ model: TodayModel) -> InfoContent {
        let reviews = model.deck.filter(\.isReview).count
        return InfoContent(
            id: "vocab", badge: "Retention model", title: "Daily Vocab (70/30 Mix)",
            subtitle: "\(model.lesson?.title ?? "Today") · \(model.deck.count) words · \(reviews) review, \(model.deck.count - reviews) new",
            description: "Fluent•ish mixes about 70% words you've seen before, due for spaced-repetition review, with 30% new words, so you keep what you learned while steadily adding more.",
            tip: "Aqua chips are reviews, orange chips are new. Flip through the cards or see the whole list, and tap the speaker to hear each word.",
            reward: "+\(ProgressRules.vocabLessonXP) XP", actionLabel: "Start Lesson", route: .vocab)
    }

    static let connections = InfoContent(
        id: "connections", badge: "Pattern puzzle", title: "Connections (Conexiones)",
        subtitle: "4 groups · 16 words",
        description: "Find four groups of four Spanish words that share a thread: a theme, a grammar pattern or an idiom. Four mistakes ends the game.",
        tip: "Categories range from food and drink to false friends (falsos amigos) and set phrases. Watch for words that seem to fit two groups.",
        reward: "Up to +\(ProgressRules.gameMaxXP) XP, about −7 per mistake", actionLabel: "Play Connections", route: .connections)

    static func wordGuess(_ puzzle: DailyPuzzle) -> InfoContent {
        InfoContent(
            id: "wordGuess", badge: "Wordle style", title: "Word Guess (Palabra del Día)",
            subtitle: "\(puzzle.wordGuess.length) letters · 6 attempts",
            description: "Guess today's \(puzzle.wordGuess.length)-letter Spanish word. After each guess, green means right letter in the right spot, yellow means it's in the word but somewhere else.",
            tip: "You don't need to type accents: á, é, í, ó and ú count as plain vowels. Ñ is its own letter.",
            reward: "Up to +\(ProgressRules.gameMaxXP) XP, fewer guesses earn more", actionLabel: "Play Word Guess", route: .wordGuess)
    }

    static let crossword = InfoContent(
        id: "crossword", badge: "Speed puzzle", title: "Mini Crossword (Crucigrama)",
        subtitle: "5×5 grid · Across & Down",
        description: "A bite-sized 5×5 Spanish crossword that tests vocabulary and grammar clues in a couple of minutes.",
        tip: "Tap a square twice to switch between Across (Horizontales) and Down (Verticales).",
        reward: "Coming in a later version", actionLabel: "Play Crossword", route: nil)

    static func exercise(type: String, title: String, exercise: Exercise?) -> InfoContent {
        let route = exercise?.id.map { TodayRoute.exercise(id: $0) }
        let reward = "+\(ProgressRules.exerciseXP) XP"
        switch type {
        case "fillBlank":
            return InfoContent(id: type, badge: "Grammar drill", title: title, subtitle: "Completa la frase",
                               description: "Read everyday Spanish sentences and pick the word that makes each one sound natural: the right verb form or connector.",
                               tip: "Watch for gender (el/la) and phrases that call for the subjunctive, like \"para que\" or \"ojalá\".",
                               reward: reward, actionLabel: "Start Drill", route: route)
        case "sentenceBuilder":
            return InfoContent(id: type, badge: "Syntax drill", title: title, subtitle: "Construye la oración",
                               description: "Put scrambled Spanish words back in order to build natural sentences.",
                               tip: "Object pronouns (me, te, lo, la) usually come right before the conjugated verb.",
                               reward: reward, actionLabel: "Start Drill", route: route)
        default:
            return InfoContent(id: type, badge: "Speed drill", title: title, subtitle: "Empareja palabras",
                               description: "Match Spanish words with their English meanings as fast as you can.",
                               tip: "Builds quick, translation-free recall of words you already know.",
                               reward: reward, actionLabel: "Start Drill", route: route)
        }
    }
}

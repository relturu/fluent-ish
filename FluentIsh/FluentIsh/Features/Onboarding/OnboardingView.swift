//
//  OnboardingView.swift
//  FluentIsh
//
//  First launch: 7 steps from the AI Studio prototype (src/pages/PageOnboarding.tsx).
//  0 Welcome · 1 Language · 2 Why · 3 How often · 4 Games · 5 Level · 6 Plan ready
//
//  Changes from the prototype:
//  - The mascot is Churro (the prototype says "Hi, I'm Lumi!").
//  - Only Spanish is selectable in V1; the other languages say "SOON".
//  - Plan ready asks for a name. plan.md needs one (greeting, leaderboard,
//    feed) and the prototype never asked.
//  - SKIP jumps to Plan ready (so the name still gets asked), not straight in.
//  - Copy that promised things the rules don't do: "5-letter puzzle" (ours
//    is 6), "streak multipliers", "+30 XP Bonus".
//
//  Nothing is written until "Start practicing". Then AppState saves the
//  profile, and RootView swaps to the tabs when the listeners see it.
//
//  DEBUG: `-onboardingStep N` opens a given step (for screenshots),
//  `-onboardingName X` pre-fills the name, `-onboardingAutoFinish YES` saves.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    
    // for onboarding replay
    var isReplay = false
    var onClose: () -> Void = {}

    // Device-only answers (see OnboardingChoices for why they aren't in Firestore).
    @AppStorage("motivation") private var storedMotivation = ""
    @AppStorage("weeklyFrequency") private var storedFrequency = ""
    @AppStorage("preferredGames") private var storedGames = ""

    @State private var step = 0
    @State private var goingForward = true
    @State private var choices = OnboardingChoices()
    @State private var saving = false
    @State private var saveError: String?
    @FocusState private var nameFocused: Bool

    private static let lastStep = 6

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                stepContent
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: goingForward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: goingForward ? .leading : .trailing).combined(with: .opacity)))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
            footer
        }
        .background(Color.canvas)
        .onAppear {
            if isReplay { choices.name = appState.firstName }
            #if DEBUG
            let debugStep = UserDefaults.standard.integer(forKey: "onboardingStep")
            if (1...Self.lastStep).contains(debugStep) { step = debugStep }
            if let name = UserDefaults.standard.string(forKey: "onboardingName") { choices.name = name }
            // `-onboardingAutoFinish YES` (with -onboardingName): saves straight
            // away, to test the Firestore write from the command line.
            if UserDefaults.standard.bool(forKey: "onboardingAutoFinish") { finish() }
            #endif
        }
    }

    // MARK: Header: back · progress · skip

    private var header: some View {
        HStack(spacing: 12) {
            Group {
                if step > 0 {
                    Button { go(to: step - 1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Color.ink.opacity(0.7))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Previous step")
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.flame)
                        .frame(width: 36, height: 36)
                }
            }

            OnboardingProgressBar(fraction: Double(step + 1) / Double(Self.lastStep + 1))
                .accessibilityLabel("Step \(step + 1) of \(Self.lastStep + 1)")

            Button("SKIP") { go(to: Self.lastStep) }
                .font(.jakarta(12, 800))
                .tracking(0.8)
                .foregroundStyle(Color.flame)
                .opacity(step == Self.lastStep ? 0 : 1)
                .disabled(step == Self.lastStep)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: Footer button

    private var footer: some View {
        VStack(spacing: 8) {
            if let saveError {
                Text(saveError)
                    .textStyle(.body)
                    .foregroundStyle(Color.coral)
                    .multilineTextAlignment(.center)
            }
            Button(action: next) {
                HStack(spacing: 8) {
                    if saving {
                        ProgressView().tint(.white)
                    } else if step == Self.lastStep {
                        Image(systemName: "sparkles")
                    }
                    Text(buttonTitle).tracking(0.8)
                }
            }
            .buttonStyle(.tactile(.primary, fullWidth: true))
            .disabled(saving || (step == Self.lastStep && !choices.canFinish))
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.canvas)
    }

    private var buttonTitle: String {
        switch step {
        case 0: "GET STARTED"
        case Self.lastStep: "START PRACTICING"
        default: "CONTINUE"
        }
    }

    // MARK: Navigation

    private func go(to newStep: Int) {
        Haptics.tap()
        nameFocused = false
        goingForward = newStep > step
        withAnimation(.spring(duration: 0.35)) { step = newStep }
    }

    private func next() {
        if step < Self.lastStep { go(to: step + 1) } else { finish() }
    }

    private func finish() {
        // for settings replay button
        if isReplay {
            nameFocused = false
            Haptics.success()
            onClose()
            return
        }

        guard choices.canFinish, !saving else { return }
        nameFocused = false
        saving = true
        saveError = nil
        storedMotivation = choices.motivation
        storedFrequency = choices.weeklyFrequency
        storedGames = choices.preferredGames.sorted().joined(separator: ",")
        Task {
            do {
                try await appState.completeOnboarding(choices)
                Haptics.success()
                // No navigation here: RootView switches to the tabs once the
                // profile listener sees the new documents.
            } catch {
                saveError = "Couldn't save your plan: \(error.localizedDescription)"
                Haptics.error()
                saving = false
            }
        }
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: welcome
        case 1: languageStep
        case 2: motivationStep
        case 3: paceStep
        case 4: gamesStep
        case 5: levelStep
        default: planReady
        }
    }

    private var welcome: some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                SpeechBubble(text: "Hi, I'm Churro!", style: .light, maxWidth: 150)
                MascotView(mood: .waving, size: .xl)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Welcome to Fluent\(Text("•").foregroundStyle(Color.flame))ish")
                    .font(.jakarta(26, 800))
                    .foregroundStyle(Color.ink)
                Text("A little daily play is all it takes to get fluent-ish.")
                    .font(.jakarta(14, 700))
                    .foregroundStyle(Color.flame)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                featureRow("gamecontroller", .flame, "Daily 3-game word progression sets")
                featureRow("clock", .connPurple, "Just 10 minutes a day to build habit")
                featureRow("trophy", .aqua, "Friendly streaks and weekly leaderboards")
            }
        }
    }

    private func featureRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 12) {
            IconTile(systemName: icon, color: color, size: 36)
            Text(text)
                .font(.jakarta(13, 800))
                .foregroundStyle(Color.ink)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.ink.opacity(0.1))
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.optionCard)
                    .padding(EdgeInsets(top: 2, leading: 2, bottom: 4, trailing: 2))
            }
        }
    }

    private var languageStep: some View {
        StepLayout(mood: .thinking, speech: "Which language sparks your curiosity?",
                   title: "What would you like to learn?") {
            ForEach(OnboardingOptions.languages, id: \.code) { lang in
                OptionCard(title: lang.name, isSelected: choices.language == lang.code,
                           isEnabled: lang.available, badge: lang.available ? nil : "SOON") {
                    Text(lang.flag).font(.system(size: 26))
                } action: {
                    choices.language = lang.code
                }
            }
        }
    }

    private var motivationStep: some View {
        StepLayout(mood: .encouraging, speech: "Great goal! Let's make it happen!",
                   title: "Why are you learning \(languageName)?") {
            ForEach(OnboardingOptions.motivations, id: \.id) { item in
                OptionCard(title: item.label, isSelected: choices.motivation == item.id) {
                    IconTile(systemName: item.icon, color: item.color)
                } action: {
                    choices.motivation = item.id
                }
            }
        }
    }

    private var paceStep: some View {
        StepLayout(mood: .encouraging, speech: "A few minutes a day builds fluency!",
                   title: "How often do you want to practice?") {
            ForEach([5, 10, 15, 20], id: \.self) { minutes in
                OptionCard(title: "\(minutes) min / day", isSelected: choices.dailyMinutes == minutes) {
                    IconTile(systemName: "clock", color: .flame)
                } action: {
                    choices.dailyMinutes = minutes
                }
            }
            HStack(spacing: 10) {
                frequencyTile(id: "casual-week", title: "3 to 4 days / week", icon: "calendar")
                frequencyTile(id: "daily", title: "Every single day", icon: "flame")
            }
            .padding(.top, 6)
        }
    }

    private func frequencyTile(id: String, title: String, icon: String) -> some View {
        let selected = choices.weeklyFrequency == id
        return Button {
            Haptics.tap()
            choices.weeklyFrequency = id
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(selected ? Color.connPurple : Color.ink.opacity(0.5))
                Text(title)
                    .font(.jakarta(12, 800))
                    .foregroundStyle(Color.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? Color.connPurple.opacity(0.15) : Color.optionCard,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? Color.connPurple : Color.ink.opacity(0.15), lineWidth: 2)
            }
            .opacity(selected ? 1 : 0.8)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var gamesStep: some View {
        StepLayout(mood: .quest, speech: "Games make every word stick!",
                   title: "What games do you prefer to play?") {
            ForEach(OnboardingOptions.games, id: \.id) { game in
                OptionCard(title: game.name, subtitle: game.tag,
                           isSelected: choices.preferredGames.contains(game.id),
                           indicator: .checkbox, dimWhenUnselected: true) {
                    IconTile(systemName: game.icon, color: game.color)
                } action: {
                    toggleGame(game.id)
                }
            }
        }
    }

    /// At least one game stays selected, like the prototype.
    private func toggleGame(_ id: String) {
        if choices.preferredGames.contains(id) {
            if choices.preferredGames.count > 1 { choices.preferredGames.remove(id) }
        } else {
            choices.preferredGames.insert(id)
        }
    }

    private var levelStep: some View {
        StepLayout(mood: .proud, speech: "No stress, we'll start where you're comfortable!",
                   title: "How much \(languageName) do you know?") {
            ForEach(OnboardingOptions.levels, id: \.level) { item in
                OptionCard(title: item.title, isSelected: choices.startingLevel == item.level) {
                    Text(item.emoji).font(.system(size: 22))
                } action: {
                    choices.startingLevel = item.level
                }
            }
        }
    }

    private var planReady: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                SpeechBubble(text: "Let's get fluent-ish!", style: .light, maxWidth: 180)
                MascotView(mood: .celebrating, size: .xl)
                Text("Your daily plan is ready!")
                    .font(.jakarta(24, 800))
                    .foregroundStyle(Color.ink)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("WHAT SHOULD CHURRO CALL YOU?")
                    .textStyle(.caption)
                    .foregroundStyle(Color.inkMuted)
                TextField("Your name", text: $choices.name)
                    .font(.jakarta(16, 700))
                    .foregroundStyle(Color.ink)
                    .textContentType(.givenName)
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .onSubmit(finish)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Color.optionCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(nameFocused ? Color.flame : Color.ink.opacity(0.15), lineWidth: 2)
                    }
                    .onChange(of: choices.name) { _, new in
                        if new.count > OnboardingChoices.maxNameLength {
                            choices.name = String(new.prefix(OnboardingChoices.maxNameLength))
                        }
                    }
            }

            VStack(spacing: 0) {
                summaryRow("Target Language", value: languageName, color: .flame)
                Divider().overlay(Color.hairline)
                summaryRow("Daily Pace", value: "\(choices.dailyMinutes) min / day", color: .connPurple, icon: "clock")
                Divider().overlay(Color.hairline)
                summaryRow("Weekly Frequency",
                           value: choices.weeklyFrequency == "daily" ? "Every day" : "3–4 days / week",
                           color: .aqua, icon: "flame")
                Divider().overlay(Color.hairline)
                summaryRow("Starting Level", value: choices.startingLevel.cefr, color: .connPurple)
                Divider().overlay(Color.hairline)
                summaryRow("Favorite Games", value: "\(choices.preferredGames.count) selected", color: .sunnyEdge)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.optionCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.ink.opacity(0.1), lineWidth: 2)
            }

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("Your first game is worth up to +\(ProgressRules.gameMaxXP) XP!")
            }
            .font(.jakarta(12, 800))
            .foregroundStyle(Color.flame)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.flame.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Color.flame.opacity(0.2))
            }
        }
    }

    private func summaryRow(_ label: String, value: String, color: Color, icon: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(.jakarta(13, 700))
                .foregroundStyle(Color.ink.opacity(0.75))
            Spacer()
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.system(size: 12, weight: .bold)) }
                Text(value).font(.jakarta(14, 800))
            }
            .foregroundStyle(color)
        }
        .padding(.vertical, 11)
    }

    private var languageName: String {
        OnboardingOptions.languages.first { $0.code == choices.language }?.name ?? "Spanish"
    }
}

// MARK: - Pieces

/// Speech bubble + Churro + question, then the options.
private struct StepLayout<Options: View>: View {
    let mood: MascotMood
    let speech: String
    let title: String
    @ViewBuilder var options: () -> Options

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                SpeechBubble(text: speech, style: .light, pointer: .trailing, maxWidth: 118, fontSize: 11)
                MascotView(mood: mood, size: .md)
                Text(title)
                    .font(.jakarta(20, 800))
                    .foregroundStyle(Color.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            VStack(spacing: 10) { options() }
        }
    }
}

private struct OnboardingProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(LinearGradient(colors: [.flame, Color(hex: 0xFF8A50)], startPoint: .leading, endPoint: .trailing))
                .frame(width: max(10, (geo.size.width - 4) * fraction))
                .padding(2)
                .animation(.spring(duration: 0.4), value: fraction)
        }
        .frame(height: 14)
        .background(Color.ink.opacity(0.1), in: Capsule())
    }
}

/// The option lists, copied from the prototype.
private enum OnboardingOptions {
    struct Language { let code, name, flag: String; let available: Bool }
    struct Motivation { let id, label, icon: String; let color: Color }
    struct Game { let id, name, tag, icon: String; let color: Color }
    struct Level { let level: OnboardingChoices.StartingLevel; let title, emoji: String }

    static let languages = [
        Language(code: "es", name: "Spanish", flag: "🇪🇸", available: true),
        Language(code: "fr", name: "French", flag: "🇫🇷", available: false),
        Language(code: "it", name: "Italian", flag: "🇮🇹", available: false),
        Language(code: "de", name: "German", flag: "🇩🇪", available: false),
        Language(code: "ja", name: "Japanese", flag: "🇯🇵", available: false),
        Language(code: "pt", name: "Portuguese", flag: "🇧🇷", available: false),
    ]

    static let motivations = [
        Motivation(id: "travel", label: "Travel and adventures abroad", icon: "safari", color: .flame),
        Motivation(id: "brain", label: "Brain workout & mental sharpness", icon: "brain", color: .connPurple),
        Motivation(id: "culture", label: "Music, cinema & food culture", icon: "music.note", color: .aqua),
        Motivation(id: "friends", label: "Connect with family & friends", icon: "person.2", color: .sunny),
        Motivation(id: "career", label: "Career & professional growth", icon: "briefcase", color: .coral),
    ]

    static let games = [
        Game(id: "connections", name: "Conexiones", tag: "Group 4 related words", icon: "square.grid.3x3", color: .connPurple),
        Game(id: "wordGuess", name: "Word Guess", tag: "Daily 6-letter puzzle", icon: "number", color: .sunny),
        Game(id: "crossword", name: "Mini Crossword", tag: "Bite-sized crossword with hints", icon: "questionmark.circle", color: .aqua),
        Game(id: "fillBlank", name: "Rapid Fill-In", tag: "Context & recall drills", icon: "doc.text", color: .flame),
        Game(id: "sentenceBuilder", name: "Sentence Builder", tag: "Piece together natural phrasing", icon: "speaker.wave.2", color: .success),
    ]

    static let levels = [
        Level(level: .beginner, title: "Just starting fresh from zero", emoji: "🌱"),
        Level(level: .elementary, title: "I know some common words", emoji: "☕"),
        Level(level: .intermediate, title: "I can have basic conversations", emoji: "💬"),
        Level(level: .advanced, title: "Intermediate or higher", emoji: "⚡"),
    ]
}

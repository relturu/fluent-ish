//
//  ProgressTabView.swift
//  FluentIsh
//
//  Progress tab: Player Stats, Quest Path and Word Log.
//  Ported from design/ai-studio/src/pages/Page01Progress.tsx (whole file);
//  design: docs/design_screenshots/progress-1.png, progress-2.png.
//  (Named ProgressTabView so it doesn't clash with SwiftUI's ProgressView.)
//
//  Where the data comes from:
//  - Player Stats: appState.progress (live), appState.level, appState.streak
//  - Quest Path:   service.recentLogs (last 28 dailyLogs) + quests/es_28day
//  - Word Log:     service.allWordProgress + service.words
//
//  What changed from the mockup (plan.md wins):
//  - "Level 1 · 1,470 / 1,500" → CEFR: "B1", "1,245 / 1,500 XP → B2"
//  - 312 / 89% / 14 are real: wordsLearned, reviewsCorrect ÷ reviewsTotal, streak
//  - The heatmap's hard-coded levels come from each day's dailyLog
//  - The Word Log lists the user's own words, not a fixed vocab list
//

import SwiftUI

struct ProgressTabView: View {
    @Environment(AppState.self) private var appState
    @State private var model = ProgressModel()

    @State private var showRules = false
    @State private var showLevel = false
    @State private var celebration: String?
    @State private var selectedDay = ProgressTabRules.questLength   // today
    @State private var category = ProgressTabRules.allCategory
    @State private var search = ""

    var body: some View {
        TabPage(title: "Progress", spacing: 24) {
            HStack(spacing: 12) {
                PillButton(title: "Rules") { showRules = true }
                AppStreakIndicator { celebrateStreak() }
            }
        } content: {
            if let error = appState.errorMessage {
                Text(error).textStyle(.body).foregroundStyle(Color.coral)
            }
            playerStats
            questPath
            wordLog
        }
        .sheet(isPresented: $showRules) { ProgressRulesSheet() }
        .sheet(isPresented: $showLevel) { LevelProgressSheet(flag: "🇪🇸", level: appState.level) }
        .overlay {
            if let celebration {
                CelebrationOverlay(message: celebration) { self.celebration = nil }
            }
        }
        // The logs and word list aren't live listeners, so reload them when
        // anything that changes them changes (XP, words learned, minutes).
        .task(id: reloadKey) { await load() }
    }

    private var reloadKey: String {
        "\(appState.uid ?? "")|\(appState.progress?.xp ?? -1)|\(appState.progress?.wordsLearned ?? -1)|\(appState.todayLog?.minutesSpent ?? 0)"
    }

    private func load() async {
        guard let uid = appState.uid else { return }
        await model.load(uid: uid, language: appState.language, today: appState.today, service: appState.service)
    }

    private func celebrateStreak() {
        let days = appState.streak
        guard days > 0 else { return }
        Haptics.success()
        celebration = "¡\(days) días en racha! · \(days)-day streak! 🔥"
    }

    // MARK: 1. Player Stats  (Page01Progress.tsx lines 117–213)

    private var playerStats: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Player Stats").textStyle(.h2).foregroundStyle(Color.ink)
                Spacer()
                Button { showLevel = true } label: {
                    Text("Level \(appState.level.name)".uppercased())
                        .font(.jakarta(11, 800))
                        .tracking(0.6)
                        .foregroundStyle(Color.connPurple)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Color.connPurple.opacity(0.15), in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.connPurple.opacity(0.3)))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Level \(appState.level.name). Show level progress")
            }

            // XP bar: tap for the level sheet, like the mockup.
            Button { showLevel = true } label: { xpBar }
                .buttonStyle(.plain)

            HStack(spacing: 10) {
                StatCard(value: "\(appState.progress?.wordsLearned ?? 0)", label: "Words", color: .flame)
                StatCard(value: ProgressTabRules.recallLabel(reviewsCorrect: appState.progress?.reviewsCorrect ?? 0,
                                                             reviewsTotal: appState.progress?.reviewsTotal ?? 0),
                         label: "Recall", color: .aqua)
                Button { celebrateStreak() } label: {
                    StatCard(value: "\(appState.streak)", label: "Streak", color: .flame, icon: "flame.fill")
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
    }

    private var xpBar: some View {
        let level = appState.level
        return VStack(spacing: 6) {
            HStack {
                Text("XP").font(.jakarta(11, 700)).foregroundStyle(Color.ink.opacity(0.75))
                Spacer()
                Text(ProgressTabRules.xpLabel(level))
                    .font(.jakarta(11, 800))
                    .monospacedDigit()
                    .foregroundStyle(Color.connPurple)
                    .contentTransition(.numericText())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.ink.opacity(0.1))
                    Capsule()
                        .fill(Color.flame)
                        .padding(2)
                        .frame(width: max(10, geo.size.width * min(1, max(0, level.fraction))))
                }
            }
            .frame(height: 10)
            .animation(.easeOut(duration: 0.3), value: level.xp)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Experience: \(ProgressTabRules.xpLabel(level))")
        .accessibilityHint("Shows level progress")
    }

    // MARK: 2. Quest Path  (lines 215–285)

    private var questPath: some View {
        let cells = ProgressTabRules.questCells(today: appState.today, logs: model.logs)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Quest Path").textStyle(.h2).foregroundStyle(Color.ink)

            SectionCard {
                switch model.phase {
                case .loading:
                    loadingRow
                case .failed(let message):
                    failedRow(message)
                case .loaded:
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                        ForEach(cells) { cell in
                            QuestSquare(cell: cell, selected: cell.day == selectedDay) {
                                Haptics.tap()
                                selectedDay = cell.day
                            }
                        }
                    }
                    .padding(.vertical, 2)   // room for today's ring

                    if let cell = cells.first(where: { $0.day == selectedDay }) {
                        QuestDayDetail(cell: cell, questDay: model.questDay(cell.day))
                    }

                    activityLegend
                }
            }
        }
    }

    private var activityLegend: some View {
        HStack {
            Text("Activity")
            Spacer()
            HStack(spacing: 6) {
                Text("Less").font(.jakarta(10, 600))
                ForEach(0..<4) { level in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(QuestSquare.fill(level))
                        .frame(width: 12, height: 12)
                }
                Text("More").font(.jakarta(10, 600))
            }
        }
        .font(.jakarta(11, 600))
        .foregroundStyle(Color.ink.opacity(0.7))
        .padding(.top, 10)
        .overlay(alignment: .top) { Rectangle().fill(Color.hairline).frame(height: 1) }
        .accessibilityHidden(true)
    }

    // MARK: 3. Word Log  (lines 287–364)

    private var wordLog: some View {
        let shown = ProgressTabRules.filter(model.words, category: category, query: search)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Word Log").textStyle(.h2).foregroundStyle(Color.ink)
                Spacer()
                if model.phase == .loaded {
                    // "words seen", so it doesn't look like it contradicts
                    // "Words" above, which only counts familiar + mastered.
                    Text("\(model.words.count) words seen")
                        .font(.jakarta(11, 700))
                        .foregroundStyle(Color.inkMuted)
                }
            }

            SectionCard(spacing: 14) {
                switch model.phase {
                case .loading:
                    loadingRow
                case .failed(let message):
                    failedRow(message)
                case .loaded where model.words.isEmpty:
                    EmptyWordLog(mood: .encouraging,
                                 speech: "¡Tu primera lección te espera!",
                                 caption: "Finish a Daily Vocab lesson and your words will show up here.")
                case .loaded:
                    SearchField(text: $search)
                    CategoryChips(categories: ProgressTabRules.categories(in: model.words), selection: $category)

                    VStack(spacing: 0) {
                        if shown.isEmpty {
                            EmptyWordLog(mood: .thinking,
                                         speech: "No encontré esa palabra... ¡prueba otra!",
                                         caption: "No matching vocabulary found")
                        } else {
                            ForEach(shown) { entry in
                                WordLogRow(entry: entry)
                                if entry.id != shown.last?.id {
                                    Rectangle().fill(Color.hairline).frame(height: 1)
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                    .overlay(alignment: .top) { Rectangle().fill(Color.hairline).frame(height: 1) }
                }
            }
        }
    }

    // MARK: Loading / error

    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()   // SwiftUI's spinner (this is why the tab isn't named ProgressView)
            Spacer()
        }
        .frame(minHeight: 80)
    }

    private func failedRow(_ message: String) -> some View {
        VStack(spacing: 10) {
            Text(message).textStyle(.body).foregroundStyle(Color.coral).multilineTextAlignment(.center)
            Button("Try again") { Task { await load() } }
                .buttonStyle(.tactile(.outline, size: .small))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pieces

/// White rounded card used by Quest Path and Word Log (rounded-[22px] border).
private struct SectionCard<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.hairline))
            .shadow(color: Color.indigo.opacity(0.04), radius: 2, y: 1)
    }
}

/// "312 WORDS": one of the three stat boxes.
private struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 15, weight: .bold))
                        .shadow(color: color.opacity(0.5), radius: 4)
                }
                Text(value)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .textStyle(.h2)
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(label.uppercased())
                .font(.jakarta(11, 700))
                .tracking(0.8)
                .foregroundStyle(Color.ink.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.hairline))
        .shadow(color: Color.indigo.opacity(0.04), radius: 2, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// One day on the Quest Path. Darker orange = more done that day.
private struct QuestSquare: View {
    let cell: QuestCell
    let selected: Bool
    let action: () -> Void

    /// The four shades from the mockup: /10, /30, /65, solid.
    static func fill(_ level: Int) -> Color {
        switch level {
        case 3: Color.flame
        case 2: Color.flame.opacity(0.65)
        case 1: Color.flame.opacity(0.3)
        default: Color.flame.opacity(0.1)
        }
    }

    var body: some View {
        Button(action: action) {
            Text(cell.isToday ? "★ \(cell.day)" : "\(cell.day)")
                .font(.jakarta(10, cell.level >= 2 ? 800 : 600))
                .foregroundStyle(cell.level >= 2 ? Color.white : Color.ink.opacity(cell.level == 1 ? 0.9 : 0.4))
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(Self.fill(cell.level), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    // Today: an orange ring with a gap (ring-2 ring-offset-2).
                    if cell.isToday {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.flame, lineWidth: 2)
                            .padding(-3)
                    } else if selected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.ink.opacity(0.6), lineWidth: 1.5)
                    }
                }
                .scaleEffect(cell.isToday ? 1.05 : 1)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Day \(cell.day)\(cell.isToday ? ", today" : ""): \(ProgressTabRules.activitySummary(cell.log))")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Under the grid: the tapped day's quest title, tier, Churro's line and
/// what was done that day. Defaults to today.
private struct QuestDayDetail: View {
    let cell: QuestCell
    let questDay: QuestDay?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            MascotView(mood: .quest, size: .sm, idle: false)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(cell.isToday ? "Today · Day \(cell.day)" : "Day \(cell.day)")
                        .font(.jakarta(11, 800))
                        .foregroundStyle(Color.flame)
                    if let tier = questDay?.tier {
                        Text(tier)
                            .font(.jakarta(10, 800))
                            .foregroundStyle(tierColor(tier))
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(tierColor(tier).opacity(0.15), in: Capsule())
                    }
                    Spacer()
                    Text(dateLabel).font(.jakarta(11, 600)).foregroundStyle(Color.inkMuted)
                }
                if let questDay {
                    Text(questDay.title).textStyle(.h3).foregroundStyle(Color.ink)
                    Text("“\(questDay.mascotMessage)”")
                        .font(.jakarta(12, 600))
                        .italic()
                        .foregroundStyle(Color.ink.opacity(0.75))
                }
                Text(ProgressTabRules.activitySummary(cell.log))
                    .font(.jakarta(12, 500))
                    .foregroundStyle(Color.inkMuted)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.canvas, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var dateLabel: String {
        ProgressRules.date(fromKey: cell.date)?.formatted(.dateTime.month(.abbreviated).day()) ?? cell.date
    }

    private func tierColor(_ tier: String) -> Color {
        switch tier {
        case "L3": .flame
        case "L2": .connPurple
        default: .aqua
        }
    }
}

/// The "Search words..." box.
private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.ink.opacity(0.4))
            TextField("Search words...", text: $text)
                .font(.jakarta(13, 500))
                .foregroundStyle(Color.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Color.ink.opacity(0.35))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(Color.canvas, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.ink.opacity(0.15)))
    }
}

/// All · Connector · Café & Dining · … (scrolls sideways).
private struct CategoryChips: View {
    let categories: [String]
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(categories, id: \.self) { category in
                    let active = category == selection
                    Button {
                        Haptics.tap()
                        selection = category
                    } label: {
                        Text(category)
                            .font(.jakarta(11, 800))
                            .lineLimit(1)
                            .foregroundStyle(active ? Color.white : Color.ink.opacity(0.75))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(active ? Color.flame : Color.ink.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .frame(minHeight: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

/// One word: term, category, how well it's known, definition, and 🔊.
private struct WordLogRow: View {
    let entry: WordLogEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.word.term)
                        .font(.jakarta(14, 800))
                        .foregroundStyle(Color.flame)
                        .lineLimit(1)
                    StatusTag(status: entry.status)
                    Spacer(minLength: 4)
                    Text(entry.word.category)
                        .font(.jakarta(10, 700))
                        .foregroundStyle(Color.ink.opacity(0.5))
                        .lineLimit(1)
                }
                Text(entry.word.definitionEn)
                    .font(.jakarta(12, 500))
                    .foregroundStyle(Color.ink.opacity(0.75))
                    .lineLimit(1)
            }
            AudioButton(text: entry.word.term)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .contain)
    }
}

/// Learning / Familiar / Mastered, from wordProgress.status.
private struct StatusTag: View {
    let status: WordStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.jakarta(9, 800))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
    }

    private var color: Color {
        switch status {
        case .mastered: .success
        case .familiar: .aqua
        case .learning: .sunny
        case .new: .inkMuted
        }
    }
}

/// Churro with a speech bubble, for an empty Word Log or a search with no hits.
private struct EmptyWordLog: View {
    let mood: MascotMood
    let speech: String
    let caption: String

    var body: some View {
        VStack(spacing: 6) {
            SpeechBubble(text: speech, style: .light, maxWidth: 240, fontSize: 12)
            MascotView(mood: mood, size: .sm)
            Text(caption)
                .font(.jakarta(12, 600))
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Rules sheet

/// The "Rules" pill: how XP, levels, streaks and word status work. Numbers
/// come from ProgressRules, so this can't drift from what the app does.
struct ProgressRulesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("How progress works").font(.fraunces(21, 700)).foregroundStyle(Color.ink)
                    Spacer()
                    CloseButton { dismiss() }
                }

                rule("Earning XP", lines: [
                    "Daily Vocab lesson: \(ProgressRules.vocabLessonXP) XP",
                    "Each game: up to \(ProgressRules.gameMaxXP) XP, based on your score",
                    "Each skill exercise: \(ProgressRules.exerciseXP) XP",
                    "Each hint: −\(ProgressRules.hintPenaltyXP) XP",
                    "Replays are for practice and earn 0 XP",
                ])

                rule("Levels", lines: ProgressRules.levels.map { "\($0.name): from \($0.floor.formatted()) XP" })

                rule("Streak", lines: [
                    "Finish any game, lesson or exercise to count the day",
                    "Miss a day and the streak starts again",
                ])

                rule("Words and recall", lines: [
                    "Words: words you know well (familiar or mastered)",
                    "3 correct answers → familiar, 6 → mastered; a wrong answer drops one step",
                    "Recall: how often you get a review word right",
                ])

                Button("Got it") { dismiss() }
                    .buttonStyle(.tactile(.secondary, fullWidth: true))
            }
            .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.modal)
        .presentationCornerRadius(28)
    }

    private func rule(_ title: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.jakarta(13, 800)).foregroundStyle(Color.flame)
            ForEach(lines, id: \.self) { line in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("•").foregroundStyle(Color.inkMuted)
                    Text(line).foregroundStyle(Color.ink.opacity(0.85))
                }
                .font(.jakarta(13, 500))
            }
        }
    }
}

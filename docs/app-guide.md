# Building a screen in Fluent·ish

How to add your screen to the SwiftUI app. Arielle moved the AI Studio design into Xcode and connected Firebase; the screens marked "Coming soon" are yours to build. Who owns what: the handoff table in `docs/plan.md` ("V1 app build").

## 1. Run it

1. Get `GoogleService-Info.plist` from a teammate (privately, the repo is public) and drop it in `FluentIsh/FluentIsh/`. Never commit it.
2. Open `FluentIsh/FluentIsh.xcodeproj`, pick an **iOS 27** simulator (iPhone 17), press ⌘R.
3. ⌘U runs the unit tests. They should all pass before you push.

On first launch the app signs in anonymously and shows onboarding. Your simulator user starts with no history. To give it Sofía's seeded history (streak, words, logs), copy the uid printed after 🔥 in the Xcode console and run `node scripts/demo-user.js <uid>`.

Only one copy of the app can run per simulator: if Xcode says Firestore "Failed to open LevelDB", stop the old run (⌘.) first. A second simulator is the easy way to have a fresh user: Xcode › Window › Devices and Simulators › +.

## 2. Where things live

New files under `FluentIsh/FluentIsh/` are picked up by Xcode automatically (synchronized folders).

| Folder | What's in it |
|---|---|
| `App/` | `AppState` (who's signed in, their profile, progress and today's log), `RootView` (splash → onboarding → tabs), `MainTabView` (custom tab bar) |
| `DesignSystem/` | Colours, fonts, text styles, the 3D button, haptics |
| `Components/` | Shared pieces: top bar, Churro, confetti, speech bubble, option cards, info sheet, filler screens |
| `Features/<Screen>/` | One folder per screen. Put yours here |
| `Services/` | `FirestoreService` (all reads and writes), `ProgressRules` and `GameRules` (pure rules, unit tested), `AzureTranslator` |
| `Models/` | Codable structs that match the Firestore documents exactly |
| `Debug/` | DEBUG-only: style guide, smoke test |
| `FluentIshTests/` | Unit tests (Swift Testing) |

## 3. Replace your filler

| Your screen | File to edit | Reached from | Design |
|---|---|---|---|
| Daily Vocab deck (Sean) | new `Features/VocabDeck/`, then `TodayDestination` in `Features/Today/TodayView.swift` | Today › Start | [session review](design_screenshots/session-review.png) |
| Connections (Jessica) | new `Features/Games/Connections/`, then `TodayDestination` | Today › Connections › Play | [1](design_screenshots/connections-1-playing.png), [2](design_screenshots/connections-2-group-solved.png) |
| Word Guess (Sai) | new `Features/Games/WordGuess/`, then `TodayDestination` | Today › Word Guess › Play | [1](design_screenshots/word-guess-1-playing.png), [hint](design_screenshots/word-guess-2-hint-popup.png) |
| Exercises (Arielle) | new `Features/Exercises/`, then `TodayDestination` | Today › Skill Exercises row | [info](design_screenshots/exercise-info-sheet.png), [fill in the blank](design_screenshots/fill-blank-playing.png) |
| Progress tab (Sai) | `Features/Progress/ProgressTabView.swift` | Tab bar | [1](design_screenshots/progress-1.png), [2](design_screenshots/progress-2.png) |
| Friends tab (Sean) | `Features/Friends/FriendsView.swift` | Tab bar | [1](design_screenshots/friends-1.png), [2](design_screenshots/friends-2.png) |
| Settings tab (Jessica) | `Features/Settings/SettingsView.swift` | Tab bar | [1](design_screenshots/settings-1.png), [2](design_screenshots/settings-2.png) |

**Design reference** (`docs/design_screenshots/`, from the AI Studio prototype):
- [design system 1](design_screenshots/design-system-1.png) and [2](design_screenshots/design-system-2.png): palette, type and buttons
- [mascot](design_screenshots/mascot.png): Churro's moods
- onboarding [1](design_screenshots/onboarding-1.png), [2](design_screenshots/onboarding-2.png), [3](design_screenshots/onboarding-3.png), [4](design_screenshots/onboarding-4.png)
- today [1](design_screenshots/today-1.png), [2](design_screenshots/today-2.png)
- the tabs: in the table above

The full prototype code is in `design/ai-studio/src/`. **To port a screen from it (or have your AI agent do it), follow `docs/porting-guide.md`**: it says which file and lines hold your screen, how to translate React/Tailwind to SwiftUI, what not to copy from the mockup, and has a prompt to paste into your agent. Where the mockup and plan.md disagree (XP numbers, "Lv.1", "Lumi", the pre-filled Word Guess board), follow plan.md.

For a Today screen, swap the `FillerScreen(...)` case in `TodayDestination` for your view. The filler's DEBUG "Finish (test)" button shows the exact `record(...)` call your screen should make when the player finishes, so copy that.

For a tab, keep the `TabPage(title:) { top-bar buttons } content: { ... }` wrapper. It gives you the pinned "Fluent•ish / Title" bar, the cream background and room for the tab bar. Replace the `FillerSection` cards with your content. Each tab file's header comment lists the data that already exists for it.

## 4. Styling

Match the mockups by using these instead of raw values. `Debug/StyleGuideView.swift` shows all of them (launch argument `-screen styleguide`, see section 7).

```swift
Text("Daily Vocab").textStyle(.serifCard)          // display, h1, h2, h3, body, bodyMedium, caption,
                                                   // serifHero, serifTitle, serifCard
.foregroundStyle(Color.ink)                        // ink, inkMuted, flame, connPurple, aqua, sunny, success, coral
.background(Color.card)                            // canvas (page), card, raised, modal, hairline, segmentTrack
.font(.jakarta(15, 800))                           // when no text style fits; .fraunces(...) for serif

Button("Continue") { }                             // the chunky 3D button
    .buttonStyle(.tactile(.primary, size: .large, fullWidth: true))
                                                   // .primary .secondary .purple .yellow .aqua .outline
Haptics.tap()   Haptics.success()   Haptics.error()
```

Every colour has a light and dark version already, so dark mode works if you use these names.

| Piece | Use it for |
|---|---|
| `MascotView(mood: .celebrating, size: .lg)` | Churro. Moods: waving, celebrating, quest, thinking, proud, encouraging |
| `GameHeaderBar(title:onHowToPlay:onHint:)` | The Back / title / ? / ! header on game and exercise screens |
| `AudioButton(text:)`, `Speech.speak(_:)` | Spanish pronunciation (on-device) |
| `SpeechBubble(text:style:pointer:)` | Churro's lines |
| `CelebrationOverlay(message:onDone:)` | Confetti and a dancing Churro when something is finished |
| `TodayCard { }` | The white rounded card used on Today |
| `OptionCard(title:isSelected:...)` | Chunky selectable rows (onboarding; good for Settings) |
| `InfoSheet(content:onAction:)` | The (i) / "About" explanation sheet |
| `PageTopBar`, `StreakIndicator`, `LevelPill`, `PillButton` | Top bar pieces |

## 5. Data

Read state from `AppState` in any view:

```swift
@Environment(AppState.self) private var appState

appState.user          // AppUser?: displayName, settings.dailyGoalMinutes, ...
appState.progress      // LanguageProgress?: xp, weeklyXP, wordsLearned, recallRate, ...
appState.todayLog      // DailyLog?: what was done today (games, vocab, exercises, minutes)
appState.level         // CEFR level info: name "B1", nextName "B2", xpToNext, fraction
appState.streak        // the streak to show (0 if a day was missed)
appState.today         // "2026-11-04"
appState.service       // FirestoreService: every other read and write
```

`user`, `progress` and `todayLog` are **live**: when anything writes to them, every screen updates by itself. You don't need to refresh.

**Finishing an activity: always use `record`.** One Firestore transaction updates today's log, XP, weekly XP, streak and level. It also stops replays from earning XP twice.

```swift
// A game (also call this with status: .inProgress to save halfway)
try await appState.record(.game(key: "connections", result: GameResult(
    status: .completed, score: ProgressRules.connectionsScore(mistakes: mistakes),
    mistakes: mistakes, solvedGroups: solved, guesses: nil, filledCells: nil, hintsUsed: nil)),
    minutes: minutesSpent)

// An exercise
try await appState.record(.exercise(id: exercise.id!), minutes: minutesSpent)

// The vocab lesson: also updates each word's spaced-repetition status
try await appState.service.completeVocabLesson(answers, minutes: minutesSpent,
    uid: appState.uid!, language: appState.language)
```

`record` returns an `ActivityOutcome`: `xpAwarded` (0 on a replay) and `leveledUp`. Use them for the end-of-session screen.

**Reading content:**

| Need | Call |
|---|---|
| Which seeded day to show today | `service.contentDay(language:today:)`. It rotates through the seeded days, so add a week of puzzles in `firebase/seed/` and they're used automatically |
| Today's puzzles / lesson / prompt | `service.dailyPuzzle(language:day:)`, `vocabLesson`, `dailyPrompt` |
| The 70/30 deck | `service.lessonDeck(uid:language:today:lesson:)`, then `service.words(ids:)` |
| Exercises | `service.exercises(language:)` |
| Last 28 days of logs | `service.recentLogs(uid:language:today:)` |
| Every word seen | `service.allWordProgress(uid:language:)` |

`Features/Today/TodayModel.swift` is a working example of loading all of this.

**Rules** (all unit tested, so don't re-implement them):
- `ProgressRules.connectionsScore(mistakes:)`, `wordGuessScore(guessesUsed:solved:)`, `gameXP(score:hintsUsed:)`
- `GameRules.feedback(guess:answer:)` gives Word Guess colours. It handles repeated letters, ignores accents and treats Ñ as its own letter.
- The XP values and level floors are in `ProgressRules` and in plan.md "Defaults to implement".

Firestore rules: the app reads content, and writes only to the signed-in user's own documents (plus posts and likes). A write anywhere else fails with "permission denied". Don't rename fields without updating `docs/plan.md` and `Models/FirestoreModels.swift` together.

## 6. Tests

Put pure logic (scoring, parsing, anything without UI or Firebase) in a `nonisolated enum` like `GameRules`, and test it in `FluentIshTests/`:

```swift
import Testing
@testable import FluentIsh

struct MyRulesTests {
    @Test func scoresAPerfectGame() {
        #expect(ProgressRules.connectionsScore(mistakes: 0) == 1)
    }
}
```

Tests run in parallel. Don't share mutable `static var` state between them: use a `Mutex`, as `Components/SVGPath.swift` does.

## 7. DEBUG launch arguments

Add these in Xcode › Product › Scheme › Edit Scheme › Run › Arguments, one per line. Untick them when you're done.

| Argument | Does |
|---|---|
| `-tab progress` (`friends`, `settings`) | Opens on that tab |
| `-todayOpen connections` (`vocab`, `wordGuess`, `exercise`) | Opens that screen from Today |
| `-todaySheet level` (`vocab`, `connections`, `wordGuess`, `crossword`, `fillBlank`) | Opens a sheet on Today |
| `-darkMode YES` | Dark mode |
| `-screen styleguide` | The design-system screen |
| `-screen onboarding` | Previews onboarding. Don't finish it: that overwrites your progress |
| `-freshStart YES` | Signs out, so you get a brand-new user and onboarding. Your old uid's data stays in Firestore, but this simulator can't get back to it |
| `-smokeWrite YES` | The smoke test (always on in DEBUG, results in the console with 🧪) also tests a write |

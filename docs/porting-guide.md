# Porting an AI Studio screen to SwiftUI

How to turn a screen from the AI Studio prototype (React + Tailwind) into a SwiftUI screen in this app. Written so you can hand it to your own AI agent along with `docs/app-guide.md`. Section 6 is a prompt to paste in.

**Inputs**

| What | Where |
|---|---|
| Prototype source (read-only reference) | `design/ai-studio/src/` |
| Screenshots | `docs/design_screenshots/` |
| How the Swift app works (styling, data, `record`) | `docs/app-guide.md` |
| Data model and game rules (source of truth) | `docs/plan.md` |
| A finished port to copy | `FluentIsh/FluentIsh/Components/GameHeaderBar.swift` (section 5) |

## 1. Where your screen is in the prototype

| Screen (owner) | Prototype code | Screenshots |
|---|---|---|
| Daily Vocab deck (Sean) | `pages/Page03Daily.tsx` lines 69–340 | (none, see the Today screenshots) |
| Session Review, after any activity (Sean) | `pages/GamesAndExercises.tsx` lines 217–445; `components/LevelUpModal.tsx`; `components/RulesModal.tsx` | `session-review.png` |
| Connections (Jessica) | `pages/GamesAndExercises.tsx` lines 446–681 | `connections-1-playing.png`, `connections-2-group-solved.png` |
| Word Guess (Sai) | `pages/GamesAndExercises.tsx` lines 682–908 | `word-guess-1-playing.png`, `word-guess-2-hint-popup.png` |
| Fill in the Blank (Arielle) | `pages/GamesAndExercises.tsx` lines 1107–1254 | `fill-blank-playing.png`, `exercise-info-sheet.png` |
| Sentence Builder (Arielle) | `pages/GamesAndExercises.tsx` lines 1255–1388 | (none) |
| Definition Match (Arielle) | `pages/GamesAndExercises.tsx` lines 1389–1553 | (none) |

**A finished example:** the three exercises are built (`FluentIsh/FluentIsh/Features/Exercises/`). Copy their pattern for your game:
- `GameHeaderBar` with `?` (a `HowToPlaySheet`) and `!` (a hint counter the board reacts to)
- `.shake(misses)` and `Haptics.error()` on a wrong answer
- `FlowLayout` for wrapping tiles
- `appState.record(...)` when the player finishes, then a recap
- pure checking logic in a tested `nonisolated enum` (`Services/ExerciseRules.swift`)
| Progress tab (Sai) | `pages/Page01Progress.tsx` | `progress-1.png`, `progress-2.png` |
| Friends tab (Sean) | `pages/Page02Friends.tsx` | `friends-1.png`, `friends-2.png` |
| Settings tab (Jessica) | `pages/Page04Settings.tsx` | `settings-1.png`, `settings-2.png` |

Shared prototype pieces: `components/common/HiFiElements.tsx` (buttons, header bar, hint popup `GameAssistModal` at line 920, `CountUpNumber` at line 186) and `src/types.ts` (mock data shapes). Ignore `flows/`, `LoFiElements`, `DeviceFrame`, `WireframeToolbar` and `Design*Modal`: they're wireframe tooling, not app screens.

**The pattern every game and exercise follows** (see the screenshots):
1. `GameHeaderBar` on top: Back, title, **?** (how to play) and **!** (hint).
2. The board.
3. The action buttons at the bottom.
4. When it's finished, the **Session Review**: score, accuracy, time, XP earned, streak and level status, a learning tip, and the words practised.

Learning activities also have an **info sheet** before starting (`exercise-info-sheet.png`). It already exists as `InfoSheet` on Today.

## 2. Copy the look, not the behaviour

The prototype is a mockup. Its numbers and some of its logic are placeholders. **When it disagrees with `docs/plan.md`, plan.md wins.**

| Prototype | Do this instead |
|---|---|
| Hard-coded words, puzzles, users (`DAILY_SPANISH_VOCAB`, arrays in the page) | Load from Firestore (`app-guide.md` section 5). `TodayModel.swift` is an example |
| "+25 XP", "+40 XP", "100 Pts", "Level 1 (1495/1,500)" | XP from `ProgressRules` (vocab 20, game up to 30, exercise 10, hint −5); levels are CEFR (`appState.level`); no "points" |
| Word Guess board pre-filled, 5 rows | Empty board, **6** rows, colours from `GameRules.feedback` |
| "Solve CHARLA" in the hint popup (gives away the answer) | A hint reveals a little (e.g. the first letter) and costs 5 XP (`hintsUsed`) |
| Connections with no game over | 4 mistakes ends the game; shuffle the tiles |
| Exercises that never check answers | Check each answer and show right/wrong |
| Streak never resets | Already handled by `record` |
| "Lumi" | The mascot is Churro |
| `localStorage`, React state for progress | `appState.record(...)` (saves to Firestore; the Today screen updates by itself) |

## 3. Translation table

**Layout**

| Tailwind / React | SwiftUI |
|---|---|
| `flex flex-col gap-3` | `VStack(spacing: 12)` |
| `flex items-center justify-between` | `HStack { a; Spacer(); b }` |
| `grid grid-cols-4 gap-2` | `LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8)` |
| `overflow-y-auto` | `ScrollView` |
| `sticky top-0` header | `.safeAreaInset(edge: .top, spacing: 0) { GameHeaderBar(...) }` |
| `p-4` / `px-5 py-3` | `.padding(16)` / `.padding(.horizontal, 20).padding(.vertical, 12)` (Tailwind unit = 4pt) |
| `w-9 h-9` | `.frame(width: 36, height: 36)` |
| `rounded-2xl` / `rounded-xl` / `rounded-full` | `RoundedRectangle(cornerRadius: 16 / 12, style: .continuous)` / `Capsule()` or `Circle()` |
| `border` / `border-b` | `.overlay(RoundedRectangle(...).strokeBorder(Color.hairline))` / an `.overlay(alignment: .bottom)` 1pt `Rectangle` |
| `truncate` | `.lineLimit(1)` |
| `absolute` overlay | `.overlay(alignment: ...)` or a `ZStack` |
| `hidden` / conditional `&&` | `if condition { ... }` |
| `min-h-[44px]` | `.frame(minHeight: 44)`. Keep every tap target at least 44pt |

**Colours.** Use the token, never the hex. Tokens switch for dark mode by themselves, so drop every `darkMode ? ... : ...`.

| Prototype hex | Token |
|---|---|
| `#FF6B2C` | `.flame` |
| `#1F1B4D` (text) | `.ink` |
| `#706E7B`, `opacity-60/70` text | `.inkMuted` |
| `#FFF8EC` (page) / `#17143A` (dark page) | `.canvas` |
| `bg-white` / `#221E52` (cards) | `.card` |
| `#F0EAE0` (inactive tiles, tracks) | `.raised` or `.segmentTrack` |
| `#7B5CFF` | `.connPurple` |
| `#FFC93C` | `.sunny` |
| `#19C3B1` | `.aqua` |
| `#3DDC84` | `.success` |
| `#FF5C6C` | `.coral` |
| `border-[#1F1B4D]/10` | `.hairline` |
| `bg-[#FF6B2C]/10` | `Color.flame.opacity(0.1)` |

**Text.** Use `.textStyle(...)` from `DesignSystem/Typography.swift`. `type-h3` → `.textStyle(.h3)`. `font-serif text-[22px] font-bold` → `.textStyle(.serifTitle)`. For an exact size and weight, use `.font(.jakarta(13, 700))` (`font-bold` = 700, `font-extrabold` = 800, `font-semibold` = 600, `font-medium` = 500).

**Components**

| Prototype | Swift |
|---|---|
| `HiFiButton` / `btn-3d-primary` | `Button(...).buttonStyle(.tactile(.primary))`: `.secondary` (indigo), `.purple`, `.yellow`, `.aqua`, `.outline`; `size: .small` |
| `GameHeaderBar` | `GameHeaderBar` (ported, section 5) |
| `AudioButton`, `speakSpanish` | `AudioButton(text:)`, `Speech.speak(_:)` |
| `ChurroMascot mood=… size=…` | `MascotView(mood: .celebrating, size: .lg)` |
| `speech="…"` on the mascot | `SpeechBubble(text: "…")` above it |
| `ConfettiBurst` | `CelebrationOverlay(message:onDone:)` |
| `GameAssistModal`, `RulesModal` | A `.sheet` styled like `InfoSheet` (`Components/InfoSheet.swift`) |
| `CountUpNumber` | `Text("\(xp)").contentTransition(.numericText())` with `withAnimation` |
| `playSelectSound` / `playCelebrationSound` | `Haptics.tap()` / `Haptics.success()` (sound is V2) |

**Icons** (lucide-react → SF Symbols): `ArrowLeft` → `arrow.left`, `ChevronRight` → `chevron.right`, `Check` → `checkmark`, `X` → `xmark`, `Play` → `play.fill`, `Volume2` → `speaker.wave.2.fill`, `Flame` → `flame.fill`, `Sparkles` → `sparkles`, `Lightbulb` → `lightbulb`, `RotateCcw` → `arrow.counterclockwise`, `Delete` → `delete.left`, `Trophy` → `trophy`, `Clock` → `clock`. Search others in the SF Symbols app.

**React → SwiftUI**

| React | SwiftUI |
|---|---|
| `useState(x)` | `@State private var x` |
| props | `let` properties on the view |
| `onClick={() => …}` | `Button { … } label: { … }` |
| `useEffect(() => …, [])` | `.task { … }` (async loading) or `.onAppear` |
| `.map((item) => <Row/>)` | `ForEach(items) { Row(item: $0) }` |
| `onNavigate('session-review')` | `NavigationLink(value:)` / a `navigationDestination` |
| `setTimeout` | `try? await Task.sleep(for: .seconds(1))` inside a `Task` |
| `className={cond ? 'a' : 'b'}` | `.foregroundStyle(cond ? .flame : .ink)` |

## 4. Steps

1. Read your rows in sections 1 and 2, the screenshots, and `docs/app-guide.md`.
2. Create `Features/<Screen>/` with:
   - `<Screen>View.swift`: the UI.
   - `<Screen>Model.swift`, if it loads data: an `@Observable` class, like `TodayModel`.
   - Rules in a `nonisolated enum`, if there's game logic: no UI, no Firebase, so it's testable.
3. Port the layout top to bottom, section by section. Keep a `// Ported from <file> lines X–Y` comment at the top, as `GameHeaderBar.swift` does.
4. Wire data: load content through `appState.service`. When the player finishes, call `appState.record(...)` (copy it from your filler's "Finish (test)" button in `TodayView.swift` › `TodayDestination`), then show the result.
5. Replace your `FillerScreen` case in `TodayDestination`, or the `FillerSection` cards in your tab.
6. Add tests for the rules in `FluentIshTests/`.
7. Check it: ⌘R, compare with the screenshot in light **and** dark mode (`-darkMode YES`), then ⌘U.

## 5. Worked example: `GameHeaderBar`

Prototype (`HiFiElements.tsx` lines 642–733, shortened):

```tsx
<header className="sticky top-0 z-30 px-4 py-2.5 border-b bg-[#FFF8EC]/95 border-[#1F1B4D]/10 backdrop-blur-md">
  <div className="flex items-center justify-between gap-2">
    <div className="flex items-center justify-start shrink-0 min-w-[64px]">
      <button onClick={onBack} className="text-[13px] font-bold flex items-center gap-1 opacity-80 min-h-[44px]">
        <ArrowLeft className="w-4 h-4" /><span>Back</span>
      </button>
    </div>
    <div className="text-center flex-1 min-w-0">
      <h2 className="type-h3 truncate">{title}</h2>
      {subtitle && <p className="text-[11px] opacity-60 font-semibold truncate">{subtitle}</p>}
    </div>
    <div className="flex items-center justify-end gap-1.5 shrink-0 min-w-[64px]">
      {onOpenHowToPlay && <button className="w-9 h-9 rounded-xl font-extrabold text-[13px] border bg-white border-[#1F1B4D]/15">?</button>}
      {onOpenHint && <button className="w-9 h-9 rounded-xl ... bg-[#FF6B2C]/10 text-[#FF6B2C] border-[#FF6B2C]/30">!</button>}
    </div>
  </div>
</header>
```

SwiftUI (`Components/GameHeaderBar.swift`, shortened):

```swift
HStack(spacing: 8) {
    Button { dismiss() } label: {                         // onBack defaults to going back
        HStack(spacing: 4) {
            Image(systemName: "arrow.left").font(.system(size: 14, weight: .bold))
            Text("Back").font(.jakarta(13, 700))               // text-[13px] font-bold
        }
        .foregroundStyle(Color.ink.opacity(0.8))              // opacity-80
        .frame(minHeight: 44)                                 // min-h-[44px]
    }
    .frame(minWidth: 64, alignment: .leading)                 // min-w-[64px]

    VStack(spacing: 1) {
        Text(title).textStyle(.h3).lineLimit(1)               // type-h3 truncate
        if let subtitle {
            Text(subtitle).font(.jakarta(11, 600)).foregroundStyle(Color.ink.opacity(0.6))
        }
    }
    .frame(maxWidth: .infinity)                               // flex-1

    HStack(spacing: 6) {                                      // gap-1.5
        if let onHowToPlay { SquareIconButton(symbol: "?", ...) }   // w-9 h-9 rounded-xl
        if let onHint { SquareIconButton(symbol: "!", tint: .flame, fill: Color.flame.opacity(0.12), ...) }
    }
    .frame(minWidth: 64, alignment: .trailing)
}
.padding(.horizontal, 16)                                      // px-4
.background { Rectangle().fill(.ultraThinMaterial).overlay(Color.canvas.opacity(0.95)) }  // bg/95 + blur
.overlay(alignment: .bottom) { Rectangle().fill(Color.hairline).frame(height: 1) }        // border-b
```

What changed in the port, and why:
- **Every `darkMode ? … : …` is gone.** `Color.canvas`, `.ink` and `.hairline` already switch.
- **`sticky top-0` became how it's used:** `.safeAreaInset(edge: .top)` pins it while the screen scrolls.
- **Back calls `dismiss()` by default,** so screens don't pass an `onBack`.
- **The 36pt "?" and "!" got a 44pt invisible tap area**, Apple's minimum.

Use it on your screen:

```swift
ScrollView { board }
    .background(Color.canvas)
    .safeAreaInset(edge: .top, spacing: 0) {
        GameHeaderBar(title: "Connections", onHowToPlay: { showRules = true }, onHint: { showHint = true })
    }
    .toolbar(.hidden, for: .navigationBar)
```

The filler screens on Today already use it, so ⌘R and tap Play to see it.

## 6. Prompt for your agent

Paste this into Claude Code, Copilot, Cursor, etc., from the repo root, and fill in the brackets from the section 1 table:

```text
You are porting one screen of the Fluent·ish iOS app from a React/Tailwind prototype to SwiftUI.

Screen: [Connections]
Prototype code: design/ai-studio/src/[pages/GamesAndExercises.tsx lines 446–681]
Screenshots: docs/design_screenshots/[connections-1-playing.png, connections-2-group-solved.png]

Read these first, in order:
1. docs/porting-guide.md (how to translate the prototype, and what NOT to copy from it)
2. docs/app-guide.md (the app's structure, styling components and data APIs)
3. docs/plan.md, "Defaults to implement" (scoring, XP and rule values; these override the prototype)
4. FluentIsh/FluentIsh/Components/GameHeaderBar.swift (a finished port to imitate)
5. FluentIsh/FluentIsh/Features/Today/TodayView.swift: TodayDestination (my filler screen
   and the exact appState.record(...) call to make when the player finishes)

Then:
- Build the screen in FluentIsh/FluentIsh/Features/[Games/Connections]/ using the design-system
  tokens and components (Color.ink, .textStyle, .tactile buttons, MascotView, GameHeaderBar).
  No hex colours, no darkMode checks, no hard-coded content: load it with appState.service.
- Put game logic in a nonisolated enum and add Swift Testing tests in FluentIsh/FluentIshTests/.
- Save progress with appState.record(...) as described in app-guide.md section 5.
- Replace my FillerScreen case in TodayDestination with the new view.
- Don't change Firestore field names, other people's screens, or shared components
  without asking me.
- Build with Xcode on an iOS 27 simulator, run the tests, and tell me what to check by hand.

Work in small steps and explain each one before moving on.
```

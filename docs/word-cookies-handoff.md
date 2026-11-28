# Word Cookies: handoff for a new chat

_Updated Nov 27, 2026 (evening). Ask Claude to read this file in a new chat. When the build is finished, delete this file; `docs/plan.md` is the permanent record._

## Who I am and how to work with me
- I'm Sai (CMU 67-443, Fluent·ish team). I'm building a new game, **Word Cookies**, on branch **`add-word-cookie`**.
- Read `CLAUDE.md` and the **"Word Cookies"** section of `docs/plan.md` first. Then this file, which is newer than plan.md on the screen design.
- **Work one step at a time.** Explain *why* each change is made, and give me a test to run before moving on.
- **After every change, tell me what I should see in the UI.**
- **Ask before** uploading to Firestore (`seed.js`), committing, or starting the next step. When I say "plan with me / don't edit", only plan.
- Only change what the step needs. Game, Progress, Friends and Settings screens belong to teammates.
- **Visuals stay consistent with the other Fluent·ish games** (app colors, Jakarta font, tactile 3D style). No cookie art or copied assets from the real Word Cookies.

## The game
- Each day, one word from that day's Daily Vocab deck (the **base word**, 6–9 letters) is split into letter tiles in a circle (the "pan").
- The player drags across tiles to spell Spanish words made only from those letters. **5–6 words to find per day** (number of words, not letters), including the base word.
- Found words fill their slots; their English shows above the pan. One puzzle per day, the same for everyone. You can't lose.

## Decisions (all settled, don't re-ask)
| Topic | Decision |
|---|---|
| Base word | One word from that day's deck, 6–9 letters, picked by hand in the seed. Kept even though the real game uses shorter base words: it ties the game to the deck. |
| Word count | **5–6 words** per day including the base word (cut from 5–8 on Nov 27: 8 felt like too much). Others are everyday A1–A2 words, 3+ letters, dictionary forms only, neutral Spanish. |
| Not on the list | A real word that isn't on the list just shakes. No dictionary, no bonus words. |
| Tiles | Uppercase, accents dropped (á→A), **Ñ stays its own tile**. Each tile used once per word. |
| Hints | Reveal the leftmost hidden letter of the first unfound word with 2+ hidden letters. Max 3, −5 XP each. |
| Score / XP | Score always 1.0. XP = 30 − 5 × hints. |
| Word bank | On the first finish, `VocabAnswer`s for found words with a `wordId`; correct if no letter was hinted. |
| Word Guess | Will be removed later. Word Cookies must not use Word Guess code (incl. `GameRules.normalize`). |
| Board layout | Like the real game: **base word alone on top, centered; other words in two columns** below (shortest first, down the left column then the right; left gets the extra one). All slots the same size; the longest column word sets it (~22pt on 6-letter days, ~27pt on 5-letter days, iPhone 16). Never scrolls. No crossword-style crossing words. |
| English meanings | Shown in the pill above the pan when found; tap a found row to see it again; the end card lists every word with its English. Not shown inside the rows. |
| Look | Indigo pan (same colors as `.tactile(.secondary)`), 3D off-white tiles that turn flame when selected, flame drag line, spelled word as small flame tiles, round tactile Shuffle (bottom-left) and yellow Hint with hints-left badge (bottom-right). |

**Word lists (6 each, approved Nov 27):**
| Day | Words (base word last, * = has wordId) |
|---|---|
| Sat SOBREMESA | mar, amor, beso, mesa, sabor, sobremesa* |
| Sun REGATEAR | área, arte, rata, tarea, tragar, regatear* |
| Mon ATARDECER | dar, cara, acera*, tarde, receta, atardecer* |
| Tue ASCENSOR | ser, cena, cosa, rosa, carne, ascensor* |
| Wed SORPRESA | paso, pera, sopa, paseo, perro*, sorpresa* |
| Thu COMPAÑERO | año, pero, ropa, campo, compra, compañero* |
| Fri DESCANSAR | sed, casa*, nada, arena, secar, descansar* |

## Progress
| Step | Status |
|---|---|
| 1. Data model | ✅ Committed (`075e4b2`) |
| 2. Seed + checks | ✅ Committed. Trim to 6 words committed and re-seeded to Firestore (Nov 27) |
| 3. Game rules + tests | ✅ Committed |
| 4. Game screen | ✅ Redesign A–C committed and checked on the simulator. Step D committed (Nov 27): D1 slots pop left to right when found (`SlotCell`), D2 rejected word stays in coral, shakes, fades (`showRejected`), D3 re-spelled or tapped row flashes (`flashes`). Reduce Motion drops the movement. Also: tiles 20% of the pan (was 23%) and a 70% hit radius, so dragging past a tile doesn't pick it up. |
| 5. Today wiring | 🟡 Written before the redesign, committed, preview layout + info text still to update (see below) |
| 6. Docs + tell teammates | Not started |

Build passes; **297/297 tests pass** (Nov 27).

### Uncommitted changes on `add-word-cookie`
- `FluentIsh/FluentIsh/Features/Games/WordCookies/WordCookiesView.swift` (new): the screen
- `FluentIsh/FluentIsh/Features/Games/WordCookies/WordCookiesBoard.swift` (new): layout math
- `FluentIsh/FluentIshTests/WordCookiesBoardTests.swift` (new): 11 tests
- `FluentIsh/FluentIshTests/WordCookiesGameTests.swift`: comment only (its fixture keeps the old 8-word Sunday on purpose; rules work for any count)
- `FluentIsh/FluentIsh/Features/Today/TodayCards.swift`, `TodayModel.swift`, `TodayView.swift`: Step 5
- `firebase/seed/dailyPuzzles.json`: 13 words removed (52 → 42)
- `scripts/check-seed.js`: limit 5–8 → 5–6 (passes, 8547 checks)
- `docs/plan.md`, this file

### Step 4: what the screen is now
- **`WordCookiesBoard.swift`** (pure, `nonisolated enum`):
  - `arrange(rowCount:top:) -> Arrangement { top, left, right, rowCount }`
  - `slotSide(for:lengths:in:)`: min of top word fitting the width, longest column word fitting half the width (minus `columnGap` 14), all rows fitting the height; capped at `maxSlot` 44; whole points; 0 before measuring
  - `circleSide(forHeight:)`: 38% of the height below the header, 180–270
- **`WordCookiesView.swift`**, top to bottom: `GameHeaderBar`, `slotBoard` (card, fills leftover height, measured with `onGeometryChange`), `wordPill` (flame letter chips while spelling, otherwise the feedback/prompt text, shakes on a miss), `playArea` (pan + corner buttons), VoiceOver Clear/Submit row only when VoiceOver is on. `endCard` replaces pill + pan when finished.
  - Private pieces: `SlotRow` (takes `side`), `LetterTile`, `TactileDisc` (3D face + edge for non-buttons), `RoundTactileButtonStyle` (`.plain` / `.hint`), `EndCard` (with `wordList`), `StatBox`, `AssistSheet`.
  - `Feedback.found(display, en:)` → pill shows "tarea: homework, task". `showMeaning(of:)` for tapping a found row (not while spelling or after the game ends).
  - `baseRowIndex`: row with the puzzle's `baseWordId`, else the last row.
  - Previews use the new 6-word Sunday.
- **Step D (done):** staggered pop instead of letters flying from the pill (simpler; can add flying later). Gotcha: a 0-second keyframe makes the scale NaN and the view disappears, so `SlotCell`'s wait is `max(delay, 0.001)` (`if` isn't allowed in the keyframe builder).

### Step 5: what's already written (needs a look)
- `WordCookiesPreview` in `TodayCards.swift`: mini slot rows (green when found). **Still a plain stack, not the new top + two columns.** Decide whether to match the board.
- `TodayRoute.wordCookies`, a Today card hidden when the day has no `wordCookies`, `"wordCookies"` in `V1Games.keys` (x/3), DEBUG `-todayOpen wordCookies` / `-todaySheet wordCookies`.
- `TodayDestination` passes `saved:` from `appState.todayLog` and calls `appState.record(.game(key: "wordCookies", ...), minutes:, words:)`, sending `words:` only on the first finish.
- `TodayInfo.wordCookies` text says "The longest word is from today's vocab" and "Every word is on the grid": **update to the new design** (deck word on top; English shows when found).

## Still to do (in order)
1. ~~Sai checks the screen~~ ✅ Nov 27, looks good.
2. ~~Re-seed Firestore~~ ✅ Nov 27, 7 `dailyPuzzles` docs updated. **Tell relturu.**
3. ~~Commit~~ ✅ Nov 27, on `add-word-cookie` (local, not pushed).
4. ~~Step D animations~~ ✅ Nov 27, committed.
5. Finish Step 5 (preview layout + info text), then tick steps 4–5 in `plan.md` and update its Step 4 description to the new layout.
6. Step 6: `docs/app-guide.md`, tell Arielle (Today, word bank) and relturu (seed).

## How the app works (so you don't need to re-explore)
- **Loading:** `TodayModel.load` finds the content day (same weekday as one of the 7 seeded days, Oct 24–30), then reads `vocabLessons/{lang}_{day}`, `dailyPuzzles/{lang}_{day}` and the deck's `words`. Game screens never fetch anything themselves.
- **Saving:** `appState.record(...)` runs one Firestore transaction for the daily log, XP, streak and the word bank. XP only on the first finish; a completed result is never overwritten. A restored game ignores saved words that aren't on the current list.
- **Ground rules from `CLAUDE.md`:** the repo is **public** (no secrets); only seed scripts write content collections; date IDs are `{lang}_{yyyy-MM-dd}`; no arrays inside arrays.
- **Commands:** `node scripts/check-seed.js`; build and test with the Xcode `BuildProject` and `RunAllTests` tools (run them one at a time, not in parallel). `RenderPreview` times out on this project, so ask Sai to look instead.
- New files in the app/test folders are picked up automatically (synchronized folders), no project-file edits needed.

# Word Cookies: handoff for a new chat

_Written Nov 27, 2026. Paste this into the new chat, or ask Claude to read `docs/word-cookies-handoff.md`. When the build is finished, delete this file; `docs/plan.md` is the permanent record._

## Who I am and how to work with me
- I'm Sai (CMU 67-443, Fluent·ish team). I'm building a new game, **Word Cookies**, on branch **`add-word-cookie`**.
- Read `CLAUDE.md` and the **"Word Cookies"** section of `docs/plan.md` first. That section is the source of truth for this game: decisions, data format, and a checklist of 6 steps.
- **Work one step at a time.** Explain *why* each change is made, and give me a test to run before moving on.
- **After every change, tell me what I should see in the UI.** If nothing changes on screen, say so and say when it will.
- **Ask before** uploading to Firestore (`seed.js`), committing, or starting the next step.
- Only change what the step needs. Game, Progress, Friends and Settings screens belong to teammates.

## The game
- Each day, one word from that day's Daily Vocab deck (the **base word**) is broken into letter tiles arranged in a circle.
- The player drags across tiles to spell Spanish words made only from those letters.
- A grid of blank slots shows how many words there are and how long each is. The base word is always one of them.
- A found word fills its slots and shows its English translation.
- The game is done when every word is found. There's a Shuffle button.
- There's one puzzle per day, and it's the same for everyone.

## Decisions (all settled, don't re-ask)
| Topic | Decision |
|---|---|
| Base word | Any one word from that day's deck: a single word (no phrases) with 6–9 letters. Picked by hand in the seed, *not* "the longest". |
| Other words | 5–8 words total (not 10–14), 3+ letters, including the base word. **Only the base word must be a deck word**; the others are everyday A1–A2 words. |
| Word forms | Dictionary forms only: singular nouns, infinitive verbs, masculine singular adjectives (*rosa* not *rosas*, *ser* not *eres*). Neutral Spanish (no *mesero*). |
| Not on the list | A real word that isn't on the list just shakes. There's no dictionary and no bonus words. |
| Tiles | Uppercase with every accent dropped (á→A, è→E, ç→C), except **Ñ stays its own tile**. Language-neutral, so new languages need only seed data, not code. Each tile is used once per word. |
| Hints | Tapping Hint reveals the leftmost hidden letter of the first unfound word (in grid order) that still has **2+ hidden letters**, so a hint never completes a word. **Max 3 per puzzle.** Each costs −5 XP (the existing `ProgressRules.hintPenaltyXP`). |
| Score / XP | Score is always 1.0 (you can't lose). XP = 30 − 5 × hints, via `ProgressRules.gameXP(score:hintsUsed:)`. |
| Word bank | On the **first** finish, send `VocabAnswer`s for found words that have a `wordId` (the base word always does). A word counts as correct if none of its letters were revealed by a hint. |
| Same for everyone | Yes. No personal-word mixing, unlike Connections. |
| Word Guess | Will be **removed** after Word Cookies is done. **Word Cookies must not use any Word Guess code**: not `GameRules.normalize` (it turns Ñ into N anyway), `WordGuessPreview`, `GameMix.wordGuessAnswers`, or the Word Guess checks' variables in `check-seed.js`. When Word Guess is removed, check whether `GameRules.normalize` is used anywhere else before deleting it. |
| Other languages | No code changes needed. Each language just needs its own `dailyPuzzles/{lang}_{date}.wordCookies` in the seed (Sean's V2 "other languages" item). Keep screen text language-neutral ("Spell words using these letters"). |

**Approved base words:** Sat sobremesa · Sun regatear · Mon atardecer · Tue ascensor · Wed sorpresa · Thu compañero · Fri descansar.

## Progress
| Step | Status |
|---|---|
| 1. Data model | ✅ Done. Builds, 263/263 tests pass |
| 2. Seed + checks | ✅ Done. Lists approved and uploaded to Firestore Nov 27 (7 `dailyPuzzles` docs) |
| 3. Game rules + tests | ✅ Done Nov 27. 286/286 tests pass (23 new) |
| 4. Game screen | Not started |
| 5. Today wiring | Not started |
| 6. Docs + tell teammates | Not started |

**Nothing is committed and nothing is uploaded.** Uncommitted changes on `add-word-cookie`:
- `FluentIsh/FluentIsh/Models/FirestoreModels.swift`
- `scripts/schemas.js`
- `scripts/check-seed.js`
- `firebase/seed/dailyPuzzles.json`
- `docs/plan.md`
- this file

### Step 1: what exists now
- **`WordCookiesWord`** `{ word: String ("área", with accents), en: String, wordId: String? }`
- **`WordCookiesPuzzle`** `{ baseWordId: String, letters: String ("REGATEAR", tile form), words: [WordCookiesWord] }`
- **`DailyPuzzle.wordCookies: WordCookiesPuzzle? = nil`.** It's optional so the app still loads Firestore data that doesn't have the field yet.
- **`GameResult.foundWords: [String]? = nil`** holds found words in tile form, e.g. `"TAREA"`.
- **`GameResult.revealedLetters: [String]? = nil`** holds hint cells as `"WORD:index"`, e.g. `"TAREA:0"`. They're plain strings because Firestore doesn't allow arrays inside arrays.
- **`hintsUsed`** (already existed) is reused.
- **Daily log key:** the game saves under `"wordCookies"` in `dailyLog.games`. `check-seed.js` allows that key and expects score 1.0.

### Step 2: what exists now
- **Seed data:** `dailyPuzzles.json` has a `wordCookies` section for all 7 days (52 words). Words are listed shortest first, and 10 have a `wordId` (the 7 base words, plus acera, perro and casa).
- **`check-seed.js`:** it now requires `wordCookies` on every day. The new `checkWordCookies()` uses its own `tileLetters()` (keeps Ñ) and its own deck lookup. It checks:
  - the base word is in that day's deck, is one word, and has 6–9 letters
  - `letters` is the base word's tiles
  - there are 5–8 words; each has 3+ letters, isn't repeated, fits the tiles (counting repeats) and has English
  - every `wordId` exists and is the same word
  - the base word is in the list with its `wordId`
- **What it can't check:** it can't tell a plural from a dictionary form. That rule relies on whoever writes the lists.
- **Still to do:** after I approve, run `cd scripts && node seed.js --dry-run`, then `node seed.js`. It needs `firebase/serviceAccount.json`. Only the 7 `dailyPuzzles` docs should show as updated. Then tick Step 2 in `plan.md`. Optionally, add a `wordCookies` example to the `dailyPuzzles` sample in plan.md's "Sample records".

## Next steps (detail)
**Step 3: rules** (`Features/Games/WordCookies/WordCookiesGame.swift`)
- **Style:** a `nonisolated struct` with no UI and no Firebase, like `WordGuessGame` (the project defaults to MainActor).
- **Its own `tiles(_:)` normalizer:** uppercase, drop every accent mark except the tilde on N. Don't use `.folding(options: .diacriticInsensitive)`: it turns Ñ into N.
- **State:** tile order, found words, revealed cells. `init(puzzle:restoring saved: GameResult?)` restores from `foundWords` and `revealedLetters`.
- **`submit(tileIndices)`** returns found / alreadyFound / notInList / tooShort. A tile can't be used twice in one word.
- **`shuffle()`** is free and isn't saved.
- **`revealHint()`** follows the hint rule above; max 3, returns false when not allowed.
- **Rows:** sorted by length, then alphabetically.
- **Also:** `isComplete`, `hintsUsed`, and a `result` that builds the `GameResult`.
- **Elsewhere:** add `ProgressRules.wordCookiesScore()` (= 1.0) and `GameMix.wordCookiesAnswers(...)`.
- **Tests** (Swift Testing) in `FluentIshTests/WordCookiesGameTests.swift`: repeated letters, a tile reused, accents, Ñ, already found, hint cap, a hint never completing a word, restoring, completion, XP with hints.
- **UI:** no visible change in Step 3; it's logic and tests only.

**Step 4: screen** (`Features/Games/WordCookies/WordCookiesView.swift`)
- **Layout:**
  - `GameHeaderBar` (`title`, `onHowToPlay`, `onHint`, `badge`) and a How to Play sheet
  - the slot grid (5–8 rows); found words show their English, and hinted letters show in their slots
  - the tile circle, with one `DragGesture` for the whole circle. Dragging over a tile adds it, and dragging back onto the previous tile removes it. The word being spelled shows above the circle.
  - Shuffle and Hint (x/3) buttons
- **Feedback:** `ShakeEffect` on a wrong word, `CelebrationOverlay` when finished, a result card with XP and the hint penalty, and `Haptics`.
- **VoiceOver:** tapping tiles plus a Submit button also works.
- **Saving:** through an `onSave: (GameResult, minutes) async throws -> ActivityOutcome` closure after each found word and each hint. This is the same *pattern* as `WordGuessView`, written fresh, not shared.
- **Styling:** `.jakarta(size, weight)` fonts, `Color.ink/.inkMuted/.canvas/.card/.flame/.hairline`, and `.buttonStyle(.tactile(...))`.

**Step 5: Today** (`Features/Today/TodayModel.swift`, `TodayView.swift`, `TodayCards.swift`)
- **Today screen:**
  - add `TodayRoute.wordCookies`
  - add a `TodayCard` with `GameCardHeader` and a new `WordCookiesPreview` (slot rows, filled in when found)
  - add `TodayInfo.wordCookies`
  - **hide the card if the day has no `wordCookies`**
- **Opening the game:** the `TodayDestination` case passes `saved: appState.todayLog?.games["wordCookies"]` and calls `appState.record(.game(key: "wordCookies", result:), minutes:, words:)`. It sends `words:` only on the first finish.
- **Counter:** add `"wordCookies"` to `V1Games.keys`. It shows x/3 until Word Guess is removed.
- **DEBUG:** add `-todayOpen wordCookies` and `-todaySheet wordCookies` in `openDebugSheet()`.
- **Progress tab:** needs no change. It counts any game in `log.games` that's `.completed`.

**Step 6:** add Word Cookies to `docs/app-guide.md`, tick `plan.md`, and tell Arielle (Today, word bank) and relturu (seed) before merging.

## How the app works (so you don't need to re-explore)
- **Loading:** `TodayModel.load` finds the content day (same weekday as one of the 7 seeded days, Oct 24–30). Then it reads `vocabLessons/{lang}_{day}`, `dailyPuzzles/{lang}_{day}` and the deck's `words`. Game screens never fetch anything themselves; their data is passed in.
- **Saving:** `appState.record(...)` runs one Firestore transaction for the daily log, XP, streak and the word bank. XP is only given the first time a game finishes, and a completed result is never overwritten.
- **Ground rules from `CLAUDE.md`:**
  - the repo is **public**, so never commit secrets
  - only the seed scripts write content collections
  - date IDs are `{lang}_{yyyy-MM-dd}`
  - no arrays inside arrays
- **Commands:**
  - check the seed: `node scripts/check-seed.js`, or `--seed-dir <copy>` to test a broken copy
  - build and test with the Xcode `BuildProject` and `RunAllTests` tools; the simulator must be on iOS 27

# Fluent·ish — notes for Claude Code

Fluent·ish is an iOS language-learning app with NYT-style games (SwiftUI + Firebase Firestore + Azure Translator), built for CMU 67-443.

**Before doing anything, read `docs/plan.md`.** It is the source of truth for the data model, rules, indexes and build tasks. Its top section, "Team decisions & progress", shows what's done and who owns what. Check it before starting, and tick boxes as you finish steps.

If you're working on Azure Translator / API, see "Remaining Azure steps" in `docs/plan.md` and the Azure sections of `README.md`.

## Ground rules
- **This repo is PUBLIC.** Never commit `serviceAccount.json`, `GoogleService-Info.plist`, `.env`, `Secrets.xcconfig` or any API key. Run `git status` before committing. A playground containing a real Azure key goes on Canvas, not GitHub.
- Don't rename fields or collections without updating `docs/plan.md` and the Swift models in the same change.
- Date-based document IDs are always `{language}_{yyyy-MM-dd}` (e.g. `es_2026-10-24`).
- No arrays inside arrays in Firestore data (the crossword grid is one string per row, with `#` for black squares).
- Only the seed scripts (Admin SDK) write content collections. The app only reads them.
- Spanish content is written at B1 level (easy exercises: A2) and stays neutral between Spain and Latin America where possible.
- Sprint 4 (V1) builds the app screens from the AI Studio design. Follow "V1 app build" in `docs/plan.md` one step at a time. Game, Progress, Friends and Settings screens belong to teammates: only build filler for them unless asked.
- The person you're working with wants to understand each step. Explain why, and give a test to run before moving on.

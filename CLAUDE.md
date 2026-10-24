# Fluent·ish — notes for Claude Code

Fluent·ish is an iOS language-learning app with NYT-style games (SwiftUI + Firebase Firestore + Azure Translator), built for CMU 67-443.

**Before doing anything, read `docs/plan.md`.** It is the source of truth for the data model, rules, indexes and build tasks. Its top section, "Team decisions & progress", shows what's done and who owns what. Check it before starting, and tick boxes as you finish steps.

If you're working on Azure Translator / API, follow `docs/azure-handoff.md` (once it exists).

## Ground rules
- **This repo is PUBLIC.** Never commit `serviceAccount.json`, `GoogleService-Info.plist`, `.env`, `Secrets.xcconfig` or any API key. Run `git status` before committing. A playground containing a real Azure key goes on Canvas, not GitHub.
- Don't rename fields or collections without updating `docs/plan.md` and the Swift models in the same change.
- Date-based document IDs are always `{language}_{yyyy-MM-dd}` (e.g. `es_2026-10-24`).
- No arrays inside arrays in Firestore data (the crossword grid is one string per row, with `#` for black squares).
- Only the seed scripts (Admin SDK) write content collections. The app only reads them.
- Spanish content is written at B1 level and stays neutral between Spain and Latin America where possible.
- This sprint covers data, the API and seeding. **Ask before building app screens.**
- The person you're working with wants to understand each step. Explain why, and give a test to run before moving on.

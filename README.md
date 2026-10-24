# fluent-ish
Games + a little bit of language learning. Fluent·ish is an iOS app (SwiftUI) with NYT-style daily word games for Romance languages, backed by Firebase Firestore and Azure Translator.

## Start here
- `docs/plan.md`: the data plan and source of truth. Its top section tracks team progress.
- `CLAUDE.md`: context Claude Code loads automatically.
- `docs/azure-handoff.md`: step-by-step guide for the Azure Translator work (coming soon).

## Secrets (this repo is public)
Never commit these. They're gitignored, so ask a teammate for them privately:
- `firebase/serviceAccount.json` (Firebase Admin key, used by `scripts/`)
- `FluentIsh/FluentIsh/GoogleService-Info.plist` (Firebase iOS config)
- `scripts/.env`: copy from `scripts/.env.example`
- `FluentIsh/Secrets.xcconfig`

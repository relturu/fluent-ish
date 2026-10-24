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

## Azure seed enrichment

Once `firebase/seed/words.json` and `firebase/seed/dailyPrompts.json` exist, copy
`scripts/.env.example` to `scripts/.env` and set `AZURE_KEY` and `AZURE_REGION`
to your Translator resource values. `AZURE_ENDPOINT` is optional and defaults
to Microsoft's public Translator endpoint. The `.env` file is gitignored.

Run the enrichment before uploading seed data:

```sh
node scripts/enrich-azure.js
```

The script adds dictionary translations and fills missing example pairs and
prompt translations. It preserves handwritten definitions and existing
examples. A second run skips records already enriched. Use `--help` for options
to point it at a different seed directory or specific JSON files.

## Azure Translator service

`AzureTranslator` exposes async `dictionaryLookup`, `dictionaryExamples`,
`translate`, and `detectLanguage` methods. It accepts an injected configuration;
`AzureTranslator.Configuration.from(bundle:)` reads `AZURE_KEY`,
`AZURE_REGION`, and optional `AZURE_ENDPOINT` values from the app's Info.plist.

When the Xcode project is available, create the gitignored
`FluentIsh/Secrets.xcconfig` with the credential values and set it as the
app target's Base Configuration. In the target build settings, map the
xcconfig values into generated Info.plist keys:

```text
INFOPLIST_KEY_AZURE_KEY = $(AZURE_KEY)
INFOPLIST_KEY_AZURE_REGION = $(AZURE_REGION)
INFOPLIST_KEY_AZURE_ENDPOINT = $(AZURE_ENDPOINT)
```

Then configure the service with:

```swift
let configuration = try AzureTranslator.Configuration.from(bundle: .main)
let translator = AzureTranslator(configuration: configuration)
let results = try await translator.dictionaryLookup(text: "charlar")
```

Embedding a subscription key in an iOS app is suitable only for this classroom
demonstration: a key packaged in a client app can be extracted. Production
requests should go through a secure backend or equivalent credential-protection
architecture. Never commit a real key or `Secrets.xcconfig`.

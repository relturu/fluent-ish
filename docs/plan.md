# Fluent·ish: Firestore Setup & Azure Translator Plan

_Created Oct 23, 2026. This doc is the source of truth. If a field name changes, update this doc and the Swift models together._

---

## Team decisions & progress

**Read this first.** It records decisions made after the original plan was written and where the team is now.

### Decisions
- **The repo is PUBLIC** (`github.com/relturu/fluent-ish`). Never commit `firebase/serviceAccount.json`, `GoogleService-Info.plist`, `.env`, `Secrets.xcconfig` or any key. `.gitignore` covers these, but check `git status` before every commit anyway. The playground with the real Azure key is submitted on **Canvas only**.
- **Ownership:** Firebase/Firestore (build tasks 1–4, 6, 7, 9): **relturu**. Azure Translator / API (build tasks 5, 8): **teammate**, following `docs/azure-handoff.md`.
- **Seed data works without Azure.** `definitionEn`, `example`, `exampleEn` and `textEn` are written by hand, so the app has complete data before enrichment. Azure enrichment adds the `azure` field and fills gaps, then `seed.js` is re-run. It's idempotent, so re-running is safe.
- **Firebase project:** ID `fluent-ish-9d543` (display name `fluent-ish`). Firestore `(default)` database, Standard edition, location `nam7` (US). Anonymous auth is enabled. The iOS app is registered with bundle ID **`edu.cmu.relturu.FluentIsh`**; the Xcode project must use exactly this ID. Teammates: ask relturu to add you under Project settings → Users and permissions, and to send you `serviceAccount.json` and `GoogleService-Info.plist` privately.
- **Layout:** Xcode creates `FluentIsh/FluentIsh.xcodeproj` with sources in `FluentIsh/FluentIsh/`. Swift files go in `FluentIsh/FluentIsh/Models/` and `FluentIsh/FluentIsh/Services/`. Firebase config lives in lowercase `firebase/`.

### Progress — Firebase (relturu)
- [x] 0. Repo hygiene: `.gitignore`, `CLAUDE.md`, this doc, `.env.example`
- [x] 1. Xcode project `FluentIsh` + firebase-ios-sdk (FirebaseAuth, FirebaseFirestore). Uses synchronized folders, so files added under `FluentIsh/FluentIsh/` are compiled automatically. **Turn off Xcode → Settings → Source Control → "Add and remove files automatically"**: it stages gitignored files like `GoogleService-Info.plist`.
- [x] 2. Firebase project, `GoogleService-Info.plist`, Firestore DB, Anonymous auth, `FirebaseApp.configure()`. The app signs in anonymously on launch (`FluentIshApp.swift`) and keeps the same uid across launches.
- [x] 3. `FirestoreModels.swift` + `AzureModels.swift` compile (`FluentIsh/FluentIsh/Models/`)
- [x] 4. Firebase CLI, `firestore.rules` + `firestore.indexes.json` deployed. Deploy with `cd firebase && firebase deploy --only firestore:rules,firestore:indexes`. Check with `node scripts/test-rules.js` (12 allow/deny checks, all pass)
- [ ] 5. Seed JSON for every collection + `scripts/check-seed.js` passes
- [ ] 6. `scripts/seed.js` writes everything; second run changes nothing
- [ ] 7. `scripts/verify.js` + in-app DEBUG smoke test pass
- [ ] 8. `docs/sample-data.json` + console screenshots / TA added as Viewer
- [ ] 9. `docs/azure-handoff.md` written for the Azure teammate

### Progress — Azure (teammate)
- [ ] Azure for Students + Translator F0 resource, key in `scripts/.env`
- [ ] `Playgrounds/AzureTranslator.playground`: all 4 calls print parsed values
- [ ] `scripts/enrich-azure.js` run, seed re-uploaded
- [ ] `FluentIsh/FluentIsh/Services/AzureTranslator.swift`

---

## Overview

Firestore stores everything the app owns: user profiles, progress, daily puzzle content, vocabulary and social posts. Azure Translator is only used for on-demand language help: meanings, example sentences and "what does this say?" translations. Results from Azure get cached into Firestore, so each word is looked up once rather than on every screen load.

| Layer | Holds | Screens |
|---|---|---|
| Firestore: user data | Profile, settings, per-language XP/level/streak, word mastery, daily results | Today, Progress, Settings |
| Firestore: content | Words, vocab lessons, daily puzzles, exercises, quests, daily prompts | Today, Progress, Friends |
| Firestore: social | Friends, posts, likes, leaderboard periods | Friends |
| Azure Translator | Dictionary lookups, example sentences, sentence translation, language detection | Today (info buttons, hints), Friends (prompt and posts) |
| On the device only | Active tab, search text, filters, and device preferences (dark mode, audio, reminder) in `@AppStorage` | All tabs |

The app is designed to support several Romance languages (Spanish, French, Italian, Portuguese per Settings). Every content collection carries a `language` field, and progress is stored per language.

## Firestore setup steps

The free Spark plan covers everything below. Azure is billed separately, so you don't need to upgrade Firebase.

1. **Create the project.** In the Firebase console, add a project, then add an iOS app using your Xcode bundle ID. Download `GoogleService-Info.plist` and drag it into the Xcode project.
2. **Add the SDK.** In Xcode, add the firebase-ios-sdk package with Swift Package Manager and select FirebaseAuth and FirebaseFirestore.
3. **Configure on launch.** Call `FirebaseApp.configure()` in your App init or AppDelegate.
4. **Create the database.** Go to Build > Firestore Database > Create. Pick a US location; this can't be changed later. Start in test mode while building, but replace those rules before test mode expires (see below).
5. **Turn on Authentication.** Enable Anonymous sign-in for now, and add Email or Sign in with Apple later. Use the signed-in user's uid as the document ID in `users`.
6. **Seed the content.** Add one real record per collection by hand in the console, or with a one-off seed script. The rubric requires at least one populated record in each collection.
7. **Add indexes when asked.** The leaderboard query (below) needs a composite index. Firestore's error message includes a link that creates it in one click.
8. **Give the TA access.** In Project settings > Users and permissions, add the TA as a Viewer. Also take a screenshot of each populated collection as a backup.

## Starter security rules

These rules let users edit only their own data, let all signed-in users read shared content, and let the leaderboard read everyone's progress.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function isMe(uid) { return signedIn() && request.auth.uid == uid; }

    match /users/{uid} {
      allow read: if signedIn();
      allow write: if isMe(uid);
      match /progress/{lang} {
        allow read: if signedIn();          // leaderboards
        allow write: if isMe(uid);
      }
      match /{sub=**} { allow read, write: if isMe(uid); }
    }
    match /{path=**}/progress/{lang} {     // collection-group leaderboard query
      allow read: if signedIn();
    }

    // Shared content: read-only in the app, edited in the console
    match /words/{id}              { allow read: if signedIn(); }
    match /vocabLessons/{id}       { allow read: if signedIn(); }
    match /dailyPuzzles/{id}       { allow read: if signedIn(); }
    match /exercises/{id}          { allow read: if signedIn(); }
    match /quests/{id}             { allow read: if signedIn(); }
    match /dailyPrompts/{id}       { allow read: if signedIn(); }
    match /leaderboardPeriods/{id} { allow read: if signedIn(); }

    match /posts/{postId} {
      allow read: if signedIn();
      allow create: if signedIn() && request.resource.data.authorId == request.auth.uid;
      allow update: if signedIn();          // likesCount; tighten in V2
      allow delete: if isMe(resource.data.authorId);
      match /likes/{likerId} {
        allow read: if signedIn();
        allow write: if isMe(likerId);
      }
    }
  }
}
```

Shared content is read-only in the app. The seed scripts write it with the Firebase Admin SDK, which bypasses these rules, so Azure results get cached into content at seed time rather than from the app. V1 friend lists are seeded the same way. Letting users add each other is a V2 rule change, because adding a friend means writing to the other person's friends list.

## Collection structure

The design has a `users` collection with 4 subcollections, plus 8 top-level content and social collections. Date-based documents use `{language}_{date}` IDs (e.g. `es_2026-10-24`) so the app can fetch today's document directly without running a query.

| Collection | Document ID | Feeds these wireframe boxes |
|---|---|---|
| `users` | auth uid | Greeting, Settings profile, Preferences, Daily Goal target |
| `users/{uid}/progress` | language code (`es`) | Level, total XP, weekly XP, streak, Player Stats, leaderboard rank |
| `users/{uid}/wordProgress` | word ID | 70/30 split, words learned, recall %, Word Log mastery |
| `users/{uid}/dailyLog` | `es_2026-10-24` | Daily Goal minutes ring, Today's Games 0/3 status, Recent Activity, Quest Path days |
| `users/{uid}/friends` | friend's uid | Friends leaderboard, Friend Highlights feed |
| `words` | slug, e.g. `w_sobremesa` | Word Log, vocab lesson cards, Definition Match |
| `vocabLessons` | `es_2026-10-24` | Daily Vocab card |
| `dailyPuzzles` | `es_2026-10-24` | Connections, Word Guess, Mini Crossword |
| `exercises` | auto ID | Skill Exercises list (Easy/Medium/Hard) |
| `quests` | `es_28day` | Quest Path map, mascot quest message |
| `dailyPrompts` | `es_2026-10-24` | Daily Spanish Prompt |
| `posts` (+ `likes` sub) | auto ID | Friend Highlights, prompt answers, likes |
| `leaderboardPeriods` | `2026-W43` | Weekly Cup label and dates |

## Sample records

```jsonc
// users/u_sofia
{
  "displayName": "Sofía Martínez",
  "username": "sofia",
  "avatarInitials": "SM",
  "avatarColor": "#E8743B",
  "nativeLanguage": "en",
  "targetLanguage": "es",
  "settings": {
    "dailyGoalMinutes": 10
  },
  "createdAt": "2026-09-10T14:00:00Z"
}

// users/u_sofia/progress/es
{
  "language": "es",
  "level": "B1",
  "xp": 1245,
  "weeklyXP": 1245,
  "weekId": "2026-W43",
  "currentStreak": 14,
  "longestStreak": 14,
  "lastActiveDate": "2026-10-23",
  "wordsLearned": 312,
  "reviewsCorrect": 1780,
  "reviewsTotal": 2000,
  "displayName": "Sofía Martínez",
  "avatarInitials": "SM"
}

// users/u_sofia/wordProgress/w_sobremesa
{
  "wordId": "w_sobremesa",
  "language": "es",
  "status": "familiar",          // new | learning | familiar | mastered
  "timesSeen": 6,
  "timesCorrect": 5,
  "lastReviewed": "2026-10-22T19:05:00Z",
  "nextReview": "2026-10-25"
}

// users/u_sofia/dailyLog/es_2026-10-24
{
  "date": "2026-10-24",
  "language": "es",
  "vocabCompleted": true,
  "vocabScore": 0.9,
  "games": {
    "connections": { "status": "completed", "score": 0.96, "mistakes": 1, "solvedGroups": [0, 1, 2, 3] },
    "wordGuess":   { "status": "inProgress", "guesses": ["CHARLO"], "score": null },
    "crossword":   { "status": "notStarted", "filledCells": [], "score": null }
  },
  "exercisesCompleted": ["ex_fill_001"],
  "xpEarned": 85,
  "minutesSpent": 12
}

// users/u_sofia/friends/u_maya
{
  "friendId": "u_maya",
  "status": "accepted",           // pending | accepted
  "since": "2026-09-15T00:00:00Z"
}

// words/w_sobremesa
{
  "language": "es",
  "term": "la sobremesa",
  "lemma": "sobremesa",
  "gender": "f",
  "partOfSpeech": "noun",
  "definitionEn": "relaxed conversation at the table after a meal",
  "category": "Culture & Idioms",
  "level": "B1",
  "example": "La sobremesa duró dos horas.",
  "exampleEn": "The after-dinner chat lasted two hours.",
  "azure": { "translations": ["after-dinner conversation"], "fetchedAt": "2026-10-20T00:00:00Z" }
}

// vocabLessons/es_2026-10-24
{
  "language": "es",
  "date": "2026-10-24",
  "title": "La Sobremesa",
  "wordCount": 10,
  "reviewRatio": 0.7,
  "newWordIds": ["w_sobremesa", "w_cortado", "w_merienda"]
}

// dailyPuzzles/es_2026-10-24
{
  "language": "es",
  "date": "2026-10-24",
  "connections": {
    "groups": [
      { "category": "Cosas del café", "words": ["cortado", "taza", "azúcar", "leche"], "difficulty": 1 },
      { "category": "Conectores", "words": ["además", "sin embargo", "aunque", "pues"], "difficulty": 2 },
      { "category": "Verbos sociales", "words": ["charlar", "compartir", "brindar", "invitar"], "difficulty": 3 },
      { "category": "Momentos del día", "words": ["merienda", "siesta", "madrugada", "sobremesa"], "difficulty": 4 }
    ]
  },
  "wordGuess": { "answer": "CHARLA", "length": 6, "definitionEn": "a chat, a talk" },
  "crossword": {
    "size": 5,
    "solution": ["TARDE", "A#I#N", "COSTE", "O#A#R", "SUSTO"],
    "cluesAcross": [
      { "number": 1, "row": 0, "col": 0, "clue": "Parte del día después del mediodía", "answer": "TARDE" },
      { "number": 4, "row": 2, "col": 0, "clue": "Lo que cuesta algo", "answer": "COSTE" },
      { "number": 5, "row": 4, "col": 0, "clue": "Lo que sientes al ver un fantasma", "answer": "SUSTO" }
    ],
    "cluesDown": [
      { "number": 1, "row": 0, "col": 0, "clue": "Comida mexicana con tortilla", "answer": "TACOS" },
      { "number": 2, "row": 0, "col": 2, "clue": "Nunca faltan en la sobremesa", "answer": "RISAS" },
      { "number": 3, "row": 0, "col": 4, "clue": "Primer mes del año", "answer": "ENERO" }
    ]
  }
}

// exercises/ex_fill_001
{
  "language": "es",
  "type": "fillBlank",          // fillBlank | sentenceBuilder | definitionMatch
  "title": "Fill in the Blank",
  "subtitle": "Completa la Frase",
  "difficulty": "medium",
  "items": [
    { "prompt": "Después de cenar, nos gusta ___.", "answer": "charlar", "choices": ["charlar", "correr", "dormir"] }
  ]
}

// quests/es_28day
{
  "language": "es",
  "lengthDays": 28,
  "days": [
    { "day": 1, "title": "Primer café", "tier": "L1", "rewardXp": 20, "mascotMessage": "¡Vamos!" },
    { "day": 28, "title": "Churro's Quest", "tier": "L3", "rewardXp": 200, "mascotMessage": "¡14 días invictos!" }
  ]
}

// dailyPrompts/es_2026-10-24
{
  "language": "es",
  "date": "2026-10-24",
  "theme": "La Sobremesa",
  "text": "En nuestra sobremesa nunca falta ________.",
  "textEn": "Our after-meal chats are never missing ________."
}

// posts/p_123
{
  "authorId": "u_maya",
  "authorName": "Maya Lin",
  "authorHandle": "maya",
  "language": "es",
  "type": "promptResponse",      // promptResponse | achievement
  "promptId": "es_2026-10-24",
  "badge": "BEST FILL-IN OF THE DAY",
  "text": "En nuestra sobremesa nunca falta un cortado bien cargado y risas.",
  "likesCount": 18,
  "createdAt": "2026-10-24T13:32:00Z"
}

// posts/p_123/likes/u_sofia
{ "likedAt": "2026-10-24T14:00:00Z" }

// leaderboardPeriods/2026-W43
{
  "label": "Weekly Cup",
  "startDate": "2026-10-19",
  "endDate": "2026-10-25"
}
```

For the rubric's JSON document, remove the `//` comments, since real JSON doesn't allow them. The crossword grid is stored as one string per row, with `#` for black squares, because Firestore can't store an array inside an array.

## Key queries

- **Today screen:** read `vocabLessons/es_{today}`, `dailyPuzzles/es_{today}`, `users/{uid}/dailyLog/es_{today}`, and `users/{uid}/progress/es`.
- **Review words for the 70/30 split:** query `wordProgress` where `language == "es"` and `nextReview <= today`, limited to 7. This needs a composite index on language + nextReview.
- **Global leaderboard:** run a collection-group query on `progress` where `language == "es"` and `weekId == "2026-W43"`, ordered by `weeklyXP` descending. This needs a composite index. When a user earns XP and their `weekId` isn't the current week, the app first resets `weeklyXP` to 0 and updates `weekId`.
- **Friends leaderboard:** read the uids in `users/{uid}/friends`, then fetch `users/{friendId}/progress/es` for each friend.
- **Friend Highlights:** query `posts` where `authorId in [friend uids]`, ordered by `createdAt` descending. An `in` filter accepts up to 30 values, so split larger friend lists into batches.

## Swift structs

There is one Codable struct per document type, plus a struct for each nested object. `@DocumentID` fills in the document's ID when the app reads it. Dates stored as `"2026-10-24"` strings stay as `String`. Timestamps use `Date`, which Firestore converts automatically.

```swift
import FirebaseFirestore

// MARK: - User data

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    var displayName: String
    var username: String
    var avatarInitials: String
    var avatarColor: String
    var nativeLanguage: String
    var targetLanguage: String
    var settings: UserSettings
    var createdAt: Date
}

struct UserSettings: Codable {
    var dailyGoalMinutes: Int
}

struct LanguageProgress: Codable, Identifiable {   // users/{uid}/progress/{lang}
    @DocumentID var id: String?
    var language: String
    var level: String
    var xp: Int
    var weeklyXP: Int
    var weekId: String
    var currentStreak: Int
    var longestStreak: Int
    var lastActiveDate: String
    var wordsLearned: Int
    var reviewsCorrect: Int
    var reviewsTotal: Int
    var displayName: String
    var avatarInitials: String

    var recallRate: Double {          // 89% on Progress
        reviewsTotal == 0 ? 0 : Double(reviewsCorrect) / Double(reviewsTotal)
    }
}

enum WordStatus: String, Codable { case new, learning, familiar, mastered }

struct WordProgress: Codable, Identifiable {        // users/{uid}/wordProgress/{wordId}
    @DocumentID var id: String?
    var wordId: String
    var language: String
    var status: WordStatus
    var timesSeen: Int
    var timesCorrect: Int
    var lastReviewed: Date?
    var nextReview: String
}

enum GameStatus: String, Codable { case notStarted, inProgress, completed }

struct GameResult: Codable {
    var status: GameStatus
    var score: Double?
    var mistakes: Int?
    var solvedGroups: [Int]?          // Connections
    var guesses: [String]?            // Word Guess
    var filledCells: [String]?        // Crossword
    var hintsUsed: Int?
}

struct DailyLog: Codable, Identifiable {            // users/{uid}/dailyLog/{lang_date}
    @DocumentID var id: String?
    var date: String
    var language: String
    var vocabCompleted: Bool
    var vocabScore: Double?
    var games: [String: GameResult]   // "connections", "wordGuess", "crossword"
    var exercisesCompleted: [String]
    var xpEarned: Int
    var minutesSpent: Int

    var gamesCompleted: Int { games.values.filter { $0.status == .completed }.count }
}

struct Friend: Codable, Identifiable {              // users/{uid}/friends/{friendId}
    @DocumentID var id: String?
    var friendId: String
    var status: String                // "pending" | "accepted"
    var since: Date
}

// MARK: - Content

struct AzureCache: Codable {
    var translations: [String]
    var fetchedAt: Date
}

struct Word: Codable, Identifiable {
    @DocumentID var id: String?
    var language: String
    var term: String
    var lemma: String
    var gender: String?               // "m" | "f" | nil
    var partOfSpeech: String
    var definitionEn: String
    var category: String
    var level: String
    var example: String?
    var exampleEn: String?
    var azure: AzureCache?
}

struct VocabLesson: Codable, Identifiable {
    @DocumentID var id: String?
    var language: String
    var date: String
    var title: String
    var wordCount: Int
    var reviewRatio: Double
    var newWordIds: [String]
}

struct ConnectionsGroup: Codable {
    var category: String
    var words: [String]
    var difficulty: Int
}

struct ConnectionsPuzzle: Codable { var groups: [ConnectionsGroup] }

struct WordGuessPuzzle: Codable {
    var answer: String
    var length: Int
    var definitionEn: String
}

struct CrosswordClue: Codable {
    var number: Int
    var row: Int
    var col: Int
    var clue: String
    var answer: String
}

struct CrosswordPuzzle: Codable {
    var size: Int
    var solution: [String]            // one string per row, "#" = black square
    var cluesAcross: [CrosswordClue]
    var cluesDown: [CrosswordClue]
}

struct DailyPuzzle: Codable, Identifiable {
    @DocumentID var id: String?
    var language: String
    var date: String
    var connections: ConnectionsPuzzle
    var wordGuess: WordGuessPuzzle
    var crossword: CrosswordPuzzle
}

struct ExerciseItem: Codable {
    var prompt: String
    var answer: String
    var choices: [String]?
}

struct Exercise: Codable, Identifiable {
    @DocumentID var id: String?
    var language: String
    var type: String                  // fillBlank | sentenceBuilder | definitionMatch
    var title: String
    var subtitle: String
    var difficulty: String            // easy | medium | hard
    var items: [ExerciseItem]
}

struct QuestDay: Codable {
    var day: Int
    var title: String
    var tier: String                  // L1 | L2 | L3
    var rewardXp: Int
    var mascotMessage: String
}

struct Quest: Codable, Identifiable {
    @DocumentID var id: String?
    var language: String
    var lengthDays: Int
    var days: [QuestDay]
}

struct DailyPrompt: Codable, Identifiable {
    @DocumentID var id: String?
    var language: String
    var date: String
    var theme: String
    var text: String
    var textEn: String?               // filled by Azure /translate at seed time
}

// MARK: - Social

struct Post: Codable, Identifiable {
    @DocumentID var id: String?
    var authorId: String
    var authorName: String
    var authorHandle: String
    var language: String
    var type: String                  // promptResponse | achievement
    var promptId: String?
    var badge: String?
    var text: String
    var likesCount: Int
    var createdAt: Date
}

struct Like: Codable, Identifiable {                // posts/{postId}/likes/{uid}
    @DocumentID var id: String?
    var likedAt: Date
}

struct LeaderboardPeriod: Codable, Identifiable {
    @DocumentID var id: String?
    var label: String
    var startDate: String
    var endDate: String
}
```

Reading a document looks like this: `let log = try await db.document("users/\(uid)/dailyLog/es_2026-10-24").getDocument(as: DailyLog.self)`. Writing a struct uses `try db.collection("posts").addDocument(from: post)`.

## Gaps in the current mapping

The wireframe annotations cover what's on screen, but several things underneath them aren't mapped. Items marked Fix are worth correcting before you submit, because the TA will compare the wireframes to the data. The rest should go on the V1/V2 feature list.

### Fix before submitting
- **Daily Goal "Updates" line.** The goal is now minutes only, so "Updates" should say "when minutes are logged from a game, lesson or exercise." The ring reads `dailyLog.minutesSpent` against `settings.dailyGoalMinutes`.
- **Word count mismatch.** Player Stats shows 312 words, while the Word Log says 10 words. Label the Word Log as "this week" or "recent," or add paging.
- **Recall % has no source.** 89% has to come from stored review counts (`reviewsCorrect / reviewsTotal`). Add those fields to the Player Stats box.

Already resolved: the second Daily Goal (0/3 games) is removed, the app uses XP everywhere (leaderboard ranks by `weeklyXP`), `audioURL` is removed in favor of on-device speech, and the Navigation Bar box is removed.

### Data the screens imply but nobody has mapped
Defaults for streaks, levels, review intervals and scoring are set in the Claude Code handoff section below, so building isn't blocked. Change them there if your team decides differently.

- **Onboarding.** V1 uses Anonymous auth, so there's no login screen, but a first-launch screen still has to set the display name, target language and starting level.
- **Streak rules.** Define what counts as an active day (any game? the daily goal?), and which time zone "today" uses. Store `lastActiveDate` and `currentStreak`, and update them when the first activity of the day is logged.
- **Level thresholds.** "Next milestone: Level B2, 1,245 / 1,500 XP" needs a table of XP cutoffs per level, either hardcoded or in a config document.
- **The 70/30 review mix.** This needs spaced-repetition fields per word (`status`, `nextReview`) and a rule for when a word becomes "familiar" or "mastered."
- **In-progress games.** If a user leaves Connections halfway through, where do their guesses go? Save partial state in `dailyLog.games`.
- **Game scoring.** Recent Activity shows 96%, 91% and 88%. Define how each game turns into a percentage (mistakes, guesses used, hints taken).
- **Puzzle content itself.** Someone has to write a Connections set, a Word Guess answer and a crossword grid with clues for every day and every language. Seed about 5 days per game for the demo.
- **Word Guess validation.** Checking whether a guess is a real word needs a word list per language. Bundle it in the app rather than storing it in Firestore.
- **Skill exercise content.** The boxes map the exercise title and difficulty, but not the actual questions, answers and choices inside each exercise.
- **Word categories.** The filter chips (Connector, Café & Dining, Daily Verb, Culture & Idioms) need a `category` field on each word and a fixed list of categories.
- **Quest Path state.** Map where each day's tier color (L1/L2/L3/Mastered) comes from. This plan derives it from `dailyLog`, plus quest definitions in `quests`.
- **Mascot speech bubbles.** "¡Un cafecito y a jugar!" and Churro's quest message aren't mapped. Store them in content documents or hardcode a rotating list.
- **Adding friends.** There's no screen for finding or adding friends, accepting requests, or showing usernames (@maya). Add it to V2 if it's out of scope for V1.
- **Likes and "Best Fill-in" badge.** Store likes per user so nobody can like a post twice. Also decide who awards the badge: the most likes, or a fixed rule.
- **Achievement posts.** Posts like "Conexiones 4/4" and "250 words mastered" have to be created automatically when the event happens. Define which events create a post.
- **Moderation.** Users can post free text to friends. At minimum, add a way to report or delete a post.
- **Language switching.** Changing from Spanish to French should keep Spanish progress, which is why progress is stored per language. Also decide whether the streak is per language or overall.
- **Daily reminder.** The toggle needs a time field and a local notification. That notification is device-side, not Firestore.

## Azure Translator plan

The app uses 4 Translator endpoints. They're used in two ways: ahead of time, to fill in word meanings and examples when content is seeded, and on demand, for text the app can't know in advance (hints, friends' posts, prompt answers).

### Endpoints
All requests go to `https://api.cognitive.microsofttranslator.com` with `api-version=3.0`, as a POST with a JSON array body like `[{"Text": "..."}]`. Each request sends three headers: `Ocp-Apim-Subscription-Key`, `Ocp-Apim-Subscription-Region`, and `Content-Type: application/json`.

| Endpoint | What it returns | Used for |
|---|---|---|
| `/dictionary/lookup?from=es&to=en` | Alternate translations for one word or short phrase, with part of speech and confidence | Word meanings: vocab cards, info buttons, Word Log |
| `/dictionary/examples?from=es&to=en` | Example sentence pairs for a word plus a chosen translation | "See it in context" on vocab cards and exercises |
| `/translate?from=es&to=en` | A full sentence translation | Hints, prompt meaning, "translate" on friends' posts |
| `/detect` | The detected language with a score | Checking that a prompt answer is written in Spanish |

Dictionary Lookup and Examples only translate to or from English, which is fine for English-speaking learners. They can return an empty list for idioms (e.g. sobremesa). In that case, fall back to `/translate` or the `definitionEn` you wrote yourself.

### Where each screen uses it

| Screen | Feature | Endpoint | When it's called | Cached in |
|---|---|---|---|---|
| Today | Daily Vocab info button and lesson cards | Dictionary Lookup, then Examples | At seed time for lesson words | `words/{id}.azure`, `example`, `exampleEn` |
| Today | Connections hint ("show English for 1 word") | Dictionary Lookup | On tap, costs the player XP | Session only |
| Today | Word Guess: meaning after solving | Dictionary Lookup | At seed time | `dailyPuzzles.wordGuess.definitionEn` |
| Today | Mini Crossword: "translate this clue" | Translate | On tap | Session only |
| Today | Fill in the Blank / Sentence Builder hint | Translate (full sentence) | On tap | Session only |
| Today | Definition Match pairs | Dictionary Lookup | At seed time | `exercises.items` |
| Progress | Word Log definitions | None, reads `words` | — | Already in Firestore |
| Progress | Word Log search for a word not in the log | Dictionary Lookup | On search, optional V2 | Session only |
| Friends | Daily Prompt: "what does this mean?" | Translate | At seed time | `dailyPrompts.textEn` |
| Friends | Answer check before sharing | Detect | On submit | — |
| Friends | "Translate" button on a friend's post | Translate | On tap | Session only |
| Settings | Switching to French, Italian or Portuguese | Change the `from` code (fr / it / pt) | — | `users.targetLanguage` |

Audio for words and the "Spanish Audio" toggle aren't part of Translator. Use `AVSpeechSynthesizer` on the device with a voice such as es-ES or es-MX.

### Request and response shapes

```jsonc
// POST /dictionary/lookup?api-version=3.0&from=es&to=en
[{ "Text": "charlar" }]
// returns
[{
  "normalizedSource": "charlar",
  "displaySource": "charlar",
  "translations": [{
    "normalizedTarget": "chat",
    "displayTarget": "chat",
    "posTag": "VERB",
    "confidence": 0.62,
    "prefixWord": "",
    "backTranslations": [{ "normalizedText": "charlar", "displayText": "charlar", "numExamples": 15, "frequencyCount": 120 }]
  }]
}]

// POST /dictionary/examples?api-version=3.0&from=es&to=en
[{ "Text": "charlar", "Translation": "chat" }]   // Translation = normalizedTarget from the lookup
// returns
[{
  "normalizedSource": "charlar",
  "normalizedTarget": "chat",
  "examples": [{
    "sourcePrefix": "Nos gusta ", "sourceTerm": "charlar", "sourceSuffix": " después de cenar.",
    "targetPrefix": "We like to ", "targetTerm": "chat", "targetSuffix": " after dinner."
  }]
}]

// POST /translate?api-version=3.0&from=es&to=en
[{ "Text": "En nuestra sobremesa nunca falta un cortado." }]
// returns
[{ "translations": [{ "text": "Our after-dinner chats always include a cortado.", "to": "en" }] }]

// POST /detect?api-version=3.0
[{ "Text": "un cortado bien cargado y risas" }]
// returns
[{ "language": "es", "score": 1.0, "isTranslationSupported": true, "isTransliterationSupported": false }]
```

The values above show the response shape and are illustrative only. Copy real responses from your playground into the deliverable.

### Swift structs for Azure responses

```swift
struct DictionaryLookupResult: Codable {
    let normalizedSource: String
    let displaySource: String
    let translations: [DictionaryTranslation]
}

struct DictionaryTranslation: Codable {
    let normalizedTarget: String
    let displayTarget: String
    let posTag: String
    let confidence: Double
    let prefixWord: String
    let backTranslations: [BackTranslation]
}

struct BackTranslation: Codable {
    let normalizedText: String
    let displayText: String
    let numExamples: Int
    let frequencyCount: Int
}

struct DictionaryExampleResult: Codable {
    let normalizedSource: String
    let normalizedTarget: String
    let examples: [DictionaryExample]
}

struct DictionaryExample: Codable {
    let sourcePrefix: String, sourceTerm: String, sourceSuffix: String
    let targetPrefix: String, targetTerm: String, targetSuffix: String

    var sourceSentence: String { sourcePrefix + sourceTerm + sourceSuffix }
    var targetSentence: String { targetPrefix + targetTerm + targetSuffix }
}

struct TranslateResult: Codable { let translations: [TranslationText] }
struct TranslationText: Codable { let text: String; let to: String }

struct DetectResult: Codable {
    let language: String
    let score: Double
    let isTranslationSupported: Bool
    let isTransliterationSupported: Bool
}
```

## Azure setup, playground and checklist

### Azure setup
- [ ] One teammate signs up for Azure for Students with a school email (no credit card needed)
- [ ] Create a Translator resource in the Azure portal and choose the Free F0 pricing tier
- [ ] Write down the key, the region (e.g. eastus) and the endpoint from Keys and Endpoint
- [ ] Share the key and region privately with the team; don't commit them to a public repo

### Playground
Paste the Azure response structs above into the same playground, then add this code:

```swift
import Foundation
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

let key = "YOUR_KEY"
let region = "eastus"
let base = "https://api.cognitive.microsofttranslator.com"

func post<T: Decodable>(_ path: String, _ body: [[String: String]], as: T.Type) async throws -> T {
    var req = URLRequest(url: URL(string: base + path)!)
    req.httpMethod = "POST"
    req.setValue(key, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
    req.setValue(region, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, response) = try await URLSession.shared.data(for: req)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        print("HTTP \(http.statusCode):", String(data: data, encoding: .utf8) ?? "")
    }
    return try JSONDecoder().decode(T.self, from: data)
}

Task {
    do {
        // 1. Dictionary lookup: word meaning
        let lookup = try await post("/dictionary/lookup?api-version=3.0&from=es&to=en",
                                    [["Text": "charlar"]], as: [DictionaryLookupResult].self)
        guard let best = lookup.first?.translations.first else { print("No dictionary entry"); return }
        print("charlar →", best.displayTarget, "(\(best.posTag))")

        // 2. Examples for that word + translation
        let ex = try await post("/dictionary/examples?api-version=3.0&from=es&to=en",
                                [["Text": "charlar", "Translation": best.normalizedTarget]],
                                as: [DictionaryExampleResult].self)
        ex.first?.examples.prefix(2).forEach { print("  ", $0.sourceSentence, "→", $0.targetSentence) }

        // 3. Full-sentence translation (Daily Prompt)
        let tr = try await post("/translate?api-version=3.0&from=es&to=en",
                                [["Text": "En nuestra sobremesa nunca falta ________."]],
                                as: [TranslateResult].self)
        print("Prompt:", tr.first?.translations.first?.text ?? "")

        // 4. Detect language of a user answer
        let det = try await post("/detect?api-version=3.0",
                                 [["Text": "un cortado bien cargado y risas"]], as: [DetectResult].self)
        print("Detected:", det.first?.language ?? "?", det.first?.score ?? 0)
    } catch {
        print("Error:", error)
    }
    PlaygroundPage.current.finishExecution()
}
```

- [ ] Run the playground and confirm all 4 calls print parsed values, not raw JSON
- [ ] Try one French or Italian word (`from=fr`, `from=it`) to show multi-language support
- [ ] Save a sample response from each endpoint for the deliverable
- [ ] Leave the key in the submitted playground, as the rubric asks, and tell the TA it's a free-tier key. **(Canvas copy only. The repo is public, so the GitHub copy must not contain the key.)**

### Firestore deliverables
- [ ] Create the Firestore database and turn on Anonymous auth
- [ ] Add at least one record to every collection in the table above, including the 4 user subcollections
- [ ] Paste in the security rules
- [ ] Write the JSON document with one clean sample per collection, without `//` comments
- [ ] Take screenshots of each populated collection, or add the TA as a Viewer
- [ ] Put all structs (Firestore and Azure) in one Models.swift file for the team

### Shared deliverables
- [ ] Fix the "Fix before submitting" items in the wireframe annotations
- [ ] Label each wireframe box's source with real names: a Firestore path, an Azure endpoint, or "local state"
- [ ] Move the unmapped items above into the V1 or V2 feature list
- [ ] Tell the TA that Internal API and SwiftData don't apply, so those rows count as full credit

## Claude Code handoff

This section tells Claude Code what to build for the Sprint 3 data deliverables and in what order. The doc is the source of truth: if a field name changes, update this doc and the models together.

### Locked decisions
- **Storage:** Firestore for all app data. No SwiftData, and no internal API.
- **Auth:** Firebase Anonymous auth in V1, with no login screen. Sign-in and cross-device sync come in V2 by linking the anonymous account.
- **Device-only state:** dark mode, audio toggle and reminder settings use `@AppStorage`. Tabs, search and filters are view state.
- **Pronunciation:** `AVSpeechSynthesizer` on the device. No stored audio.
- **Scoring currency:** XP only. `xp` is lifetime XP and `weeklyXP` drives the leaderboard.
- **Daily goal:** minutes only (`settings.dailyGoalMinutes` vs. `dailyLog.minutesSpent`).
- **Language codes:** es, fr, it, pt. Seed Spanish only for V1.
- **Content writes:** only the seed scripts (Admin SDK) write content collections. The app reads them.

### Defaults to implement
These are reasonable starting values so building isn't blocked. The team can change them later.

| Rule | Default |
|---|---|
| "Today" | Device local date, formatted `yyyy-MM-dd` |
| Week ID | ISO week, e.g. `2026-W43`, starting Monday |
| Streak | A day counts if any XP is earned. If `lastActiveDate` is yesterday, +1; if today, no change; otherwise reset to 1 |
| Level floors (XP) | A1 0 · A2 300 · B1 800 · B2 1500 · C1 2500 · C2 4000 |
| Word status | Seen once → learning; 3 correct → familiar; 6 correct → mastered; a wrong answer drops one status |
| Review interval | learning 1 day · familiar 3 days · mastered 7 days |
| Words learned | Count of words that are familiar or mastered |
| 70/30 lesson | Up to 7 due review words plus 3 new words from `newWordIds`; fill with new words if fewer are due |
| XP | Vocab lesson 20 · each game 30 × score · each exercise 10 · each hint −5 |
| Connections score | `max(0, 1 − mistakes ÷ 4)` |
| Word Guess score | `(7 − guesses used) ÷ 6`, with 6 guesses allowed |
| Crossword score | `max(0, 1 − 0.1 × hintsUsed)` |
| Minutes | Time on a game, lesson or exercise screen, rounded up, added to `minutesSpent` |

### What the team does first
Claude Code can't do these steps itself, because they need your accounts or Xcode's interface.
- [ ] Create a GitHub repo and clone it _(done: public repo, see decisions above)_
- [ ] In Xcode, create a SwiftUI iOS app named FluentIsh inside the repo, then add the firebase-ios-sdk package with FirebaseAuth and FirebaseFirestore
- [ ] Create the Firebase project, add the iOS app, put `GoogleService-Info.plist` in the Xcode project, create the Firestore database and enable Anonymous auth
- [ ] Download a service account key (Project settings > Service accounts > Generate new private key) and save it as `firebase/serviceAccount.json`
- [ ] Create the Azure Translator F0 resource and note its key and region
- [ ] Install Node.js and the Firebase CLI (`npm install -g firebase-tools`, then `firebase login`)

### Repo layout
```
FluentIsh/                         Xcode project (team creates it)
  FluentIsh/Models/FirestoreModels.swift
  FluentIsh/Models/AzureModels.swift
  FluentIsh/Services/AzureTranslator.swift
  FluentIsh/Secrets.xcconfig       gitignored: AZURE_KEY, AZURE_REGION
Playgrounds/AzureTranslator.playground
firebase/
  firebase.json
  firestore.rules
  firestore.indexes.json
  seed/*.json                      one file per collection
  serviceAccount.json              gitignored
scripts/
  enrich-azure.js
  seed.js
  check-seed.js
  verify.js
  .env                             gitignored: AZURE_KEY, AZURE_REGION
docs/
  plan.md                          this doc
  azure-handoff.md                 step-by-step guide for the Azure teammate
  sample-data.json                 rubric deliverable
CLAUDE.md                          auto-loaded context for Claude Code
```

### Build tasks, in order
1. **Repo setup.** Add a `.gitignore` covering Xcode build files, `node_modules`, `serviceAccount.json`, `Secrets.xcconfig` and `.env`. Add `Secrets.example.xcconfig` and `.env.example` with placeholder values, plus a short README. _Done when:_ `git status` shows no secrets.
2. **Models.** Copy the Firestore structs into `FirestoreModels.swift` and the Azure response structs into `AzureModels.swift`. _Done when:_ the app builds.
3. **Rules and indexes.** Write `firebase.json`, `firestore.rules` (from this doc) and `firestore.indexes.json` (below), then run `firebase deploy --only firestore:rules,firestore:indexes`. _Done when:_ the deploy succeeds.
4. **Seed data.** Write Spanish seed JSON for every collection: 5 days (2026-10-24 to 10-28) of `dailyPuzzles`, `vocabLessons` and `dailyPrompts`; at least 30 words covering every word used in lessons and puzzles, with categories; 3 exercises (one per type); 1 `quests` document with all 28 days; 4 demo users (Sofía, Maya, Lucas, Elena) with progress, wordProgress, dailyLog and friends; several posts with likes; and the current `leaderboardPeriods` week. Every crossword must be valid, with all across and down answers being real Spanish words. Every referenced ID must exist. _Done when:_ a check script finds no missing IDs.
5. **Azure enrichment.** `scripts/enrich-azure.js` reads the words seed, calls Dictionary Lookup and Dictionary Examples, and fills in `azure`, `example` and `exampleEn`. It also calls `/translate` to fill in `dailyPrompts.textEn`. It keeps the handwritten `definitionEn` when a lookup comes back empty, and reads the key from `.env`. _Done when:_ every word has an example or a clear note that none was found.
6. **Seed script.** `scripts/seed.js` uses firebase-admin with the service account to write every collection and subcollection with fixed document IDs, so re-running it doesn't create duplicates. It must convert ISO date strings in `createdAt`, `since`, `lastReviewed`, `likedAt` and `azure.fetchedAt` into Firestore Timestamps; otherwise Swift can't decode them as `Date`. _Done when:_ every collection appears in the console, and running the script twice changes nothing.
7. **Verify.** `scripts/verify.js` reads one document from each collection and checks required fields. Also add a DEBUG-only check in the app that signs in anonymously and decodes one document of each type into its struct. _Done when:_ both report success.
8. **Azure service and playground.** Write `AzureTranslator.swift` with lookup, examples, translate and detect, reading the key from `Secrets.xcconfig`. Build `AzureTranslator.playground` from the playground code in this doc. _Done when:_ all 4 calls print parsed values.
9. **Deliverable export.** Generate `docs/sample-data.json` with one clean record per collection (valid JSON, no comments), plus screenshots of the populated collections. _Done when:_ the file passes a JSON validator.

### firestore.indexes.json
```json
{
  "indexes": [
    {
      "collectionGroup": "progress",
      "queryScope": "COLLECTION_GROUP",
      "fields": [
        { "fieldPath": "language", "order": "ASCENDING" },
        { "fieldPath": "weekId", "order": "ASCENDING" },
        { "fieldPath": "weeklyXP", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "wordProgress",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "language", "order": "ASCENDING" },
        { "fieldPath": "nextReview", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "posts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "authorId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### Ground rules for Claude Code
- Never commit keys, `serviceAccount.json` or `GoogleService-Info.plist`. **This repo is public.** The playground copy with a real key goes to Canvas, not GitHub.
- Don't rename fields or collections without updating `docs/plan.md` and the models together.
- Keep date-based IDs as `{language}_{yyyy-MM-dd}`.
- No arrays inside arrays in Firestore data.
- Write Spanish content at B1 level, natural and Spain/Latin-America neutral where possible.
- Ask before building app screens. This sprint covers data, the API and seeding, not UI.

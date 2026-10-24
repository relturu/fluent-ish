// Field schemas for every Firestore collection. They mirror the Swift structs in
// FluentIsh/FluentIsh/Models/FirestoreModels.swift: if you change a struct,
// change it here too. Used by check-seed.js (JSON files) and verify.js (live data).
//
// Types: string, int, number, bool, day ("yyyy-MM-dd" string), timestamp
// (ISO string in seed JSON, Firestore Timestamp in the database), string[], int[],
// enum:a|b, map:gameResult, a nested object, or [object] for an array of objects.
// A "?" marks an optional field (may be missing or null; Swift Optional).

// Top-level collections and subcollections (with the collection their parent lives in).
const TOP_LEVEL = ["users", "words", "vocabLessons", "dailyPuzzles", "exercises", "quests", "dailyPrompts", "posts", "leaderboardPeriods"];
const SUBCOLLECTIONS = { progress: "users", wordProgress: "users", dailyLog: "users", friends: "users", likes: "posts" };

const CATEGORIES = ["Connector", "Café & Dining", "Daily Verb", "Culture & Idioms"];

const GAME_RESULT = {
  status: "enum:notStarted|inProgress|completed", score: "number?", mistakes: "int?",
  solvedGroups: "int[]?", guesses: "string[]?", filledCells: "string[]?", hintsUsed: "int?",
};
const CLUE = { number: "int", row: "int", col: "int", clue: "string", answer: "string" };

const SCHEMAS = {
  users: {
    displayName: "string", username: "string", avatarInitials: "string", avatarColor: "string",
    nativeLanguage: "string", targetLanguage: "string", settings: { dailyGoalMinutes: "int" }, createdAt: "timestamp",
  },
  progress: {
    language: "string", level: "string", xp: "int", weeklyXP: "int", weekId: "string", currentStreak: "int",
    longestStreak: "int", lastActiveDate: "day", wordsLearned: "int", reviewsCorrect: "int", reviewsTotal: "int",
    displayName: "string", avatarInitials: "string",
  },
  wordProgress: {
    wordId: "string", language: "string", status: "enum:new|learning|familiar|mastered", timesSeen: "int",
    timesCorrect: "int", lastReviewed: "timestamp?", nextReview: "day",
  },
  dailyLog: {
    date: "day", language: "string", vocabCompleted: "bool", vocabScore: "number?", games: "map:gameResult",
    exercisesCompleted: "string[]", xpEarned: "int", minutesSpent: "int",
  },
  friends: { friendId: "string", status: "enum:pending|accepted", since: "timestamp" },
  words: {
    language: "string", term: "string", lemma: "string", gender: "enum?:m|f", partOfSpeech: "string",
    definitionEn: "string", category: `enum:${CATEGORIES.join("|")}`, level: "string", example: "string?",
    exampleEn: "string?", azure: { optional: true, translations: "string[]", fetchedAt: "timestamp" },
  },
  vocabLessons: {
    language: "string", date: "day", title: "string", wordCount: "int", reviewRatio: "number", newWordIds: "string[]",
  },
  dailyPuzzles: {
    language: "string", date: "day",
    connections: { groups: [{ category: "string", words: "string[]", difficulty: "int" }] },
    wordGuess: { answer: "string", length: "int", definitionEn: "string" },
    crossword: { size: "int", solution: "string[]", cluesAcross: [CLUE], cluesDown: [CLUE] },
  },
  exercises: {
    language: "string", type: "enum:fillBlank|sentenceBuilder|definitionMatch", title: "string", subtitle: "string",
    difficulty: "enum:easy|medium|hard", items: [{ prompt: "string", answer: "string", choices: "string[]?" }],
  },
  quests: {
    language: "string", lengthDays: "int",
    days: [{ day: "int", title: "string", tier: "enum:L1|L2|L3", rewardXp: "int", mascotMessage: "string" }],
  },
  dailyPrompts: { language: "string", date: "day", theme: "string", text: "string", textEn: "string?" },
  posts: {
    authorId: "string", authorName: "string", authorHandle: "string", language: "string",
    type: "enum:promptResponse|achievement", promptId: "string?", badge: "string?", text: "string",
    likesCount: "int", createdAt: "timestamp",
  },
  likes: { likedAt: "timestamp" },
  leaderboardPeriods: { label: "string", startDate: "day", endDate: "day" },
};

module.exports = { TOP_LEVEL, SUBCOLLECTIONS, CATEGORIES, GAME_RESULT, SCHEMAS };

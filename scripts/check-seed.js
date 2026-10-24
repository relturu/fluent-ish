// Validates firebase/seed/*.json before anything is uploaded.
//
// Seed format: one JSON array per collection, file name = collection name.
// Every record has an "id" (the document ID). Subcollection records also have
// a "parent" path, e.g. "users/u_sofia". seed.js strips both before writing.
//
// Checks: (1) fields and types match the Swift structs in FirestoreModels.swift,
// (2) every referenced ID exists, (3) game data follows docs/plan.md rules
// (crossword grids, Connections, scoring, XP, review intervals).
//
// Usage: node scripts/check-seed.js [--seed-dir path]

const fs = require("node:fs");
const path = require("node:path");

const argIndex = process.argv.indexOf("--seed-dir");
const SEED_DIR = argIndex > -1 ? path.resolve(process.argv[argIndex + 1]) : path.join(__dirname, "../firebase/seed");

// Top-level collections and subcollections (with the collection their parent lives in).
const TOP_LEVEL = ["users", "words", "vocabLessons", "dailyPuzzles", "exercises", "quests", "dailyPrompts", "posts", "leaderboardPeriods"];
const SUBCOLLECTIONS = { progress: "users", wordProgress: "users", dailyLog: "users", friends: "users", likes: "posts" };

const CATEGORIES = ["Connector", "Café & Dining", "Daily Verb", "Culture & Idioms"];
const LEVEL_FLOORS = [["A1", 0], ["A2", 300], ["B1", 800], ["B2", 1500], ["C1", 2500], ["C2", 4000]];
const REVIEW_DAYS = { learning: 1, familiar: 3, mastered: 7 };

// ---- Schemas: mirror the Swift structs. "?" = optional (may be missing or null). ----
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

// ---- Reporting ----
const errors = [];
let checks = 0;
function check(condition, message) {
  checks++;
  if (!condition) errors.push(message);
  return condition;
}

// ---- Helpers ----
const isDay = (v) => typeof v === "string" && /^\d{4}-\d{2}-\d{2}$/.test(v) && !isNaN(Date.parse(v + "T00:00:00Z"));
const isTimestamp = (v) => typeof v === "string" && /^\d{4}-\d{2}-\d{2}T/.test(v) && !isNaN(Date.parse(v));
const addDays = (day, n) => new Date(Date.parse(day + "T00:00:00Z") + n * 86400000).toISOString().slice(0, 10);
const normalize = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toUpperCase();
const round2 = (x) => Math.round(x * 100) / 100;
const near = (a, b) => Math.abs(a - b) <= 0.01;

function isoWeekId(day) {
  const d = new Date(Date.parse(day + "T00:00:00Z"));
  const weekday = (d.getUTCDay() + 6) % 7; // Monday = 0
  d.setUTCDate(d.getUTCDate() - weekday + 3); // Thursday of this week decides the year
  const dayOfYear = (d - Date.UTC(d.getUTCFullYear(), 0, 1)) / 86400000 + 1;
  const week = Math.ceil(dayOfYear / 7);
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, "0")}`;
}

function checkType(value, type, where) {
  if (typeof type === "object" && !Array.isArray(type)) return checkObject(value, type, where);
  if (Array.isArray(type)) {
    if (!check(Array.isArray(value), `${where}: expected an array`)) return;
    value.forEach((item, i) => checkObject(item, type[0], `${where}[${i}]`));
    return;
  }
  const optional = type.includes("?");
  const base = type.replace("?", "");
  if (value === undefined || value === null) {
    check(optional, `${where}: required field is missing`);
    return;
  }
  if (base === "string") check(typeof value === "string", `${where}: expected a string`);
  else if (base === "int") check(Number.isInteger(value), `${where}: expected an integer`);
  else if (base === "number") check(typeof value === "number", `${where}: expected a number`);
  else if (base === "bool") check(typeof value === "boolean", `${where}: expected true/false`);
  else if (base === "day") check(isDay(value), `${where}: expected a yyyy-MM-dd string, got ${JSON.stringify(value)}`);
  else if (base === "timestamp") check(isTimestamp(value), `${where}: expected an ISO timestamp, got ${JSON.stringify(value)}`);
  else if (base === "string[]") check(Array.isArray(value) && value.every((v) => typeof v === "string"), `${where}: expected an array of strings`);
  else if (base === "int[]") check(Array.isArray(value) && value.every(Number.isInteger), `${where}: expected an array of integers`);
  else if (base.startsWith("enum:")) check(base.slice(5).split("|").includes(value), `${where}: "${value}" is not one of ${base.slice(5)}`);
  else if (base === "map:gameResult") {
    if (!check(value && typeof value === "object" && !Array.isArray(value), `${where}: expected an object`)) return;
    for (const [key, result] of Object.entries(value)) {
      check(["connections", "wordGuess", "crossword"].includes(key), `${where}.${key}: unknown game`);
      checkObject(result, GAME_RESULT, `${where}.${key}`);
    }
  } else throw new Error(`Unknown schema type ${type}`);
}

function checkObject(value, schema, where) {
  if (schema.optional && (value === undefined || value === null)) return;
  if (!check(value && typeof value === "object" && !Array.isArray(value), `${where}: expected an object`)) return;
  for (const [field, type] of Object.entries(schema)) {
    if (field === "optional") continue;
    checkType(value[field], type, `${where}.${field}`);
  }
  for (const field of Object.keys(value)) {
    check(field in schema || field === "id" || field === "parent", `${where}.${field}: field is not in the Swift model (typo?)`);
  }
}

function findNestedArray(value, where) {
  if (Array.isArray(value)) {
    value.forEach((item, i) => {
      check(!Array.isArray(item), `${where}[${i}]: array inside an array (Firestore can't store this)`);
      findNestedArray(item, `${where}[${i}]`);
    });
  } else if (value && typeof value === "object") {
    for (const [k, v] of Object.entries(value)) findNestedArray(v, `${where}.${k}`);
  }
}

// ---- Load ----
const data = {};
for (const name of [...TOP_LEVEL, ...Object.keys(SUBCOLLECTIONS)]) {
  const file = path.join(SEED_DIR, `${name}.json`);
  if (!check(fs.existsSync(file), `${name}.json: file is missing`)) { data[name] = []; continue; }
  try {
    data[name] = JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (e) {
    check(false, `${name}.json: invalid JSON (${e.message})`);
    data[name] = [];
    continue;
  }
  check(Array.isArray(data[name]), `${name}.json: must be a JSON array`);
  check(data[name].length > 0, `${name}.json: needs at least one record (rubric)`);
}

const byId = (name) => new Map(data[name].map((r) => [r.id, r]));
const users = byId("users");
const words = byId("words");
const prompts = byId("dailyPrompts");
const puzzles = byId("dailyPuzzles");
const exercises = byId("exercises");
const periods = byId("leaderboardPeriods");

// ---- 1. Shape: ids, parents, schemas, no nested arrays ----
for (const [name, records] of Object.entries(data)) {
  const seen = new Set();
  for (const [i, record] of records.entries()) {
    const label = `${name}/${record.id ?? `#${i}`}`;
    if (!check(typeof record.id === "string" && record.id.length > 0, `${name}.json #${i}: missing "id"`)) continue;
    const key = `${record.parent ?? ""}/${record.id}`;
    check(!seen.has(key), `${label}: duplicate id${record.parent ? ` under ${record.parent}` : ""}`);
    seen.add(key);

    if (name in SUBCOLLECTIONS) {
      const parentCollection = SUBCOLLECTIONS[name];
      const match = typeof record.parent === "string" && record.parent.match(/^(\w+)\/([^/]+)$/);
      if (check(match && match[1] === parentCollection, `${label}: "parent" must look like "${parentCollection}/<id>"`)) {
        check(byId(parentCollection).has(match[2]), `${label}: parent ${record.parent} does not exist`);
      }
    } else {
      check(record.parent === undefined, `${label}: top-level records must not have "parent"`);
    }
    checkObject(record, SCHEMAS[name], label);
    findNestedArray(record, label);
  }
}

// ---- 2 & 3. References and game rules ----
const dateIdCollections = ["vocabLessons", "dailyPuzzles", "dailyPrompts", "dailyLog"];
for (const name of dateIdCollections) {
  for (const r of data[name]) {
    check(r.id === `${r.language}_${r.date}`, `${name}/${r.id}: id must be "{language}_{date}" = "${r.language}_${r.date}"`);
  }
}

for (const w of data.words) {
  check(/^w_[a-z0-9_]+$/.test(w.id), `words/${w.id}: id should look like w_slug`);
}

for (const lesson of data.vocabLessons) {
  for (const wordId of lesson.newWordIds ?? []) {
    const word = words.get(wordId);
    if (check(word, `vocabLessons/${lesson.id}: word ${wordId} does not exist in words`)) {
      check(word.language === lesson.language, `vocabLessons/${lesson.id}: ${wordId} is not ${lesson.language}`);
    }
  }
  check(lesson.wordCount >= (lesson.newWordIds ?? []).length, `vocabLessons/${lesson.id}: wordCount is smaller than newWordIds`);
}

function checkCrossword(cw, where) {
  const grid = cw.solution ?? [];
  const n = cw.size;
  if (!check(grid.length === n && grid.every((row) => row.length === n), `${where}: solution must be ${n} rows of ${n} characters`)) return;
  check(grid.every((row) => /^[A-ZÑ#]+$/.test(row)), `${where}: rows may only contain A-Z, Ñ and #`);
  const cell = (r, c) => (r >= 0 && r < n && c >= 0 && c < n ? grid[r][c] : "#");

  // Number every cell that starts an across or down word (2+ letters), in reading order.
  const expectedAcross = [];
  const expectedDown = [];
  let number = 0;
  for (let r = 0; r < n; r++) {
    for (let c = 0; c < n; c++) {
      if (cell(r, c) === "#") continue;
      const startsAcross = cell(r, c - 1) === "#" && cell(r, c + 1) !== "#";
      const startsDown = cell(r - 1, c) === "#" && cell(r + 1, c) !== "#";
      if (!startsAcross && !startsDown) continue;
      number++;
      if (startsAcross) {
        let answer = "";
        for (let k = c; cell(r, k) !== "#"; k++) answer += cell(r, k);
        expectedAcross.push({ number, row: r, col: c, answer });
      }
      if (startsDown) {
        let answer = "";
        for (let k = r; cell(k, c) !== "#"; k++) answer += cell(k, c);
        expectedDown.push({ number, row: r, col: c, answer });
      }
    }
  }
  const compare = (actual, expected, direction) => {
    const fmt = (x) => `${x.number}@(${x.row},${x.col}) ${x.answer}`;
    const a = (actual ?? []).map(fmt).sort().join(", ");
    const e = expected.map(fmt).sort().join(", ");
    check(a === e, `${where}: ${direction} clues don't match the grid.\n      clues: ${a}\n      grid:  ${e}`);
  };
  compare(cw.cluesAcross, expectedAcross, "across");
  compare(cw.cluesDown, expectedDown, "down");
}

for (const p of data.dailyPuzzles) {
  const where = `dailyPuzzles/${p.id}`;
  const groups = p.connections?.groups ?? [];
  check(groups.length === 4, `${where}: Connections needs exactly 4 groups`);
  check(groups.every((g) => g.words?.length === 4), `${where}: every Connections group needs exactly 4 words`);
  check([...groups.map((g) => g.difficulty)].sort().join() === "1,2,3,4", `${where}: Connections difficulties must be 1, 2, 3, 4`);
  const tiles = groups.flatMap((g) => g.words ?? []).map((w) => w.toLowerCase());
  check(new Set(tiles).size === tiles.length, `${where}: a Connections word appears twice`);

  const wg = p.wordGuess ?? {};
  check(wg.answer === wg.answer?.toUpperCase() && /^[A-ZÑ]+$/.test(wg.answer ?? ""), `${where}: Word Guess answer must be uppercase letters`);
  check(wg.length === wg.answer?.length, `${where}: wordGuess.length (${wg.length}) != answer length (${wg.answer?.length})`);
  check(data.words.some((w) => normalize(w.lemma) === wg.answer), `${where}: Word Guess answer ${wg.answer} has no matching word in words`);

  if (p.crossword) checkCrossword(p.crossword, `${where} crossword`);
}

for (const ex of data.exercises) {
  for (const [i, item] of (ex.items ?? []).entries()) {
    const where = `exercises/${ex.id} item ${i}`;
    if (!item.choices) continue;
    if (ex.type === "sentenceBuilder") {
      const pool = [...item.choices];
      const allThere = item.answer.split(" ").every((tile) => {
        const k = pool.indexOf(tile);
        if (k === -1) return false;
        pool.splice(k, 1);
        return true;
      });
      check(allThere, `${where}: answer can't be built from the tiles in choices`);
    } else {
      check(item.choices.includes(item.answer), `${where}: answer "${item.answer}" is not one of the choices`);
    }
  }
}

for (const q of data.quests) {
  const days = (q.days ?? []).map((d) => d.day).sort((a, b) => a - b);
  check(days.length === q.lengthDays && days.every((d, i) => d === i + 1), `quests/${q.id}: days must be exactly 1..${q.lengthDays}`);
}

for (const period of data.leaderboardPeriods) {
  const where = `leaderboardPeriods/${period.id}`;
  check(isoWeekId(period.startDate) === period.id, `${where}: startDate ${period.startDate} is in ${isoWeekId(period.startDate)}, not ${period.id}`);
  check(new Date(period.startDate + "T00:00:00Z").getUTCDay() === 1, `${where}: weeks start on Monday`);
  check(addDays(period.startDate, 6) === period.endDate, `${where}: endDate should be startDate + 6 days`);
}

for (const p of data.progress) {
  const where = `progress ${p.parent}/${p.id}`;
  check(p.id === p.language, `${where}: id must be the language code`);
  const user = users.get(p.parent?.split("/")[1]);
  if (user) {
    check(p.displayName === user.displayName && p.avatarInitials === user.avatarInitials, `${where}: displayName/avatarInitials must match the user (leaderboard copy)`);
  }
  const expectedLevel = LEVEL_FLOORS.filter(([, floor]) => p.xp >= floor).pop()?.[0];
  check(p.level === expectedLevel, `${where}: ${p.xp} XP is level ${expectedLevel}, not ${p.level}`);
  check(p.currentStreak <= p.longestStreak, `${where}: currentStreak is greater than longestStreak`);
  check(p.reviewsCorrect <= p.reviewsTotal, `${where}: reviewsCorrect is greater than reviewsTotal`);
  check(p.weeklyXP <= p.xp, `${where}: weeklyXP is greater than lifetime xp`);
  check(periods.has(p.weekId), `${where}: weekId ${p.weekId} has no leaderboardPeriods document`);
}

for (const wp of data.wordProgress) {
  const where = `wordProgress ${wp.parent}/${wp.id}`;
  check(wp.id === wp.wordId, `${where}: id must equal wordId`);
  check(words.has(wp.wordId), `${where}: word ${wp.wordId} does not exist`);
  check(wp.timesCorrect <= wp.timesSeen, `${where}: timesCorrect is greater than timesSeen`);
  check(!(wp.status === "mastered" && wp.timesCorrect < 6), `${where}: mastered needs 6+ correct`);
  check(!(wp.status === "familiar" && wp.timesCorrect < 3), `${where}: familiar needs 3+ correct`);
  if (wp.lastReviewed && REVIEW_DAYS[wp.status]) {
    const expected = addDays(wp.lastReviewed.slice(0, 10), REVIEW_DAYS[wp.status]);
    check(wp.nextReview === expected, `${where}: ${wp.status} reviewed ${wp.lastReviewed.slice(0, 10)} → nextReview should be ${expected}`);
  }
}

for (const log of data.dailyLog) {
  const where = `dailyLog ${log.parent}/${log.id}`;
  const games = log.games ?? {};
  let xp = log.vocabCompleted ? 20 : 0;
  let hints = 0;
  for (const [game, result] of Object.entries(games)) {
    const g = `${where} ${game}`;
    hints += result.hintsUsed ?? 0;
    if (result.status !== "completed") {
      check(result.score == null, `${g}: only completed games have a score`);
      continue;
    }
    let expected;
    if (game === "connections") expected = Math.max(0, 1 - (result.mistakes ?? 0) / 4);
    if (game === "wordGuess") expected = (7 - (result.guesses ?? []).length) / 6;
    if (game === "crossword") expected = Math.max(0, 1 - 0.1 * (result.hintsUsed ?? 0));
    check(typeof result.score === "number" && near(result.score, expected), `${g}: score should be ${round2(expected)}, got ${result.score}`);
    xp += Math.round(30 * (result.score ?? 0));
  }
  xp += 10 * (log.exercisesCompleted ?? []).length - 5 * hints;
  check(log.xpEarned === xp, `${where}: xpEarned should be ${xp} (vocab 20 + 30×score per game + 10 per exercise − 5 per hint), got ${log.xpEarned}`);
  for (const exId of log.exercisesCompleted ?? []) check(exercises.has(exId), `${where}: exercise ${exId} does not exist`);

  const wg = games.wordGuess;
  if (wg?.guesses) check(wg.guesses.length <= 6, `${where}: Word Guess allows at most 6 guesses`);
  const puzzle = puzzles.get(log.id);
  if (puzzle) {
    if (wg?.guesses) {
      check(wg.guesses.every((guess) => guess.length === puzzle.wordGuess.answer.length), `${where}: every guess must be ${puzzle.wordGuess.answer.length} letters`);
      if (wg.status === "completed") check(wg.guesses.at(-1) === puzzle.wordGuess.answer, `${where}: completed Word Guess must end with the answer ${puzzle.wordGuess.answer}`);
    }
    const cells = games.crossword?.filledCells ?? [];
    if (cells.length) {
      const solution = puzzle.crossword.solution;
      const fits = cells.length === solution.length && cells.every((row, r) =>
        row.length === solution[r].length && [...row].every((ch, c) => (ch === "#") === (solution[r][c] === "#")));
      check(fits, `${where}: filledCells must match the crossword shape ("." = empty, "#" = black)`);
    }
    check((games.connections?.solvedGroups ?? []).every((g) => g >= 0 && g < 4), `${where}: solvedGroups must be 0-3`);
  }
}

for (const f of data.friends) {
  const where = `friends ${f.parent}/${f.id}`;
  const owner = f.parent?.split("/")[1];
  check(f.id === f.friendId, `${where}: id must equal friendId`);
  check(users.has(f.friendId), `${where}: user ${f.friendId} does not exist`);
  check(f.friendId !== owner, `${where}: can't be friends with yourself`);
  if (f.status === "accepted") {
    const mutual = data.friends.some((o) => o.parent === `users/${f.friendId}` && o.friendId === owner && o.status === "accepted");
    check(mutual, `${where}: accepted friendship must exist on both sides`);
  }
}

for (const post of data.posts) {
  const where = `posts/${post.id}`;
  const author = users.get(post.authorId);
  if (check(author, `${where}: author ${post.authorId} does not exist`)) {
    check(post.authorName === author.displayName && post.authorHandle === author.username, `${where}: authorName/authorHandle must match the user`);
  }
  if (post.promptId != null) check(prompts.has(post.promptId), `${where}: promptId ${post.promptId} does not exist`);
  if (post.type === "promptResponse") check(post.promptId != null, `${where}: promptResponse posts need a promptId`);
  const likes = data.likes.filter((l) => l.parent === `posts/${post.id}`);
  check(post.likesCount === likes.length, `${where}: likesCount is ${post.likesCount} but there are ${likes.length} likes`);
}

for (const like of data.likes) {
  check(users.has(like.id), `likes ${like.parent}/${like.id}: user ${like.id} does not exist`);
}

// ---- Report ----
const counts = Object.entries(data).map(([name, records]) => `${name} ${records.length}`).join(" · ");
console.log(`Seed dir: ${SEED_DIR}`);
console.log(`Records: ${counts}\n`);
if (errors.length === 0) {
  console.log(`✅ All ${checks} checks passed.`);
} else {
  for (const e of errors) console.log(`❌ ${e}`);
  console.log(`\n${errors.length} of ${checks} checks failed.`);
  process.exit(1);
}

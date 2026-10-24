// Generates docs/sample-data.json, the rubric deliverable: one clean, valid
// JSON record per collection (no comments), keyed by its Firestore document path.
// Built from firebase/seed so it always matches what seed.js uploads.
// Timestamps appear as ISO strings (JSON has no timestamp type); in Firestore
// they are Timestamp values.
//
// Usage: node scripts/export-sample.js

const fs = require("node:fs");
const path = require("node:path");
const { TOP_LEVEL, SUBCOLLECTIONS } = require("./schemas");

const SEED_DIR = path.join(__dirname, "../firebase/seed");
const OUT = path.join(__dirname, "../docs/sample-data.json");

// The representative record for each collection (the same examples as docs/plan.md).
const PICKS = [
  ["users", "u_sofia"],
  ["progress", "es", "users/u_sofia"],
  ["wordProgress", "w_sobremesa", "users/u_sofia"],
  ["dailyLog", "es_2026-10-24", "users/u_sofia"],
  ["friends", "u_maya", "users/u_sofia"],
  ["words", "w_sobremesa"],
  ["vocabLessons", "es_2026-10-24"],
  ["dailyPuzzles", "es_2026-10-24"],
  ["exercises", "ex_fill_001"],
  ["quests", "es_28day"],
  ["dailyPrompts", "es_2026-10-24"],
  ["posts", "p_001"],
  ["likes", "u_sofia", "posts/p_001"],
  ["leaderboardPeriods", "2026-W43"],
];

const sample = {};
for (const [collection, id, parent] of PICKS) {
  const records = JSON.parse(fs.readFileSync(path.join(SEED_DIR, `${collection}.json`), "utf8"));
  const record = records.find((r) => r.id === id && r.parent === parent);
  if (!record) throw new Error(`${collection}/${id} not found in seed`);
  const { id: _id, parent: _parent, ...fields } = record;
  sample[parent ? `${parent}/${collection}/${id}` : `${collection}/${id}`] = fields;
}

const covered = new Set(PICKS.map(([c]) => c));
const missing = [...TOP_LEVEL, ...Object.keys(SUBCOLLECTIONS)].filter((c) => !covered.has(c));
if (missing.length) throw new Error(`No sample for: ${missing.join(", ")}`);

fs.writeFileSync(OUT, JSON.stringify(sample, null, 2) + "\n");
JSON.parse(fs.readFileSync(OUT, "utf8")); // round-trip: the file must be valid JSON
console.log(`✅ Wrote ${path.relative(process.cwd(), OUT)}: ${Object.keys(sample).length} records, valid JSON`);
Object.keys(sample).forEach((p) => console.log(`   ${p}`));

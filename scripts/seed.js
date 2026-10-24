// Uploads firebase/seed/*.json to Firestore with the Admin SDK.
//
// - Runs check-seed.js first and refuses to upload invalid data.
// - Uses each record's "id" as the document ID (and "parent" for subcollections),
//   so re-running never creates duplicates.
// - Converts ISO strings in timestamp fields to Firestore Timestamps so Swift
//   can decode them as Date.
// - Compares with what's already in Firestore and only writes changed docs.
// - Never deletes anything; docs that aren't in the seed are reported and left alone.
//
// Usage: node scripts/seed.js [--dry-run]
// Needs firebase/serviceAccount.json (gitignored) and `npm install` in scripts/.

const fs = require("node:fs");
const path = require("node:path");
const { execFileSync } = require("node:child_process");
const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");

const SEED_DIR = path.join(__dirname, "../firebase/seed");
const SERVICE_ACCOUNT = path.join(__dirname, "../firebase/serviceAccount.json");
const TIMESTAMP_FIELDS = new Set(["createdAt", "since", "lastReviewed", "likedAt", "fetchedAt"]);
// Parents must exist before their subcollections, so top-level collections go first.
const ORDER = [
  "users", "words", "vocabLessons", "dailyPuzzles", "exercises", "quests", "dailyPrompts", "posts", "leaderboardPeriods",
  "progress", "wordProgress", "dailyLog", "friends", "likes",
];
const DRY_RUN = process.argv.includes("--dry-run");

// Turns ISO strings in timestamp fields into Firestore Timestamps, recursively.
function toFirestore(value, key) {
  if (Array.isArray(value)) return value.map((v) => toFirestore(v));
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, toFirestore(v, k)]));
  }
  if (TIMESTAMP_FIELDS.has(key) && typeof value === "string") return Timestamp.fromDate(new Date(value));
  return value;
}

function sameValue(a, b) {
  if (a instanceof Timestamp || b instanceof Timestamp) {
    return a instanceof Timestamp && b instanceof Timestamp && a.isEqual(b);
  }
  if (Array.isArray(a) || Array.isArray(b)) {
    return Array.isArray(a) && Array.isArray(b) && a.length === b.length && a.every((x, i) => sameValue(x, b[i]));
  }
  if (a && b && typeof a === "object" && typeof b === "object") {
    const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
    return [...keys].every((k) => sameValue(a[k], b[k]));
  }
  return a === b;
}

async function main() {
  // 1. Validate first.
  try {
    execFileSync(process.execPath, [path.join(__dirname, "check-seed.js")], { stdio: "pipe" });
  } catch (error) {
    console.error(error.stdout?.toString() || error.message);
    console.error("Seed data is invalid. Fix the errors above before uploading.");
    process.exit(1);
  }

  if (!fs.existsSync(SERVICE_ACCOUNT)) {
    console.error(`Missing ${SERVICE_ACCOUNT}. Download it from Firebase console → Project settings → Service accounts.`);
    process.exit(1);
  }
  const serviceAccount = require(SERVICE_ACCOUNT);
  initializeApp({ credential: cert(serviceAccount) });
  const db = getFirestore();
  console.log(`Project: ${serviceAccount.project_id}${DRY_RUN ? "  (dry run, nothing will be written)" : ""}\n`);

  // 2. Build every document we want to exist.
  const docs = [];
  for (const name of ORDER) {
    const records = JSON.parse(fs.readFileSync(path.join(SEED_DIR, `${name}.json`), "utf8"));
    for (const { id, parent, ...fields } of records) {
      const docPath = parent ? `${parent}/${name}/${id}` : `${name}/${id}`;
      docs.push({ collection: name, ref: db.doc(docPath), data: toFirestore(fields) });
    }
  }

  // 3. Compare with what's already there (getAll reads many docs in one request).
  const existing = await db.getAll(...docs.map((d) => d.ref));
  const summary = Object.fromEntries(ORDER.map((n) => [n, { created: 0, updated: 0, unchanged: 0 }]));
  const toWrite = [];
  docs.forEach((doc, i) => {
    const snap = existing[i];
    if (!snap.exists) summary[doc.collection].created++;
    else if (sameValue(snap.data(), doc.data)) { summary[doc.collection].unchanged++; return; }
    else summary[doc.collection].updated++;
    toWrite.push(doc);
  });

  // 4. Write in batches (Firestore allows 500 writes per batch).
  if (!DRY_RUN) {
    for (let i = 0; i < toWrite.length; i += 500) {
      const batch = db.batch();
      for (const doc of toWrite.slice(i, i + 500)) batch.set(doc.ref, doc.data); // set() = replace whole doc
      await batch.commit();
    }
  }

  // 5. Report.
  console.log("collection            created  updated  unchanged");
  for (const [name, s] of Object.entries(summary)) {
    console.log(`${name.padEnd(20)} ${String(s.created).padStart(8)} ${String(s.updated).padStart(8)} ${String(s.unchanged).padStart(10)}`);
  }
  const total = (k) => Object.values(summary).reduce((sum, s) => sum + s[k], 0);
  console.log(`${"TOTAL".padEnd(20)} ${String(total("created")).padStart(8)} ${String(total("updated")).padStart(8)} ${String(total("unchanged")).padStart(10)}`);

  // Docs in Firestore that the seed doesn't know about (left untouched).
  const seeded = new Set(docs.map((d) => d.ref.path));
  const extras = [];
  for (const name of ORDER.slice(0, 9)) {
    const snap = await db.collection(name).select().get();
    snap.docs.filter((d) => !seeded.has(d.ref.path)).forEach((d) => extras.push(d.ref.path));
  }
  if (extras.length) {
    console.log(`\nNot in seed (left alone): ${extras.join(", ")}`);
  }
  console.log(DRY_RUN ? "\nDry run: nothing was written." : `\n✅ Wrote ${toWrite.length} document(s).`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

// Verifies the live Firestore database (not the seed files) with the Admin SDK:
//   1. every collection has at least as many docs as the seed,
//   2. one doc per collection has every field the Swift struct needs, with the
//      right types (timestamps must be real Firestore Timestamps),
//   3. the three queries that need composite indexes run (i.e. indexes are built).
//
// Usage: node scripts/verify.js

const fs = require("node:fs");
const path = require("node:path");
const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { TOP_LEVEL, SUBCOLLECTIONS, GAME_RESULT, SCHEMAS } = require("./schemas");

const SEED_DIR = path.join(__dirname, "../firebase/seed");
initializeApp({ credential: cert(require("../firebase/serviceAccount.json")) });
const db = getFirestore();

// Returns a list of problems with `value` against a schema type.
function problems(value, type, where) {
  if (Array.isArray(type)) {
    if (!Array.isArray(value)) return [`${where}: expected an array`];
    return value.flatMap((item, i) => problems(item, type[0], `${where}[${i}]`));
  }
  if (typeof type === "object") {
    if (type.optional && value == null) return [];
    if (!value || typeof value !== "object") return [`${where}: expected an object`];
    return Object.entries(type)
      .filter(([field]) => field !== "optional")
      .flatMap(([field, t]) => problems(value[field], t, `${where}.${field}`));
  }
  const optional = type.includes("?");
  const base = type.replace("?", "");
  if (value == null) return optional ? [] : [`${where}: missing (Swift decode would fail)`];
  const ok = {
    string: () => typeof value === "string",
    int: () => Number.isInteger(value),
    number: () => typeof value === "number",
    bool: () => typeof value === "boolean",
    day: () => typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value),
    timestamp: () => value instanceof Timestamp,
    "string[]": () => Array.isArray(value) && value.every((v) => typeof v === "string"),
    "int[]": () => Array.isArray(value) && value.every(Number.isInteger),
  }[base];
  if (ok) return ok() ? [] : [`${where}: expected ${base}, got ${value?.constructor?.name ?? typeof value} ${JSON.stringify(value)}`];
  if (base.startsWith("enum:")) return base.slice(5).split("|").includes(value) ? [] : [`${where}: "${value}" not in ${base.slice(5)}`];
  if (base === "map:gameResult") {
    return Object.entries(value).flatMap(([game, result]) => problems(result, GAME_RESULT, `${where}.${game}`));
  }
  throw new Error(`Unknown type ${type}`);
}

async function main() {
  let failures = 0;
  const report = (ok, message) => {
    if (!ok) failures++;
    console.log(`${ok ? "✅" : "❌"} ${message}`);
  };

  console.log("Collections (live count ≥ seed count, sample doc matches the Swift model)\n");
  for (const name of [...TOP_LEVEL, ...Object.keys(SUBCOLLECTIONS)]) {
    const seedCount = JSON.parse(fs.readFileSync(path.join(SEED_DIR, `${name}.json`), "utf8")).length;
    // Subcollections are spread under many parents, so use a collection-group query.
    const ref = name in SUBCOLLECTIONS ? db.collectionGroup(name) : db.collection(name);
    const liveCount = (await ref.count().get()).data().count;
    const sample = (await ref.limit(1).get()).docs[0];
    const issues = sample ? problems(sample.data(), SCHEMAS[name], sample.ref.path) : ["no documents"];
    report(liveCount >= seedCount && issues.length === 0,
      `${name.padEnd(18)} ${String(liveCount).padStart(3)} docs (seed ${seedCount})  sample: ${sample?.ref.path ?? "-"}`);
    issues.forEach((issue) => console.log(`     ${issue}`));
  }

  console.log("\nIndexed queries (fail with FAILED_PRECONDITION if an index is missing or still building)\n");
  const queries = [
    ["Global leaderboard (progress, collection group)", () => db.collectionGroup("progress")
      .where("language", "==", "es").where("weekId", "==", "2026-W43").orderBy("weeklyXP", "desc"),
      (docs) => docs.map((d) => `${d.get("displayName")} ${d.get("weeklyXP")}`).join(" > ")],
    ["Due reviews (u_sofia wordProgress, nextReview ≤ 2026-10-24)", () => db.collection("users/u_sofia/wordProgress")
      .where("language", "==", "es").where("nextReview", "<=", "2026-10-24").limit(7),
      (docs) => docs.map((d) => d.id).join(", ")],
    ["Friend Highlights (posts by Sofía's friends, newest first)", () => db.collection("posts")
      .where("authorId", "in", ["u_maya", "u_lucas", "u_elena"]).orderBy("createdAt", "desc"),
      (docs) => docs.map((d) => `${d.id} (${d.get("authorHandle")})`).join(", ")],
  ];
  for (const [label, build, describe] of queries) {
    try {
      const snap = await build().get();
      report(snap.size > 0, `${label}: ${snap.size} result(s)`);
      console.log(`     ${describe(snap.docs)}`);
    } catch (error) {
      report(false, `${label}: ${error.message.split("\n")[0]}`);
    }
  }

  console.log(failures === 0 ? "\nAll verification checks passed." : `\n${failures} check(s) failed.`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((error) => { console.error(error); process.exit(1); });

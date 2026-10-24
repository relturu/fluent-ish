// Checks the deployed Firestore security rules from a client's point of view.
// Signs in anonymously (like the app does), then tries reads/writes that the
// rules should allow or deny. Cleans up the test docs it creates.
//
// Usage: node scripts/test-rules.js   (needs FIREBASE_API_KEY in scripts/.env)

const path = require("path");
try { process.loadEnvFile(path.join(__dirname, ".env")); } catch {}

const PROJECT = "fluent-ish-9d543";
const BUNDLE_ID = "edu.cmu.relturu.FluentIsh";
const API_KEY = process.env.FIREBASE_API_KEY;
const DB = `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents`;

if (!API_KEY) {
  console.error("Missing FIREBASE_API_KEY in scripts/.env (see scripts/.env.example)");
  process.exit(1);
}

async function signInAnonymously() {
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Ios-Bundle-Identifier": BUNDLE_ID },
    body: JSON.stringify({ returnSecureToken: true }),
  });
  const json = await res.json();
  if (!json.localId) throw new Error("Anonymous sign-in failed: " + JSON.stringify(json.error));
  return { uid: json.localId, token: json.idToken };
}

// Returns the HTTP status. 403 = denied by rules; 200 (or 404 for a missing doc on read) = allowed.
async function call(method, docPath, token, fields) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  const res = await fetch(`${DB}/${docPath}`, {
    method,
    headers,
    body: fields ? JSON.stringify({ fields }) : undefined,
  });
  return res.status;
}

const str = (s) => ({ stringValue: s });

async function main() {
  const me = await signInAnonymously();
  console.log(`Signed in anonymously as ${me.uid}\n`);

  const otherUid = "u_someone_else";
  const testPostId = `rules_test_${me.uid}`;

  const cases = [
    ["Signed-out read of words",            "deny",  () => call("GET",    "words/w_sobremesa", null)],
    ["Signed-in read of words",             "allow", () => call("GET",    "words/w_sobremesa", me.token)],
    ["Write my own user doc",               "allow", () => call("PATCH",  `users/${me.uid}`, me.token, { displayName: str("Rules Test") })],
    ["Write ANOTHER user's doc",            "deny",  () => call("PATCH",  `users/${otherUid}`, me.token, { displayName: str("hacked") })],
    ["Write another user's dailyLog",       "deny",  () => call("PATCH",  `users/${otherUid}/dailyLog/es_2026-10-24`, me.token, { language: str("es") })],
    ["Read another user's progress (leaderboard)", "allow", () => call("GET", `users/${otherUid}/progress/es`, me.token)],
    ["Read another user's dailyLog",        "deny",  () => call("GET",    `users/${otherUid}/dailyLog/es_2026-10-24`, me.token)],
    ["Write shared content (words)",        "deny",  () => call("PATCH",  "words/w_rules_test", me.token, { term: str("hacked") })],
    ["Create post as someone else",         "deny",  () => call("PATCH",  `posts/${testPostId}_fake`, me.token, { authorId: str(otherUid), text: str("hi") })],
    ["Create post as myself",               "allow", () => call("PATCH",  `posts/${testPostId}`, me.token, { authorId: str(me.uid), text: str("hi") })],
    ["Delete my own post",                  "allow", () => call("DELETE", `posts/${testPostId}`, me.token)],
    ["Delete my own user doc (cleanup)",    "allow", () => call("DELETE", `users/${me.uid}`, me.token)],
  ];

  let failures = 0;
  for (const [name, expected, run] of cases) {
    const status = await run();
    const actual = status === 403 || status === 401 ? "deny" : (status === 200 || status === 404 ? "allow" : `HTTP ${status}`);
    const ok = actual === expected;
    if (!ok) failures++;
    console.log(`${ok ? "✅" : "❌"} ${name.padEnd(46)} expected ${expected.padEnd(5)} got ${actual}`);
  }

  console.log(failures === 0 ? "\nAll rules checks passed." : `\n${failures} check(s) failed.`);
  process.exit(failures === 0 ? 0 : 1);
}

main().catch((err) => { console.error(err); process.exit(1); });

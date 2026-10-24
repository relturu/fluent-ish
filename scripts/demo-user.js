// Gives a real signed-in app user (e.g. your simulator's anonymous uid) a copy of
// Sofía's demo data, so screens and the DEBUG smoke test have something to read.
// Security rules only let a user read their OWN dailyLog/wordProgress/friends,
// so the app can't test those against u_sofia.
//
// Copies users/u_sofia and its progress, wordProgress, dailyLog and friends
// subcollections to users/<uid>, renamed "Demo User" so the leaderboard doesn't
// show two Sofías. Safe to re-run. Not part of the seed: seed.js lists it under
// "Not in seed" and leaves it alone.
//
// Usage: node scripts/demo-user.js <uid>     (the uid the app prints at launch)

const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");

const SOURCE = "u_sofia";
const SUBCOLLECTIONS = ["progress", "wordProgress", "dailyLog", "friends"];
const DEMO_NAME = { displayName: "Demo User", username: "demo", avatarInitials: "DU" };

async function main() {
  const uid = process.argv[2];
  if (!uid) {
    console.error("Usage: node scripts/demo-user.js <uid>   (copy the uid the app prints after 🔥)");
    process.exit(1);
  }
  initializeApp({ credential: cert(require("../firebase/serviceAccount.json")) });
  const db = getFirestore();

  // Catch typos: the uid must belong to a real Firebase Auth user.
  try {
    await getAuth().getUser(uid);
  } catch {
    console.error(`No Firebase Auth user with uid "${uid}". Check for typos (0 vs O, l vs I).`);
    process.exit(1);
  }

  const batch = db.batch();
  const user = (await db.doc(`users/${SOURCE}`).get()).data();
  batch.set(db.doc(`users/${uid}`), { ...user, ...DEMO_NAME });
  let count = 1;

  for (const sub of SUBCOLLECTIONS) {
    const snap = await db.collection(`users/${SOURCE}/${sub}`).get();
    for (const doc of snap.docs) {
      const data = sub === "progress"
        ? { ...doc.data(), displayName: DEMO_NAME.displayName, avatarInitials: DEMO_NAME.avatarInitials }
        : doc.data();
      batch.set(db.doc(`users/${uid}/${sub}/${doc.id}`), data);
      count++;
    }
  }
  await batch.commit();
  console.log(`✅ Copied ${count} docs from users/${SOURCE} to users/${uid} (as "${DEMO_NAME.displayName}").`);
}

main().catch((error) => { console.error(error); process.exit(1); });

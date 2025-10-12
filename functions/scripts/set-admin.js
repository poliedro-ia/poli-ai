const admin = require("firebase-admin");
const sa = require("../serviceAccount.json");

admin.initializeApp({
    credential: admin.credential.cert(sa),
});

async function main() {
    const uid = process.argv[2];
    if (!uid) {
        console.error("usage: node scripts/set-admin.js <UID>");
        process.exit(1);
    }
    const user = await admin.auth().getUser(uid);
    const current = user.customClaims || {};
    const next = { ...current, admin: true };
    await admin.auth().setCustomUserClaims(uid, next);
    await admin.auth().revokeRefreshTokens(uid);
    console.log(JSON.stringify({ ok: true, uid, admin: true }));
}

main().catch((e) => {
    console.error(e);
    process.exit(1);
});

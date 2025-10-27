import { onCall, CallableRequest, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../config/firebase";
import "../config/options";
import { requireAdmin } from "../http/guards";

function uidFrom(req: CallableRequest) {
    const v = String(req.data?.uid || "");
    if (!v) throw new HttpsError("invalid-argument", "uid required");
    return v;
}

export const adminSetRole = onCall({ enforceAppCheck: false }, async (req) => {
    requireAdmin(req);
    const uid = uidFrom(req);
    const makeAdmin = Boolean(req.data?.admin === true);
    const user = await admin.auth().getUser(uid);
    const current = user.customClaims || {};
    const next: Record<string, unknown> = { ...current };
    if (makeAdmin) next.admin = true; else delete next.admin;
    await admin.auth().setCustomUserClaims(uid, next);
    await admin.auth().revokeRefreshTokens(uid);
    return { ok: true, uid, admin: makeAdmin };
});

export const adminSetDisabled = onCall({ enforceAppCheck: false }, async (req) => {
    requireAdmin(req);
    const uid = uidFrom(req);
    const disabled = Boolean(req.data?.disabled === true);
    await admin.auth().updateUser(uid, { disabled });
    return { ok: true, uid, disabled };
});

export const adminListUsers = onCall({ enforceAppCheck: false }, async (req) => {
    requireAdmin(req);
    const pageToken = req.data?.pageToken ? String(req.data.pageToken) : undefined;
    const pageSizeRaw = Number(req.data?.pageSize || 20);
    const pageSize = Math.min(Math.max(pageSizeRaw, 1), 100);
    const res = await admin.auth().listUsers(pageSize, pageToken);
    const users = res.users.map((u) => ({
        uid: u.uid,
        email: u.email || null,
        displayName: u.displayName || null,
        disabled: u.disabled === true,
        emailVerified: u.emailVerified === true,
        admin: Boolean(u.customClaims && (u.customClaims as any).admin),
        createdAt: u.metadata.creationTime || null,
        lastSignInAt: u.metadata.lastSignInTime || null,
    }));
    return { users, nextPageToken: res.pageToken || null };
});

export const adminSelfPromote = onCall({ enforceAppCheck: false }, async (req) => {
    if (!req.auth) {
        throw new HttpsError("unauthenticated", "auth required");
    }
    const uid = req.auth.uid;
    const user = await admin.auth().getUser(uid);
    const current = user.customClaims || {};
    const next: Record<string, unknown> = { ...current, admin: true };
    await admin.auth().setCustomUserClaims(uid, next);
    await admin.auth().revokeRefreshTokens(uid);
    return { ok: true, uid, admin: true };
});

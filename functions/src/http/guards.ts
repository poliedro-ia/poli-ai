import { CallableRequest, HttpsError } from "firebase-functions/v2/https";

export function requireAuth(req: CallableRequest) {
    if (!req.auth) {
        throw new HttpsError("unauthenticated", "auth required");
    }
}

export function requireAdmin(req: CallableRequest) {
    requireAuth(req);
    const token = req.auth!.token as Record<string, unknown>;
    if (!token.admin) {
        throw new HttpsError("permission-denied", "admin only");
    }
}

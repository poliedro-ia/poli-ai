import { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";

export function assertAuth(req: CallableRequest) {
    if (!req.auth) {
        throw new HttpsError("unauthenticated", "Login necessário");
    }
}

export function assertAdmin(req: CallableRequest) {
    assertAuth(req);
    const role = (req.auth!.token as any).role;
    if (role !== "admin") {
        throw new HttpsError("permission-denied", "Acesso restrito ao admin");
    }
}

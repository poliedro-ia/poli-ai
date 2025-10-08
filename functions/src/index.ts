const functions = require("firebase-functions"); // v1
const admin = require("firebase-admin");         // v1

import { GenerateSchema, EditSchema, Allowed } from "./schema";

admin.initializeApp();
const db = admin.firestore();
const bucket = admin.storage().bucket();

/** ===== CONFIG LOCAIS ===== */
const ALLOWED_DOMAINS: string[] = ["sistemapoliedro.com.br", "p4ed.com"];
const SUPERADMIN_EMAIL: string = ""; // deixe vazio se não for usar bootstrap por email

/** ===== HELPERS ===== */
function lower(x: any): string {
    return typeof x === "string" ? x.toLowerCase() : "";
}
function isString(x: any): x is string {
    return typeof x === "string";
}
function assertAuth(context: any) {
    if (!context || !context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Login necessário");
    }
}
function assertAdmin(context: any) {
    assertAuth(context);
    const role = (context.auth.token as any)?.role;
    if (role !== "admin") {
        throw new functions.https.HttpsError("permission-denied", "Acesso restrito ao admin");
    }
}
function normalizePrompt(subject: string, subarea: string, style: string, details: string) {
    return [
        `[EDU] Área: ${subject.toUpperCase()} • Subárea: ${subarea} • Estilo: ${style}`,
        `Diretrizes: ilustração clara, didática, sem marcas d'água, adequada ao ensino médio.`,
        `Instruções: ${details}`,
    ].join("\n");
}
function getOpenRouterKey(): string {
    const key = process.env.OPENROUTER_API_KEY;
    if (!isString(key) || key.length === 0) {
        throw new Error("OPENROUTER_API_KEY ausente (defina via 'firebase functions:secrets:set OPENROUTER_API_KEY')");
    }
    return key;
}
async function callOpenRouter(body: Record<string, any>): Promise<any> {
    const apiKey = getOpenRouterKey();
    const resp: any = await (globalThis as any).fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
        body: JSON.stringify(body),
    } as any);
    if (!resp.ok) {
        const t = await resp.text();
        throw new Error(`OpenRouter: ${t}`);
    }
    return (await resp.json()) as any;
}

/** ===== 1) Trigger: criar perfil + claims e bloquear domínios não permitidos ===== */
exports.onAuthCreate = functions.auth.user().onCreate(async (user: any) => {
    const uid: string = user?.uid ?? "";
    const email: string = isString(user?.email) ? user.email : "";
    const displayName: string = isString(user?.displayName) ? user.displayName : "";

    const domain = lower(email.split("@")[1] || "");
    const allowed = ALLOWED_DOMAINS.map((d) => lower(d)).includes(domain);

    await db.collection("users").doc(uid).set(
        {
            uid,
            email,
            displayName,
            role: "user",
            disabled: !allowed,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
    );

    await admin.auth().setCustomUserClaims(uid, { role: "user" });

    if (!allowed) {
        await admin.auth().updateUser(uid, { disabled: true });
    }
});

/** ===== 2) Bootstrap do primeiro admin (opcional) ===== */
exports.bootstrapAdmin = functions.https.onCall(async (_data: any, context: any) => {
    assertAuth(context);
    if (!isString(SUPERADMIN_EMAIL) || SUPERADMIN_EMAIL.trim() === "") {
        throw new functions.https.HttpsError("failed-precondition", "SUPERADMIN_EMAIL não configurado no código");
    }
    const currentEmail = lower((context.auth?.token?.email as any) || "");
    if (currentEmail !== lower(SUPERADMIN_EMAIL)) {
        throw new functions.https.HttpsError("permission-denied", "Apenas o SUPERADMIN pode executar");
    }
    await admin.auth().setCustomUserClaims(context.auth.uid, { role: "admin" });
    await db.collection("users").doc(context.auth.uid).set({ role: "admin" }, { merge: true });
    return { ok: true };
});

/** ===== 3) Admin: trocar papel e bloquear/desbloquear ===== */
exports.setUserRole = functions.https.onCall(async (data: any, context: any) => {
    assertAdmin(context);
    const uid: string = isString(data?.uid) ? data.uid : "";
    const role: string = isString(data?.role) ? data.role : "";
    if (!uid || (role !== "admin" && role !== "user")) {
        throw new functions.https.HttpsError("invalid-argument", "Parâmetros inválidos");
    }
    await admin.auth().setCustomUserClaims(uid, { role });
    await db.collection("users").doc(uid).set({ role }, { merge: true });
    return { ok: true };
});

exports.setUserDisabled = functions.https.onCall(async (data: any, context: any) => {
    assertAdmin(context);
    const uid: string = isString(data?.uid) ? data.uid : "";
    const disabled: boolean = typeof data?.disabled === "boolean" ? data.disabled : false;
    if (!uid || typeof disabled !== "boolean") {
        throw new functions.https.HttpsError("invalid-argument", "Parâmetros inválidos");
    }
    await admin.auth().updateUser(uid, { disabled });
    await db.collection("users").doc(uid).set({ disabled }, { merge: true });
    return { ok: true };
});

/** ===== 4) Geração de imagem ===== */
exports.generateImageOpenRouter = functions
    .runWith({ secrets: ["OPENROUTER_API_KEY"] })
    .https.onCall(async (data: any, context: any) => {
        assertAuth(context);
        const parsed = GenerateSchema.safeParse(data);
        if (!parsed.success) {
            throw new functions.https.HttpsError("invalid-argument", "Payload inválido");
        }

        const { subject, subarea, style, details, aspectRatio, model } = parsed.data;
        if (!Allowed[subject as "fisica" | "quimica"].includes(subarea)) {
            throw new functions.https.HttpsError("invalid-argument", "Subárea não permitida");
        }

        const ownerUid: string = context.auth.uid;
        const docRef = await db.collection("images").add({
            ownerUid,
            subject,
            subarea,
            style,
            prompt: details,
            provider: "openrouter",
            status: "queued",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        try {
            await docRef.update({ status: "running" });
            const prompt = normalizePrompt(subject, subarea, style, details);

            const json: any = await callOpenRouter({
                model,
                modalities: ["image", "text"],
                messages: [{ role: "user", content: prompt }],
                image_config: { aspect_ratio: aspectRatio },
            });

            const images = json?.choices?.[0]?.message?.images;
            const dataUrl: string | undefined = images?.[0]?.image_url?.url;
            if (!isString(dataUrl) || !dataUrl.startsWith("data:image")) {
                throw new Error("Resposta sem imagem");
            }

            const base64 = dataUrl.split(",")[1];
            const buffer = Buffer.from(base64, "base64");
            const path = `images/${ownerUid}/${docRef.id}.png`;
            const file = bucket.file(path);
            await file.save(buffer, { contentType: "image/png", resumable: false, public: false });

            const [signedUrl] = await file.getSignedUrl({
                action: "read",
                expires: Date.now() + 1000 * 60 * 60 * 24 * 7,
            });

            await docRef.update({
                imageUrl: signedUrl,
                storagePath: path,
                status: "done",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return { imageId: docRef.id, imageUrl: signedUrl, status: "done" };
        } catch (err: any) {
            await docRef.update({
                status: "error",
                errorMessage: err?.message ?? "erro",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            throw new functions.https.HttpsError("internal", err?.message ?? "Falha ao gerar imagem");
        }
    });

/** ===== 5) Edição de imagem ===== */
exports.editImageOpenRouter = functions
    .runWith({ secrets: ["OPENROUTER_API_KEY"] })
    .https.onCall(async (data: any, context: any) => {
        assertAuth(context);
        const parsed = EditSchema.safeParse(data);
        if (!parsed.success) {
            throw new functions.https.HttpsError("invalid-argument", "Payload inválido");
        }

        const { imageUrl, instruction, subject, subarea, style, aspectRatio, model } = parsed.data;
        if (!Allowed[subject as "fisica" | "quimica"].includes(subarea)) {
            throw new functions.https.HttpsError("invalid-argument", "Subárea não permitida");
        }

        const ownerUid: string = context.auth.uid;
        const docRef = await db.collection("images").add({
            ownerUid,
            subject,
            subarea,
            style,
            prompt: instruction,
            baseImageUrl: imageUrl,
            provider: "openrouter",
            status: "queued",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        try {
            await docRef.update({ status: "running" });

            const prompt = normalizePrompt(
                subject,
                subarea,
                style,
                `Edite a imagem fornecida conforme: ${instruction}`
            );

            const json: any = await callOpenRouter({
                model,
                modalities: ["image", "text"],
                messages: [
                    {
                        role: "user",
                        content: [
                            { type: "text", text: prompt },
                            { type: "image_url", image_url: { url: imageUrl } },
                        ],
                    },
                ],
                image_config: { aspect_ratio: aspectRatio },
            });

            const images = json?.choices?.[0]?.message?.images;
            const dataUrl: string | undefined = images?.[0]?.image_url?.url;
            if (!isString(dataUrl) || !dataUrl.startsWith("data:image")) {
                throw new Error("Resposta sem imagem");
            }

            const base64 = dataUrl.split(",")[1];
            const buffer = Buffer.from(base64, "base64");
            const path = `images/${ownerUid}/${docRef.id}.png`;
            const file = bucket.file(path);
            await file.save(buffer, { contentType: "image/png", resumable: false, public: false });

            const [signedUrl] = await file.getSignedUrl({
                action: "read",
                expires: Date.now() + 1000 * 60 * 60 * 24 * 7,
            });

            await docRef.update({
                imageUrl: signedUrl,
                storagePath: path,
                status: "done",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            return { imageId: docRef.id, imageUrl: signedUrl, status: "done" };
        } catch (err: any) {
            await docRef.update({
                status: "error",
                errorMessage: err?.message ?? "erro",
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            throw new functions.https.HttpsError("internal", err?.message ?? "Falha ao editar imagem");
        }
    });

import { admin } from "../config/firebase";

export async function salvarBuffer(uid: string, buf: Buffer) {
    const ts = Date.now();
    const refPath = `users/${uid}/images/${ts}.png`;
    const bucket = admin.storage().bucket();
    const file = bucket.file(refPath);
    await file.save(buf, { contentType: "image/png", resumable: false, metadata: { cacheControl: "public,max-age=31536000" } });
    const [downloadUrl] = await file.getSignedUrl({ action: "read", expires: Date.now() + 1000 * 60 * 60 * 24 * 7 });
    return { storagePath: refPath, downloadUrl };
}

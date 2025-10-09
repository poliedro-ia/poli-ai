import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { z } from "zod";

const OPENROUTER_API_KEY = defineSecret("OPENROUTER_API_KEY");

const InputSchema = z.object({
    tema: z.enum(["fisica", "quimica"]),
    subarea: z.string().min(2).max(40),
    estilo: z.enum(["vetor", "realista", "desenho animado"]),
    detalhes: z.string().min(5).max(800),
    aspectRatio: z.enum([
        "1:1",
        "2:3",
        "3:2",
        "3:4",
        "4:3",
        "4:5",
        "5:4",
        "9:16",
        "16:9",
        "21:9"
    ]).default("1:1"),
    model: z.string().default("google/gemini-2.5-flash-image-preview")
});

function cap(s: string) {
    return s.charAt(0).toUpperCase() + s.slice(1);
}

export const generateImage = onCall(
    {
        region: "southamerica-east1",
        secrets: [OPENROUTER_API_KEY],
        cors: true,
        timeoutSeconds: 120,
        memory: "512MiB"
    },
    async (req) => {
        if (!req.auth) {
            throw new HttpsError("unauthenticated", "Auth requerida.");
        }
        const parsed = InputSchema.safeParse(req.data);
        if (!parsed.success) {
            throw new HttpsError("invalid-argument", "Payload inválido.");
        }
        const { tema, subarea, estilo, detalhes, aspectRatio, model } = parsed.data;
        const estiloTxt = estilo === "vetor" ? "flat vector, diagrammatic" : estilo === "realista" ? "realistic, photorealistic lighting" : "clean cartoon, didactic line art";
        const areaTxt = tema === "fisica" ? `Physics - ${cap(subarea)}` : `Chemistry - ${cap(subarea)}`;
        const prompt = `${areaTxt}. Style: ${estiloTxt}. Didactic high-contrast educational illustration for Brazilian high-school. Include clear labels when helpful. No logos. Details: ${detalhes}`;
        const body = {
            model,
            messages: [{ role: "user", content: prompt }],
            modalities: ["image", "text"],
            image_config: { aspect_ratio: aspectRatio }
        };
        const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
            method: "POST",
            headers: {
                Authorization: `Bearer ${OPENROUTER_API_KEY.value()}`,
                "Content-Type": "application/json",
                "HTTP-Referer": "https://seu-dominio-ou-app",
                "X-Title": "EduImage"
            },
            body: JSON.stringify(body)
        });
        if (!res.ok) {
            const txt = await res.text();
            logger.error("OpenRouter error", { status: res.status, txt });
            throw new HttpsError("internal", "Falha ao gerar a imagem.");
        }
        const json: any = await res.json();
        const choice = json?.choices?.[0]?.message;
        const img = choice?.images?.[0]?.image_url?.url;
        if (!img || typeof img !== "string") {
            logger.error("Resposta sem imagem válida", json);
            throw new HttpsError("internal", "Resposta inválida do provedor.");
        }
        return {
            imageDataUrl: img,
            provider: "openrouter",
            model,
            aspectRatio,
            promptUsado: prompt
        };
    }
);

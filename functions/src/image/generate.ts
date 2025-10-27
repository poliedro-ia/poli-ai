import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import "../config/options";
import { InputSchema } from "./schema";
import { montarPrompts, modelosPadrao, inferTemaSubarea } from "./prompt";
import { chamarOpenRouter, baixarComoBuffer } from "./openrouter";
import { salvarBuffer } from "./storage";

const OPENROUTER_API_KEY = defineSecret("OPENROUTER_API_KEY");

export const generateImage = onCall(
    { region: "southamerica-east1", secrets: [OPENROUTER_API_KEY], cors: true, timeoutSeconds: 180, memory: "1GiB" },
    async (req) => {
        if (!req.auth) throw new HttpsError("unauthenticated", "Auth requerida.");
        const parsed = InputSchema.safeParse(req.data);
        if (!parsed.success) throw new HttpsError("invalid-argument", "Payload inválido.");
        const { tema, subarea, estilo, detalhes, aspectRatio } = parsed.data;

        const apiKey = OPENROUTER_API_KEY.value();
        if (!apiKey) throw new HttpsError("failed-precondition", "Chave do OpenRouter ausente.");

        const inf = inferTemaSubarea(detalhes, tema, subarea);
        const temaR = inf.tema;
        const subR = inf.subarea;

        const modelos = modelosPadrao();
        const prompts = montarPrompts(temaR, subR, estilo, detalhes);

        for (const p of prompts) {
            for (const mdl of modelos) {
                try {
                    const src = await chamarOpenRouter(mdl, p, aspectRatio, apiKey);
                    const buf = await baixarComoBuffer(src);
                    const saved = await salvarBuffer(req.auth.uid, buf);
                    return {
                        storagePath: saved.storagePath,
                        downloadUrl: saved.downloadUrl,
                        provider: "openrouter",
                        model: mdl,
                        aspectRatio,
                        promptUsado: p,
                        temaSelecionado: tema,
                        subareaSelecionada: subarea,
                        temaResolvido: temaR,
                        subareaResolvida: subR,
                        inferenciaAplicada: inf.resolved,
                    };
                } catch (err: any) {
                    logger.warn("Tentativa falhou", { model: mdl, message: err?.message ?? String(err) });
                    continue;
                }
            }
        }
        throw new HttpsError("internal", "Nenhum modelo conseguiu gerar a imagem para este pedido.");
    }
);

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import fetch from "node-fetch";
import { z } from "zod";

export { adminSetRole, adminSetDisabled, adminListUsers, adminSelfPromote } from "./admin";

if (!admin.apps.length) admin.initializeApp();

const OPENROUTER_API_KEY = defineSecret("OPENROUTER_API_KEY");

const InputSchema = z.object({
    tema: z.enum(["fisica", "quimica"]),
    subarea: z.string().min(2).max(40),
    estilo: z.enum(["vetor", "realista", "desenho animado"]),
    detalhes: z.string().min(3).max(1000),
    aspectRatio: z.enum(["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]).default("1:1"),
});

function cap(s: string) { return s.charAt(0).toUpperCase() + s.slice(1); }
function estiloTexto(e: string) {
    if (e === "vetor") return "flat vector, schematic, diagrammatic, clean lines";
    if (e === "realista") return "realistic render, clear lighting, neutral background";
    return "clean cartoon, didactic line art, high contrast";
}
function baseInstrucao() {
    return "Educational, high-contrast, clearly labeled, safe for school, no logos, no brands, neutral background, readable text, SVG-like clarity";
}
function promptFisica(sub: string, det: string, est: string) {
    const area = `Physics - ${cap(sub)}`;
    const ref = "Focus on clear components, arrows for forces/fields/flows when relevant, SI units, simple geometry";
    return `${area}. ${baseInstrucao()}. Style: ${est}. ${ref}. Details: ${det}`;
}
function promptQuimica(sub: string, det: string, est: string) {
    const area = `Chemistry - ${cap(sub)}`;
    const ref = "Prefer ball-and-stick or Lewis structures when relevant, show bonds and lone pairs, clear atom labels, neutral colors";
    return `${area}. ${baseInstrucao()}. Style: ${est}. ${ref}. Details: ${det}`;
}
function expandirDetalhes(tema: "fisica" | "quimica", sub: string, det: string) {
    const t = det.trim();
    if (tema === "quimica") {
        if (/el[eé]tron/i.test(t) && /liga/i.test(t)) return "Covalent bonding diagram with valence electrons shown as pairs/dots, show shared electron pair between atoms, label bond type and atoms. " + t;
        if (!/l[eê]wis/i.test(t) && /liga/i.test(t)) return "Lewis structures and bonding representation, with arrows or dots for electron flow if applicable. " + t;
    }
    if (tema === "fisica") {
        if (/campo|for[çc]a|carga|el[eé]trico/i.test(t)) return "Use arrows to indicate direction and magnitude, include units and axes if applicable. " + t;
        if (/circuito|resistor|capacitor|indutor|bateria/i.test(t)) return "Schematic electrical diagram with standard symbols and labels for V, I, R, C. " + t;
        if (/plano inclinado|atrito|forc[ao] normal|decomposi[cç][aã]o de for[cç]as|vetores/i.test(t)) return "Show free-body diagram with vectors for weight, normal and friction, include angle and axes. " + t;
    }
    return t;
}
function montarPrompts(tema: "fisica" | "quimica", sub: string, est: string, det: string) {
    const e = estiloTexto(est);
    const d1 = expandirDetalhes(tema, sub, det);
    const p1 = tema === "fisica" ? promptFisica(sub, d1, e) : promptQuimica(sub, d1, e);
    const p2 = tema === "fisica" ? promptFisica(sub, `${d1}. Emphasize labels and conceptual clarity over realism.`, e)
        : promptQuimica(sub, `${d1}. Emphasize labels and conceptual clarity over realism.`, e);
    const p3 = tema === "fisica" ? promptFisica(sub, `${d1}. Show components separated and then assembled in the final view if helpful.`, e)
        : promptQuimica(sub, `${d1}. Show components separated and then assembled in the final view if helpful.`, e);
    return [p1, p2, p3];
}
function modelosPadrao() {
    return [
        "google/gemini-2.5-flash-image-preview",
        "black-forest-labs/flux-1.1-pro",
        "stabilityai/stable-image-ultra",
        "playgroundai/playground-v2.5",
    ];
}
function inferTemaSubarea(texto: string, temaSel: "fisica" | "quimica", subSel: string) {
    const t = texto.toLowerCase();
    const fisica = {
        mecanica: /(plano inclinado|atrito|peso|for[çc]a normal|for[çc]a resultante|mru|mruv|queda|torque)/i,
        optica: /(lente|espelho|refra[cç][aã]o|reflex[aã]o|foco|raios)/i,
        eletricidade: /(circuito|resistor|capacitor|indutor|bateria|corrente|tens[aã]o|campo el[ée]trico|carga)/i,
        termodinamica: /(gases|press[aã]o|temperatura|calor|entropia|ciclo|carnot|dilata[cç][aã]o)/i,
    };
    const quimica = {
        ligacoes: /(lig[aã]o|covalente|i[oô]nica|met[aá]lica|el[eé]tron|par de el[eé]trons|lewis)/i,
        atomistica: /(n[uú]cleo|pr[oó]ton|n[eê]utron|n[uú]mero at[oô]mico|orbitais)/i,
        estequiometria: /(mol|massa molar|reagente limitante|rendimento|propor[cç][aã]o)/i,
        reacoes: /(rea[cç][aã]o|equilibrar|equil[ií]brio qu[ií]mico|cin[eé]tica)/i,
    };
    const hitsF = [["mecanica", "fisica", fisica.mecanica.test(t)], ["optica", "fisica", fisica.optica.test(t)], ["eletricidade", "fisica", fisica.eletricidade.test(t)], ["termodinamica", "fisica", fisica.termodinamica.test(t)]].filter(x => x[2] as boolean);
    const hitsQ = [["ligacoes", "quimica", quimica.ligacoes.test(t)], ["atomistica", "quimica", quimica.atomistica.test(t)], ["estequiometria", "quimica", quimica.estequiometria.test(t)], ["reacoes", "quimica", quimica.reacoes.test(t)]].filter(x => x[2] as boolean);
    if (hitsF.length && !hitsQ.length) return { tema: "fisica" as const, subarea: hitsF[0][0] as string, resolved: true };
    if (hitsQ.length && !hitsF.length) return { tema: "quimica" as const, subarea: hitsQ[0][0] as string, resolved: true };
    return { tema: temaSel, subarea: subSel, resolved: false };
}
async function chamarOpenRouter(model: string, prompt: string, aspect: string, apiKey: string) {
    const body = {
        model,
        messages: [
            { role: "system", content: "You generate safe, school-appropriate, educational illustrations." },
            { role: "user", content: prompt },
        ],
        modalities: ["image", "text"],
        image_config: { aspect_ratio: aspect },
    };
    const res = await fetch("https://openrouter.ai/api/v1/chat/completions", {
        method: "POST",
        headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
            "HTTP-Referer": "https://seu-dominio-ou-app",
            "X-Title": "EduImage",
        },
        body: JSON.stringify(body),
    });
    if (!res.ok) {
        const txt = await res.text();
        throw new Error(`HTTP ${res.status} ${txt}`);
    }
    const json: any = await res.json();
    const m = json?.choices?.[0]?.message;
    const url = m?.images?.[0]?.image_url?.url as string | undefined;
    const b64 = m?.images?.[0]?.b64_json as string | undefined;
    if (url) return { kind: "url", value: url } as const;
    if (b64) return { kind: "b64", value: b64 } as const;
    throw new Error("NoImage");
}
async function baixarComoBuffer(source: { kind: "url" | "b64", value: string }) {
    if (source.kind === "b64") {
        return Buffer.from(source.value, "base64");
    }
    const r = await fetch(source.value);
    if (!r.ok) throw new Error(`DL ${r.status}`);
    return Buffer.from(await r.arrayBuffer());
}

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
        const temaR = inf.tema; const subR = inf.subarea;

        const modelos = modelosPadrao();
        const prompts = montarPrompts(temaR, subR, estilo, detalhes);

        for (const p of prompts) {
            for (const mdl of modelos) {
                try {
                    const src = await chamarOpenRouter(mdl, p, aspectRatio, apiKey);
                    const buf = await baixarComoBuffer(src);

                    const ts = Date.now();
                    const refPath = `users/${req.auth.uid}/images/${ts}.png`;
                    const bucket = admin.storage().bucket();
                    const file = bucket.file(refPath);
                    await file.save(buf, { contentType: "image/png", resumable: false, metadata: { cacheControl: "public,max-age=31536000" } });

                    const [downloadUrl] = await file.getSignedUrl({
                        action: "read",
                        expires: Date.now() + 1000 * 60 * 60 * 24 * 7,
                    });

                    return {
                        storagePath: refPath,
                        downloadUrl,
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

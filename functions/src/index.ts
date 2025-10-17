import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

export {
    adminSetRole,
    adminSetDisabled,
    adminListUsers,
    adminSelfPromote,
} from "./admin";

const OPENROUTER_API_KEY = defineSecret("OPENROUTER_API_KEY");

/** ------------------ Normalização & validação tolerante ------------------ */

type Tema = "fisica" | "quimica";
type Estilo = "vetor" | "realista" | "desenho";

const ASPECTS = new Set([
    "1:1",
    "2:3",
    "3:2",
    "3:4",
    "4:3",
    "4:5",
    "5:4",
    "9:16",
    "16:9",
    "21:9",
]);

function normText(v: unknown) {
    return (v ?? "").toString().trim();
}

function normalizeTema(v: unknown): Tema {
    const s = normText(v).toLowerCase();
    if (["fisica", "física", "physics"].includes(s)) return "fisica";
    if (["quimica", "química", "chemistry"].includes(s)) return "quimica";
    throw new HttpsError("invalid-argument", "Campo 'tema' inválido.");
}

function normalizeSubarea(v: unknown) {
    const s = normText(v);
    if (!s || s.length < 2) {
        throw new HttpsError("invalid-argument", "Campo 'subarea' inválido.");
    }
    return s.toLowerCase();
}

function normalizeEstilo(v: unknown): Estilo {
    const s = normText(v).toLowerCase();
    // Aceita aliases vindos do app
    if (["vetor", "vetorial", "vector"].includes(s)) return "vetor";
    if (["realista", "realistic", "realismo"].includes(s)) return "realista";
    if (["desenho", "desenho animado", "cartoon", "lineart"].includes(s))
        return "desenho";
    throw new HttpsError("invalid-argument", "Campo 'estilo' inválido.");
}

function normalizeAspect(v: unknown) {
    const s = normText(v) || "1:1";
    if (!ASPECTS.has(s)) {
        throw new HttpsError("invalid-argument", "Campo 'aspectRatio' inválido.");
    }
    return s;
}

function normalizeDetalhes(v: unknown) {
    const s = normText(v);
    if (!s || s.length < 3) {
        throw new HttpsError("invalid-argument", "Campo 'detalhes' inválido.");
    }
    return s;
}

/** ------------------ Prompt engineering util ------------------ */

function cap(s: string) {
    return s.charAt(0).toUpperCase() + s.slice(1);
}

function estiloTexto(e: Estilo) {
    if (e === "vetor")
        return "flat vector, schematic, diagrammatic, clean lines, svg-like clarity";
    if (e === "realista") return "realistic render, clear lighting, neutral background";
    return "clean cartoon / didactic line art, high contrast";
}

function baseInstrucao() {
    return "Educational, high-contrast, clearly labeled, safe for school, no logos, no brands, neutral background, readable text";
}

function promptFisica(sub: string, detalhes: string, estilo: Estilo) {
    const area = `Physics - ${cap(sub)}`;
    const reforco =
        "Focus on clear components; arrows for forces/fields/flows when relevant; SI units; simple geometry";
    return `${area}. ${baseInstrucao()}. Style: ${estiloTexto(estilo)}. ${reforco}. Details: ${detalhes}`;
}

function promptQuimica(sub: string, detalhes: string, estilo: Estilo) {
    const area = `Chemistry - ${cap(sub)}`;
    const reforco =
        "Prefer ball-and-stick or Lewis structures when relevant; show bonds and lone pairs; clear atom labels; neutral colors";
    return `${area}. ${baseInstrucao()}. Style: ${estiloTexto(estilo)}. ${reforco}. Details: ${detalhes}`;
}

function expandirDetalhes(tema: Tema, sub: string, detalhes: string) {
    const t = detalhes.trim();
    if (tema === "quimica") {
        if (/el[eé]tron/i.test(t) && /liga/i.test(t)) {
            return (
                "Covalent bonding diagram with valence electrons shown as pairs/dots, show shared electron pair between atoms, label bond type and atoms. " +
                t
            );
        }
        if (!/l[eê]wis/i.test(t) && /liga/i.test(t)) {
            return "Lewis structures and bonding representation, with arrows or dots for electron flow if applicable. " + t;
        }
    }
    if (tema === "fisica") {
        if (/campo|for[çc]a|carga|el[eé]trico/i.test(t)) {
            return "Use arrows to indicate direction and magnitude, include units and axes if applicable. " + t;
        }
        if (/circuito|resistor|capacitor|indutor|bateria/i.test(t)) {
            return "Schematic electrical diagram with standard symbols and labels for V, I, R, C. " + t;
        }
        if (/plano inclinado|atrito|forc[ao] normal|decomposi[cç][aã]o de for[cç]as|vetores/i.test(t)) {
            return "Show free-body diagram with vectors for weight, normal and friction, include angle and axes. " + t;
        }
    }
    return t;
}

function montarPrompts(tema: Tema, sub: string, estilo: Estilo, detalhes: string) {
    const d1 = expandirDetalhes(tema, sub, detalhes);
    const p = (d: string) =>
        tema === "fisica" ? promptFisica(sub, d, estilo) : promptQuimica(sub, d, estilo);
    return [
        p(d1),
        p(`${d1}. Emphasize labels and conceptual clarity over realism.`),
        p(`${d1}. Show components separated and then assembled in the final view if helpful.`),
    ];
}

function modelosPadrao() {
    return [
        "google/gemini-2.5-flash-image-preview",
        "black-forest-labs/flux-1.1-pro",
        "stabilityai/stable-image-ultra",
        "playgroundai/playground-v2.5",
    ];
}

function inferTemaSubarea(
    texto: string,
    temaSel: Tema,
    subSel: string
): { tema: Tema; subarea: string; resolved: boolean } {
    const t = texto.toLowerCase();
    const fisica = {
        mecanica:
            /(plano inclinado|atrito|peso|for[çc]a normal|for[çc]a resultante|mru|mruv|queda|torque|momento)/i,
        optica: /(lente|espelho|refra[cç][aã]o|reflex[aã]o|foco|raios de luz)/i,
        eletricidade:
            /(circuito|resistor|capacitor|indutor|bateria|corrente|tens[aã]o|campo el[ée]trico|carga)/i,
        termodinamica:
            /(gases|press[aã]o|temperatura|calor|entropia|ciclo|carnot|dilata[cç][aã]o)/i,
    };
    const quimica = {
        ligacoes:
            /(lig[aã]o|covalente|i[oô]nica|met[aá]lica|el[eé]tron|par de el[eé]trons|estrutura de lewis|octeto)/i,
        atomistica:
            /(n[uú]cleo|pr[oó]ton|n[eê]utron|el[eé]tron|n[uú]mero at[oô]mico|camadas|orbitais)/i,
        estequiometria: /(mol|massa molar|reagente limitante|rendimento|propor[cç][aã]o)/i,
        reacoes:
            /(rea[cç][aã]o|equilibrar|equil[ií]brio qu[ií]mico|cin[eé]tica|produtos|reagentes)/i,
    };

    const hitsF = [
        ["mecanica", fisica.mecanica.test(t)],
        ["optica", fisica.optica.test(t)],
        ["eletricidade", fisica.eletricidade.test(t)],
        ["termodinamica", fisica.termodinamica.test(t)],
    ].filter((x) => x[1]);

    const hitsQ = [
        ["ligacoes", quimica.ligacoes.test(t)],
        ["atomistica", quimica.atomistica.test(t)],
        ["estequiometria", quimica.estequiometria.test(t)],
        ["reacoes", quimica.reacoes.test(t)],
    ].filter((x) => x[1]);

    if (hitsF.length && !hitsQ.length)
        return { tema: "fisica", subarea: hitsF[0][0] as string, resolved: true };
    if (hitsQ.length && !hitsF.length)
        return { tema: "quimica", subarea: hitsQ[0][0] as string, resolved: true };
    return { tema: temaSel, subarea: subSel, resolved: false };
}

/** ------------------ OpenRouter ------------------ */

async function chamarOpenRouter(
    model: string,
    prompt: string,
    aspect: string,
    apiKey: string
) {
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

    // Tenta vários formatos possíveis de saída de imagem:
    const msg = json?.choices?.[0]?.message;
    const direct = msg?.images?.[0]?.image_url?.url;
    const b64 = msg?.images?.[0]?.b64_json
        ? `data:image/png;base64,${msg.images[0].b64_json}`
        : undefined;

    // Alguns modelos retornam em message.content (array):
    let fromContent: string | undefined;
    const content = msg?.content;
    if (Array.isArray(content)) {
        const imgPart = content.find(
            (c: any) =>
                (c?.type === "output_image" && c?.image_url?.url) ||
                (c?.type === "image_url" && c?.image_url?.url) ||
                c?.b64_json
        );
        if (imgPart?.image_url?.url) fromContent = imgPart.image_url.url;
        if (!fromContent && imgPart?.b64_json)
            fromContent = `data:image/png;base64,${imgPart.b64_json}`;
    }

    const out = direct || b64 || fromContent;
    if (!out || typeof out !== "string") throw new Error("NoImage");

    return out;
}

/** ------------------ HTTPS Callable ------------------ */

export const generateImage = onCall(
    {
        region: "southamerica-east1",
        secrets: [OPENROUTER_API_KEY],
        cors: true,
        timeoutSeconds: 180,
        memory: "1GiB",
    },
    async (req) => {
        if (!req.auth)
            throw new HttpsError("unauthenticated", "Auth requerida.");

        // Aceita chaves alternativas vindas do cliente
        const tema = normalizeTema(req.data?.tema ?? req.data?.topic ?? req.data?.subject);
        const subarea = normalizeSubarea(req.data?.subarea ?? req.data?.sub);
        const estilo = normalizeEstilo(req.data?.estilo ?? req.data?.style);
        const detalhes = normalizeDetalhes(req.data?.detalhes ?? req.data?.prompt);
        const aspectRatio = normalizeAspect(req.data?.aspectRatio ?? req.data?.ratio);

        const apiKey = OPENROUTER_API_KEY.value();
        if (!apiKey) {
            throw new HttpsError("failed-precondition", "Chave do OpenRouter ausente.");
        }

        const inf = inferTemaSubarea(detalhes, tema, subarea);
        const temaR = inf.tema;
        const subR = inf.subarea;

        const modelos = modelosPadrao();
        const prompts = montarPrompts(temaR, subR, estilo, detalhes);

        logger.info("generateImage: start", {
            temaR,
            subR,
            estilo,
            aspectRatio,
            uid: req.auth.uid,
        });

        for (const p of prompts) {
            for (const mdl of modelos) {
                try {
                    const url = await chamarOpenRouter(mdl, p, aspectRatio, apiKey);
                    logger.info("generateImage: success", { model: mdl });
                    return {
                        imageDataUrl: url,
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
                } catch (err) {
                    logger.warn("generateImage: attempt failed", {
                        model: mdl,
                        error: (err as Error).message,
                    });
                    continue;
                }
            }
        }

        throw new HttpsError(
            "internal",
            "Nenhum modelo conseguiu gerar a imagem para este pedido."
        );
    }
);

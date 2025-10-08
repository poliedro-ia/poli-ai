import { z } from "zod";

export const GenerateSchema = z.object({
    subject: z.enum(["fisica", "quimica"]),
    subarea: z.string().min(1),
    style: z.enum(["vetor", "realista", "cartoon", "diagramatico"]),
    details: z.string().min(3).max(800),
    aspectRatio: z.enum(["1:1", "16:9", "4:3"]).default("1:1"),
    model: z.string().default("google/gemini-2.5-flash-image-preview"),
});

export const EditSchema = z.object({
    imageUrl: z.string().url(),
    instruction: z.string().min(3).max(600),
    subject: z.enum(["fisica", "quimica"]),
    subarea: z.string().min(1),
    style: z.enum(["vetor", "realista", "cartoon", "diagramatico"]),
    aspectRatio: z.enum(["1:1", "16:9", "4:3"]).default("1:1"),
    model: z.string().default("google/gemini-2.5-flash-image-preview"),
});

export type GenerateInput = z.infer<typeof GenerateSchema>;
export type EditInput = z.infer<typeof EditSchema>;

export const Allowed = {
    fisica: ["mecanica", "optica", "eletricidade", "termodinamica"],
    quimica: ["estruturas", "cinetica", "termoquimica", "titulacoes", "organica"], // ajuste com o Prof. Cassiano
};

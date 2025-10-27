import { z } from "zod";

export const InputSchema = z.object({
    tema: z.enum(["fisica", "quimica"]),
    subarea: z.string().min(2).max(40),
    estilo: z.enum(["vetor", "realista", "desenho animado"]),
    detalhes: z.string().min(3).max(1000),
    aspectRatio: z.enum(["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"]).default("1:1"),
});

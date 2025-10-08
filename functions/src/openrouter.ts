import { OPENROUTER_API_KEY } from "./config";

const BASE = "https://openrouter.ai/api/v1";

export async function chatCompletions(body: any) {
    const apiKey = OPENROUTER_API_KEY.value();
    if (!apiKey) throw new Error("OPENROUTER_API_KEY ausente");

    const resp = await fetch(`${BASE}/chat/completions`, {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${apiKey}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
    });
    if (!resp.ok) throw new Error(await resp.text());
    const json = await resp.json();
    return json as any; // tipagem solta para evitar "choices does not exist"
}

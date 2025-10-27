import fetch from "node-fetch";

export async function chamarOpenRouter(model: string, prompt: string, aspect: string, apiKey: string) {
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

export async function baixarComoBuffer(source: { kind: "url" | "b64"; value: string }) {
    if (source.kind === "b64") {
        return Buffer.from(source.value, "base64");
    }
    const r = await fetch(source.value);
    if (!r.ok) throw new Error(`DL ${r.status}`);
    return Buffer.from(await r.arrayBuffer());
}

import { setGlobalOptions } from "firebase-functions/v2/options";
import { defineSecret } from "firebase-functions/params";

export const REGION = "southamerica-east1";

// Secrets (podem ser vazios em dev; em prod o Functions injeta)
export const OPENROUTER_API_KEY = defineSecret("OPENROUTER_API_KEY");
export const SUPERADMIN_EMAIL = defineSecret("SUPERADMIN_EMAIL");
export const ALLOWED_DOMAINS = defineSecret("ALLOWED_DOMAINS"); // JSON string '["dominio1","dominio2"]'

// Opções globais dos functions v2
setGlobalOptions({
    region: REGION,
    cpu: 1,
    memory: "512MiB",
    timeoutSeconds: 120,
});

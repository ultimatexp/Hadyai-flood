import { cert, getApps, initializeApp, type App, type ServiceAccount } from "firebase-admin/app";

let cachedApp: App | null = null;

/**
 * Firebase Admin (server only). Requires FIREBASE_SERVICE_ACCOUNT_JSON:
 * the full JSON of a Firebase service account key, as a single-line string.
 */
export function getFirebaseAdminApp(): App {
    if (cachedApp) return cachedApp;
    const existing = getApps()[0];
    if (existing) {
        cachedApp = existing;
        return existing;
    }
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    if (!raw?.trim()) {
        throw new Error("Missing FIREBASE_SERVICE_ACCOUNT_JSON");
    }
    const serviceAccount = JSON.parse(raw) as ServiceAccount;
    cachedApp = initializeApp({
        credential: cert(serviceAccount),
    });
    return cachedApp;
}

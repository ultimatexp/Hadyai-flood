"use server";

import { getAuth } from "firebase-admin/auth";
import { getFirebaseAdminApp } from "@/lib/firebase-admin";

const ADMIN_CONSOLE_UID = "web_admin_console";

/**
 * Optional staff backdoor: set ADMIN_WEB_PASSWORD on the server.
 * Issues a Firebase custom token for a fixed console UID (not LINE).
 */
export async function createAdminConsoleCustomToken(password: string) {
    const expected = process.env.ADMIN_WEB_PASSWORD?.trim();
    if (!expected) {
        return { ok: false as const, error: "not_configured" as const };
    }
    if (password !== expected) {
        return { ok: false as const, error: "invalid" as const };
    }

    try {
        const auth = getAuth(getFirebaseAdminApp());
        const customToken = await auth.createCustomToken(ADMIN_CONSOLE_UID, {
            web_admin: true,
        });
        return { ok: true as const, customToken };
    } catch (e: unknown) {
        const message = e instanceof Error ? e.message : "token_failed";
        return { ok: false as const, error: message };
    }
}

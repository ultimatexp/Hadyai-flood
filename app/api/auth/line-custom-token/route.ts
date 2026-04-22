import { NextResponse } from "next/server";
import { getAuth } from "firebase-admin/auth";
import { getFirebaseAdminApp } from "@/lib/firebase-admin";

async function verifyLineIdToken(idToken: string, clientId: string) {
    const body = new URLSearchParams();
    body.set("id_token", idToken);
    body.set("client_id", clientId);

    const res = await fetch("https://api.line.me/oauth2/v2.1/verify", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: body.toString(),
    });

    const data = (await res.json()) as Record<string, unknown>;
    if (!res.ok) {
        const msg =
            (data.error_description as string) ||
            (data.error as string) ||
            "LINE id_token verification failed";
        throw new Error(msg);
    }
    return data as {
        sub: string;
        name?: string;
        picture?: string;
    };
}

/**
 * Exchange a LINE ID token (from LIFF or LINE Login) for a Firebase custom token.
 * Env: LINE_CHANNEL_ID (LINE Login channel ID), FIREBASE_SERVICE_ACCOUNT_JSON
 */
export async function POST(req: Request) {
    try {
        const channelId = process.env.LINE_CHANNEL_ID?.trim();
        if (!channelId) {
            return NextResponse.json(
                { error: "Server misconfiguration: LINE_CHANNEL_ID is not set" },
                { status: 500 }
            );
        }

        const body = (await req.json()) as { idToken?: string };
        const idToken = body.idToken?.trim();
        if (!idToken) {
            return NextResponse.json({ error: "idToken is required" }, { status: 400 });
        }

        const lineProfile = await verifyLineIdToken(idToken, channelId);
        const uid = `line_${lineProfile.sub}`;

        const auth = getAuth(getFirebaseAdminApp());
        const customToken = await auth.createCustomToken(uid, {
            line_sub: lineProfile.sub,
            provider: "line",
        });

        return NextResponse.json({
            customToken,
            profile: {
                sub: lineProfile.sub,
                name: lineProfile.name ?? null,
                picture: lineProfile.picture ?? null,
            },
        });
    } catch (e: unknown) {
        const message = e instanceof Error ? e.message : "Authentication failed";
        return NextResponse.json({ error: message }, { status: 401 });
    }
}

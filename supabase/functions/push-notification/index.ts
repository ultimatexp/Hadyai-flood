import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'https://www.googleapis.com/discovery/v1/apis/compute/v1/rest' // Just for type if needed, but we use manual token or service account
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

// Google OAuth for FCM V1
// We need to generate an access token using the Service Account
// Minimal implementation to get access token from Service Account JSON
async function getAccessToken(serviceAccount: any) {
    const jwtHeader = { alg: 'RS256', typ: 'JWT' };
    const now = Math.floor(Date.now() / 1000);
    const jwtClaimSet = {
        iss: serviceAccount.client_email,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        exp: now + 3600,
        iat: now,
    };

    const encodedHeader = btoa(JSON.stringify(jwtHeader));
    const encodedClaimSet = btoa(JSON.stringify(jwtClaimSet));

    // Sign
    const keyMap = await crypto.subtle.importKey(
        "pkcs8",
        pemToArrayBuffer(serviceAccount.private_key),
        { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
        false,
        ["sign"]
    );

    const signature = await crypto.subtle.sign(
        "RSASSA-PKCS1-v1_5",
        keyMap,
        new TextEncoder().encode(encodedHeader + "." + encodedClaimSet)
    );

    const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
        .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, ''); // URL Safe

    const jwt = `${encodedHeader.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')}.${encodedClaimSet.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')}.${encodedSignature}`;

    const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`
    });

    const data = await res.json();
    return data.access_token;
}

function pemToArrayBuffer(pem: string) {
    const b64Lines = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "").replace(/\s/g, "");
    const b64Prefix = b64Lines.replace(/-/g, "+").replace(/_/g, "/");
    const binaryDerString = atob(b64Prefix);
    const binaryDer = new Uint8Array(binaryDerString.length);
    for (let i = 0; i < binaryDerString.length; i++) {
        binaryDer[i] = binaryDerString.charCodeAt(i);
    }
    return binaryDer.buffer;
}

serve(async (req) => {
    try {
        const { record } = await req.json()

        // Only process inserts
        if (!record) {
            return new Response('No record', { status: 400 })
        }

        const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        // 1. Get Conversation Participants to find Recipient
        const { data: participants, error: pError } = await supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', record.conversation_id)
            .neq('user_id', record.sender_id) // Exclude sender

        if (pError || !participants || participants.length === 0) {
            console.error('No recipients found or error', pError)
            return new Response('No recipients', { status: 200 })
        }

        // 2. Get FCM Tokens for recipients
        const recipientIds = participants.map(p => p.user_id)
        const { data: profiles, error: uError } = await supabase
            .from('profiles')
            .select('fcm_token, full_name') // Might want sender name too?
            .in('id', recipientIds)
            .not('fcm_token', 'is', null)

        if (uError || !profiles || profiles.length === 0) {
            console.log('No registered devices for recipients')
            return new Response('No devices', { status: 200 })
        }

        // 3. Get Sender Name (Optional, for Notification Title)
        // Could optimize by caching or including in payload if possible, but query is fine
        const { data: sender } = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', record.sender_id)
            .single()

        const senderName = sender?.full_name ?? 'Someone';
        const messageBody = record.content ?? (record.image_url ? 'Sent an image' : 'Sent a message');

        // 4. Send via FCM V1 HTTP API
        const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
        if (!serviceAccountStr) {
            console.error('Missing FIREBASE_SERVICE_ACCOUNT')
            return new Response('Config Error', { status: 500 })
        }

        const serviceAccount = JSON.parse(serviceAccountStr)
        const accessToken = await getAccessToken(serviceAccount)
        const projectId = serviceAccount.project_id

        const promises = profiles.map(async (profile) => {
            const message = {
                message: {
                    token: profile.fcm_token,
                    notification: {
                        title: senderName,
                        body: messageBody,
                    },
                    data: {
                        conversation_id: record.conversation_id,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        type: 'CHAT_MESSAGE',
                        sender_id: record.sender_id // useful for navigation
                    }
                }
            }

            const res = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(message)
            })

            const result = await res.json()
            console.log(`Sent to ${profile.fcm_token}:`, result)
        })

        await Promise.all(promises)

        return new Response(JSON.stringify({ success: true }), { headers: { 'Content-Type': 'application/json' } })
    } catch (error) {
        console.error(error)
        return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: { 'Content-Type': 'application/json' } })
    }
})

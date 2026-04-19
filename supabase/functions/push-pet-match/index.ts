import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

async function getAccessToken(serviceAccount: Record<string, unknown>) {
  const jwtHeader = { alg: 'RS256', typ: 'JWT' }
  const now = Math.floor(Date.now() / 1000)
  const jwtClaimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }

  const encodedHeader = btoa(JSON.stringify(jwtHeader))
  const encodedClaimSet = btoa(JSON.stringify(jwtClaimSet))

  const keyMap = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key as string),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  )

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    keyMap,
    new TextEncoder().encode(encodedHeader + '.' + encodedClaimSet),
  )

  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')

  const jwt = `${encodedHeader.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')}.${encodedClaimSet.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')}.${encodedSignature}`

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })

  const data = await res.json()
  return data.access_token as string
}

function pemToArrayBuffer(pem: string) {
  const b64Lines = pem.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\s/g, '')
  const b64Prefix = b64Lines.replace(/-/g, '+').replace(/_/g, '/')
  const binaryDerString = atob(b64Prefix)
  const binaryDer = new Uint8Array(binaryDerString.length)
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i)
  }
  return binaryDer.buffer
}

/** FCM `data` payload: all values must be strings. */
function buildPetMatchData(record: Record<string, unknown>): Record<string, string> {
  const out: Record<string, string> = {
    type: 'PET_MATCH',
    notification_id: String(record.id),
  }
  const raw = record.data
  const dataObj = typeof raw === 'object' && raw !== null && !Array.isArray(raw)
    ? raw as Record<string, unknown>
    : {}
  for (const [k, v] of Object.entries(dataObj)) {
    if (v == null) continue
    if (typeof v === 'object') out[k] = JSON.stringify(v)
    else out[k] = String(v)
  }
  return out
}

serve(async (req) => {
  try {
    const body = await req.json()
    const record = body.record as Record<string, unknown> | undefined
    if (!record) {
      return new Response('No record', { status: 400 })
    }

    if (String(record.type) !== 'pet_match') {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const userId = record.user_id as string | undefined
    if (!userId) {
      return new Response('No user_id', { status: 400 })
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    const { data: profile, error: pError } = await supabase
      .from('profiles')
      .select('fcm_token')
      .eq('id', userId)
      .maybeSingle()

    if (pError || !profile?.fcm_token) {
      console.log('No FCM token for user', userId, pError)
      return new Response(JSON.stringify({ ok: true, sent: false }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountStr) {
      console.error('Missing FIREBASE_SERVICE_ACCOUNT')
      return new Response('Config Error', { status: 500 })
    }

    const serviceAccount = JSON.parse(serviceAccountStr)
    const accessToken = await getAccessToken(serviceAccount)
    const projectId = serviceAccount.project_id as string

    const title = String(record.title ?? 'Potential match')
    const bodyText = String(record.message ?? '')

    const message = {
      message: {
        token: profile.fcm_token as string,
        notification: {
          title,
          body: bodyText,
        },
        data: {
          ...buildPetMatchData(record),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    }

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message),
      },
    )

    const result = await res.json()
    console.log('FCM pet_match result:', result)

    return new Response(JSON.stringify({ success: true, result }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error: unknown) {
    console.error(error)
    const msg = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: msg }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

import { NextResponse } from 'next/server';

export async function GET() {
  const channelId = process.env.LINE_CHANNEL_ID;
  // Determine the base URL from environment or default
  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 
    (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : 'http://localhost:3000');
  const redirectUri = `${baseUrl}/api/auth/line/callback`;
  
  // Generate a random state for CSRF protection
  const state = Math.random().toString(36).substring(2, 15);
  
  const lineAuthUrl = new URL('https://access.line.me/oauth2/v2.1/authorize');
  lineAuthUrl.searchParams.set('response_type', 'code');
  lineAuthUrl.searchParams.set('client_id', channelId!);
  lineAuthUrl.searchParams.set('redirect_uri', redirectUri);
  lineAuthUrl.searchParams.set('state', state);
  lineAuthUrl.searchParams.set('scope', 'profile openid');

  // Store state in a short-lived cookie for verification
  const response = NextResponse.redirect(lineAuthUrl.toString());
  response.cookies.set('line_oauth_state', state, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: 300, // 5 minutes
    path: '/',
    sameSite: 'lax',
  });

  return response;
}

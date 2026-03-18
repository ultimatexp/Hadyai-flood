import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { createSessionToken } from '@/lib/auth-session';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const code = searchParams.get('code');
  const state = searchParams.get('state');
  const error = searchParams.get('error');

  const baseUrl = process.env.NEXT_PUBLIC_BASE_URL || 
    (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : 'http://localhost:3000');

  // Check for errors from LINE
  if (error) {
    return NextResponse.redirect(`${baseUrl}/fuel?auth_error=denied`);
  }

  if (!code) {
    return NextResponse.redirect(`${baseUrl}/fuel?auth_error=no_code`);
  }

  // Verify state (CSRF protection)
  const storedState = request.cookies.get('line_oauth_state')?.value;
  if (!storedState || storedState !== state) {
    return NextResponse.redirect(`${baseUrl}/fuel?auth_error=invalid_state`);
  }

  try {
    // Exchange code for access token
    const redirectUri = `${baseUrl}/api/auth/line/callback`;
    const tokenRes = await fetch('https://api.line.me/oauth2/v2.1/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: redirectUri,
        client_id: process.env.LINE_CHANNEL_ID!,
        client_secret: process.env.LINE_CHANNEL_SECRET!,
      }),
    });

    if (!tokenRes.ok) {
      console.error('LINE token exchange failed:', await tokenRes.text());
      return NextResponse.redirect(`${baseUrl}/fuel?auth_error=token_failed`);
    }

    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token;

    // Fetch user profile from LINE
    const profileRes = await fetch('https://api.line.me/v2/profile', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!profileRes.ok) {
      console.error('LINE profile fetch failed:', await profileRes.text());
      return NextResponse.redirect(`${baseUrl}/fuel?auth_error=profile_failed`);
    }

    const profile = await profileRes.json();
    const { userId, displayName, pictureUrl } = profile;

    // Upsert user in Supabase
    await supabase
      .from('fuel_users')
      .upsert({
        line_user_id: userId,
        display_name: displayName,
        picture_url: pictureUrl || null,
        last_login_at: new Date().toISOString(),
      }, { onConflict: 'line_user_id' });

    // Create session token
    const sessionToken = await createSessionToken({
      line_user_id: userId,
      display_name: displayName,
      picture_url: pictureUrl || null,
    });

    // Set session cookie and redirect to /fuel
    const response = NextResponse.redirect(`${baseUrl}/fuel`);
    response.cookies.set('fuel_session', sessionToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 30, // 30 days
      path: '/',
      sameSite: 'lax',
    });
    // Clear the oauth state cookie
    response.cookies.delete('line_oauth_state');

    return response;
  } catch (err) {
    console.error('LINE callback error:', err);
    return NextResponse.redirect(`${baseUrl}/fuel?auth_error=server_error`);
  }
}

import { NextResponse } from 'next/server';

export async function GET() {
  const response = NextResponse.redirect(new URL('/fuel', process.env.NEXT_PUBLIC_BASE_URL || 
    (process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : 'http://localhost:3000')));
  
  response.cookies.set('fuel_session', '', {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: 0,
    path: '/',
  });

  return response;
}

export async function POST() {
  const response = NextResponse.json({ success: true });
  
  response.cookies.set('fuel_session', '', {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: 0,
    path: '/',
  });

  return response;
}

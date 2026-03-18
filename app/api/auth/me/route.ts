import { NextRequest, NextResponse } from 'next/server';
import { verifySessionToken } from '@/lib/auth-session';

export async function GET(request: NextRequest) {
  const token = request.cookies.get('fuel_session')?.value;

  if (!token) {
    return NextResponse.json({ user: null });
  }

  const user = await verifySessionToken(token);
  return NextResponse.json({ user });
}

'use server';

import { SignJWT, jwtVerify } from 'jose';
import { cookies } from 'next/headers';

const JWT_SECRET = new TextEncoder().encode(process.env.JWT_SECRET || 'default-secret');
const COOKIE_NAME = 'fuel_session';

export interface FuelUser {
  line_user_id: string;
  display_name: string;
  picture_url: string | null;
}

export async function createSessionToken(user: FuelUser): Promise<string> {
  return new SignJWT({ ...user })
    .setProtectedHeader({ alg: 'HS256' })
    .setExpirationTime('30d')
    .setIssuedAt()
    .sign(JWT_SECRET);
}

export async function verifySessionToken(token: string): Promise<FuelUser | null> {
  try {
    const { payload } = await jwtVerify(token, JWT_SECRET);
    return {
      line_user_id: payload.line_user_id as string,
      display_name: payload.display_name as string,
      picture_url: (payload.picture_url as string) || null,
    };
  } catch {
    return null;
  }
}

export async function getSession(): Promise<FuelUser | null> {
  const cookieStore = await cookies();
  const token = cookieStore.get(COOKIE_NAME)?.value;
  if (!token) return null;
  return verifySessionToken(token);
}

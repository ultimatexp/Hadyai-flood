import { NextRequest, NextResponse } from 'next/server';
import { getStripe } from '@/lib/stripe-server';

const PRESET_THB = [30, 50, 99] as const;
const MIN_CUSTOM_THB = 10;
const MAX_CUSTOM_THB = 50_000;

function siteOrigin(request: NextRequest): string {
  const env = process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, '');
  if (env) return env;
  const vercel = process.env.VERCEL_URL;
  if (vercel) return `https://${vercel}`;
  return request.nextUrl.origin;
}

function sanitizeName(raw: unknown): string | undefined {
  if (typeof raw !== 'string') return undefined;
  const t = raw.trim().slice(0, 60);
  if (!t) return undefined;
  return t.replace(/[\u0000-\u001F<>]/g, '');
}

export async function POST(request: NextRequest) {
  if (!process.env.STRIPE_SECRET_KEY) {
    return NextResponse.json({ error: 'Stripe is not configured' }, { status: 503 });
  }

  let body: { amountThb?: number; displayName?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const amountThb = Number(body.amountThb);
  if (!Number.isFinite(amountThb) || amountThb <= 0) {
    return NextResponse.json({ error: 'Invalid amount' }, { status: 400 });
  }

  const amountSatang = Math.round(amountThb * 100);
  if (amountSatang % 100 !== 0) {
    return NextResponse.json({ error: 'Use whole THB amounts only' }, { status: 400 });
  }

  const thb = amountSatang / 100;
  const isPreset = (PRESET_THB as readonly number[]).includes(thb);
  if (!isPreset && (thb < MIN_CUSTOM_THB || thb > MAX_CUSTOM_THB)) {
    return NextResponse.json(
      {
        error: `Choose ${PRESET_THB.join(', ')} THB or enter ${MIN_CUSTOM_THB}–${MAX_CUSTOM_THB} THB`,
      },
      { status: 400 },
    );
  }

  const displayName = sanitizeName(body.displayName);

  const stripe = getStripe();
  const origin = siteOrigin(request);

  const session = await stripe.checkout.sessions.create({
    mode: 'payment',
    line_items: [
      {
        quantity: 1,
        price_data: {
          currency: 'thb',
          unit_amount: amountSatang,
          product_data: {
            name: 'เลี้ยงกาแฟทีมงาน',
            description: 'Hadyai Flood / Fondue',
          },
        },
      },
    ],
    success_url: `${origin}/donate/thank-you?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${origin}/donate?donation=cancel`,
    metadata: {
      display_name: displayName ?? '',
    },
  });

  if (!session.url) {
    return NextResponse.json({ error: 'Could not start checkout' }, { status: 500 });
  }

  return NextResponse.json({ url: session.url });
}

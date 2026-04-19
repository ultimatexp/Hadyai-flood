import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';
import { getStripe } from '@/lib/stripe-server';

export const runtime = 'nodejs';

function getSupabaseAdmin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error('Supabase admin env missing');
  return createClient(url, key);
}

export async function POST(request: NextRequest) {
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!secret) {
    return NextResponse.json({ error: 'Webhook not configured' }, { status: 503 });
  }

  const rawBody = await request.text();
  const sig = request.headers.get('stripe-signature');
  if (!sig) {
    return NextResponse.json({ error: 'Missing signature' }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    const stripe = getStripe();
    event = stripe.webhooks.constructEvent(rawBody, sig, secret);
  } catch (e) {
    const message = e instanceof Error ? e.message : 'Invalid payload';
    return NextResponse.json({ error: message }, { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    if (session.payment_status !== 'paid') {
      return NextResponse.json({ received: true, skipped: 'not_paid' });
    }
    const sessionId = session.id;
    const amount = session.amount_total;
    const currency = (session.currency ?? 'thb').toLowerCase();
    if (!amount || currency !== 'thb') {
      return NextResponse.json({ received: true, skipped: 'bad_amount' });
    }

    const displayNameRaw = session.metadata?.display_name?.trim();
    const displayName = displayNameRaw ? displayNameRaw.slice(0, 60) : null;

    const supabase = getSupabaseAdmin();
    const { error } = await supabase.from('donations').insert({
      stripe_checkout_session_id: sessionId,
      amount_satang: amount,
      currency,
      display_name: displayName,
    });

    if (error) {
      if (error.code === '23505') {
        return NextResponse.json({ received: true, duplicate: true });
      }
      console.error('donations insert', error);
      return NextResponse.json({ error: 'Database error' }, { status: 500 });
    }
  }

  return NextResponse.json({ received: true });
}

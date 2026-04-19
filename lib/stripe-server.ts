import Stripe from 'stripe';

const apiVersion: Stripe.LatestApiVersion = '2025-02-24.acacia';

export function getStripe(): Stripe {
  const key = process.env.STRIPE_SECRET_KEY;
  if (!key) {
    throw new Error('STRIPE_SECRET_KEY is not set');
  }
  return new Stripe(key, { apiVersion });
}

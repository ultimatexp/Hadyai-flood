-- Mock donors for UI / leaderboard testing (not real Stripe sessions).
-- Prefer `bootstrap_fondue_donations.sql` (creates table + policy + mocks) on the Fondue project.
-- Run in Supabase SQL editor when needed. Safe to re-run: skips if IDs exist.

insert into public.donations (stripe_checkout_session_id, amount_satang, currency, display_name, created_at)
values
  ('cs_test_mock_seed_001', 3000, 'thb', 'แอน', now() - interval '5 days'),
  ('cs_test_mock_seed_002', 5000, 'thb', 'บีม', now() - interval '4 days'),
  ('cs_test_mock_seed_003', 9900, 'thb', 'ซีโน', now() - interval '3 days'),
  ('cs_test_mock_seed_004', 19900, 'thb', 'ดีน', now() - interval '2 days'),
  ('cs_test_mock_seed_005', 25000, 'thb', 'อีฟ', now() - interval '1 day')
on conflict (stripe_checkout_session_id) do nothing;

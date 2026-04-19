-- Run in Supabase Dashboard → SQL Editor for the SAME project as fondue/lib/core/config/constants.dart
-- (currently https://tympremgrvknekswiaar.supabase.co). MCP / other DBs may differ.
-- Creates donations + RLS + optional RPC, then mock rows for UI testing.

-- Donations recorded from Stripe Checkout (webhook). Public read for app wall / leaderboard.

create table if not exists public.donations (
  id uuid primary key default gen_random_uuid(),
  stripe_checkout_session_id text not null unique,
  amount_satang integer not null check (amount_satang > 0),
  currency text not null default 'thb',
  display_name text,
  created_at timestamptz not null default now()
);

create index if not exists donations_created_at_idx on public.donations (created_at desc);

alter table public.donations enable row level security;

drop policy if exists "Public read donations" on public.donations;
create policy "Public read donations"
  on public.donations
  for select
  to anon, authenticated
  using (true);

create or replace function public.donation_top_donors(limit_n integer default 3)
returns table(display_name text, total_satang bigint, donation_count bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select
    trim(d.display_name) as display_name,
    sum(d.amount_satang)::bigint as total_satang,
    count(*)::bigint as donation_count
  from public.donations d
  where length(trim(coalesce(d.display_name, ''))) > 0
  group by trim(d.display_name)
  order by total_satang desc, donation_count desc
  limit coalesce(limit_n, 3);
$$;

grant execute on function public.donation_top_donors(integer) to anon, authenticated;

-- Mock donors (฿30, 50, 99, 199, 250)
insert into public.donations (stripe_checkout_session_id, amount_satang, currency, display_name, created_at)
values
  ('cs_test_mock_seed_001', 3000, 'thb', 'แอน', now() - interval '5 days'),
  ('cs_test_mock_seed_002', 5000, 'thb', 'บีม', now() - interval '4 days'),
  ('cs_test_mock_seed_003', 9900, 'thb', 'ซีโน', now() - interval '3 days'),
  ('cs_test_mock_seed_004', 19900, 'thb', 'ดีน', now() - interval '2 days'),
  ('cs_test_mock_seed_005', 25000, 'thb', 'อีฟ', now() - interval '1 day')
on conflict (stripe_checkout_session_id) do nothing;

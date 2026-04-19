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

-- Top donors by total (named only; anonymous excluded from leaderboard)
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

-- Claim/transfer workflow for pet ownership handoff

create table if not exists public.pet_claims (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  owner_user_id uuid not null,
  claimant_user_id uuid not null,
  note text,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'withdrawn')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (pet_id, claimant_user_id)
);

create table if not exists public.pet_transfers (
  id uuid primary key default gen_random_uuid(),
  pet_id uuid not null references public.pets(id) on delete cascade,
  claim_id uuid not null references public.pet_claims(id) on delete cascade,
  owner_user_id uuid not null,
  claimant_user_id uuid not null,
  status text not null default 'pending_claimant_confirmation'
    check (status in ('pending_claimant_confirmation', 'confirmed', 'cancelled', 'expired')),
  owner_submitted_at timestamptz not null default now(),
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_pet_claims_pet_id on public.pet_claims(pet_id);
create index if not exists idx_pet_claims_claimant on public.pet_claims(claimant_user_id);
create index if not exists idx_pet_claims_owner on public.pet_claims(owner_user_id);
create index if not exists idx_pet_claims_status on public.pet_claims(status);

create index if not exists idx_pet_transfers_pet_id on public.pet_transfers(pet_id);
create index if not exists idx_pet_transfers_claimant on public.pet_transfers(claimant_user_id);
create index if not exists idx_pet_transfers_owner on public.pet_transfers(owner_user_id);
create index if not exists idx_pet_transfers_status on public.pet_transfers(status);

-- Only one active pending transfer per pet.
create unique index if not exists uq_pet_transfers_one_pending_per_pet
  on public.pet_transfers (pet_id)
  where status = 'pending_claimant_confirmation';

-- Basic timestamp trigger support.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_pet_claims_set_updated_at on public.pet_claims;
create trigger trg_pet_claims_set_updated_at
before update on public.pet_claims
for each row execute procedure public.set_updated_at();

drop trigger if exists trg_pet_transfers_set_updated_at on public.pet_transfers;
create trigger trg_pet_transfers_set_updated_at
before update on public.pet_transfers
for each row execute procedure public.set_updated_at();

alter table public.pet_claims enable row level security;
alter table public.pet_transfers enable row level security;

-- Claims: claimant can create, owner/claimant can read.
drop policy if exists "pet_claims_select_owner_or_claimant" on public.pet_claims;
create policy "pet_claims_select_owner_or_claimant"
on public.pet_claims
for select
using (auth.uid() = owner_user_id or auth.uid() = claimant_user_id);

drop policy if exists "pet_claims_insert_claimant_only" on public.pet_claims;
create policy "pet_claims_insert_claimant_only"
on public.pet_claims
for insert
with check (auth.uid() = claimant_user_id);

drop policy if exists "pet_claims_update_owner_or_claimant" on public.pet_claims;
create policy "pet_claims_update_owner_or_claimant"
on public.pet_claims
for update
using (auth.uid() = owner_user_id or auth.uid() = claimant_user_id)
with check (auth.uid() = owner_user_id or auth.uid() = claimant_user_id);

-- Transfers: owner/claimant can read. Owner creates/cancels. Claimant confirms.
drop policy if exists "pet_transfers_select_owner_or_claimant" on public.pet_transfers;
create policy "pet_transfers_select_owner_or_claimant"
on public.pet_transfers
for select
using (auth.uid() = owner_user_id or auth.uid() = claimant_user_id);

drop policy if exists "pet_transfers_insert_owner_only" on public.pet_transfers;
create policy "pet_transfers_insert_owner_only"
on public.pet_transfers
for insert
with check (auth.uid() = owner_user_id);

drop policy if exists "pet_transfers_update_owner_or_claimant" on public.pet_transfers;
create policy "pet_transfers_update_owner_or_claimant"
on public.pet_transfers
for update
using (auth.uid() = owner_user_id or auth.uid() = claimant_user_id)
with check (auth.uid() = owner_user_id or auth.uid() = claimant_user_id);

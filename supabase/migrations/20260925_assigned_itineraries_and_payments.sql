-- Phase 1 booking model: a tourist requests an itinerary (or submits a free-
-- form "Suggest an Itinerary"), admin manually lines up an operator outside
-- the platform, the operator builds a custom package (existing operator
-- itinerary builder, source='operator_proposed'), and admin links that
-- specific package to the one tourist it was made for — it's never listed
-- on the public /explore marketplace, only visible to that tourist.
--
-- Payment goes through the platform, not directly to the operator: the
-- tourist pays into the platform's own account (details in
-- platform_settings) and uploads proof same as the existing manual
-- proof-of-payment pattern elsewhere on the site. Admin verifies the
-- payment, then separately (offline, for now) pays the operator their cut
-- and marks the payout done here for bookkeeping.
--
-- NOT APPLIED AUTOMATICALLY — review and run this yourself (SQL editor or
-- your migration tool). Additive only: new nullable columns, new tables.

alter table public.itineraries
  add column if not exists assigned_tourist_id uuid references public.profiles(id) on delete set null,
  add column if not exists source_request_id uuid references public.itinerary_requests(id) on delete set null;

create index if not exists itineraries_assigned_tourist_id_idx on public.itineraries(assigned_tourist_id);

-- A tourist can see the one itinerary assigned to them regardless of its
-- status (it's deliberately never 'published', so the existing public
-- policy never covers it), plus its day-by-day plan and media.
drop policy if exists "Tourists can view their assigned itinerary" on public.itineraries;
create policy "Tourists can view their assigned itinerary"
  on public.itineraries for select
  using (auth.uid() = assigned_tourist_id);

drop policy if exists "Tourists can view days of their assigned itinerary" on public.itinerary_days;
create policy "Tourists can view days of their assigned itinerary"
  on public.itinerary_days for select
  using (exists (
    select 1 from public.itineraries
    where itineraries.id = itinerary_days.itinerary_id
      and itineraries.assigned_tourist_id = auth.uid()
  ));

drop policy if exists "Tourists can view media of their assigned itinerary" on public.itinerary_media;
create policy "Tourists can view media of their assigned itinerary"
  on public.itinerary_media for select
  using (exists (
    select 1 from public.itineraries
    where itineraries.id = itinerary_media.itinerary_id
      and itineraries.assigned_tourist_id = auth.uid()
  ));

-- ============================================================
-- Platform's own payment destination — a single admin-editable row,
-- shown to the tourist instead of the operator's own bank details, since
-- payment is collected by the platform (commission kept, operator paid
-- out separately).
-- ============================================================
create table if not exists public.platform_settings (
  id int primary key default 1,
  payment_bank_name text,
  payment_account_number text,
  payment_account_name text,
  payment_swift_code text,
  payment_wise_email text,
  payment_paypal_email text,
  updated_at timestamptz not null default now(),
  constraint platform_settings_singleton check (id = 1)
);
insert into public.platform_settings (id) values (1) on conflict (id) do nothing;

alter table public.platform_settings enable row level security;

drop policy if exists "Signed-in users can view platform payment settings" on public.platform_settings;
create policy "Signed-in users can view platform payment settings"
  on public.platform_settings for select
  using (auth.role() = 'authenticated');

drop policy if exists "Admins can update platform payment settings" on public.platform_settings;
create policy "Admins can update platform payment settings"
  on public.platform_settings for update
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));

-- ============================================================
-- Payment for an assigned package. Deliberately its own table rather
-- than reusing `payments` (which is keyed to the older `bookings` table
-- and this session couldn't verify its exact constraints) — same manual
-- proof-of-payment shape (status/proof_url/verified_at), plus the
-- operator payout side of the commission split.
-- ============================================================
create table if not exists public.itinerary_payments (
  id uuid primary key default gen_random_uuid(),
  itinerary_id uuid not null references public.itineraries(id) on delete cascade,
  tourist_id uuid not null references public.profiles(id) on delete cascade,
  operator_id uuid references public.profiles(id) on delete set null,
  amount numeric,
  currency text not null default 'USD',
  payment_method text,
  status text not null default 'unpaid' check (status in ('unpaid', 'pending_proof', 'verified')),
  proof_url text,
  proof_uploaded_at timestamptz,
  verified_at timestamptz,
  operator_payout_amount numeric,
  payout_status text not null default 'not_paid' check (payout_status in ('not_paid', 'paid')),
  payout_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists itinerary_payments_itinerary_id_idx on public.itinerary_payments(itinerary_id);
create index if not exists itinerary_payments_tourist_id_idx on public.itinerary_payments(tourist_id);

alter table public.itinerary_payments enable row level security;

drop policy if exists "Tourists can view their own itinerary payments" on public.itinerary_payments;
create policy "Tourists can view their own itinerary payments"
  on public.itinerary_payments for select
  using (auth.uid() = tourist_id);

drop policy if exists "Tourists can create their own itinerary payments" on public.itinerary_payments;
create policy "Tourists can create their own itinerary payments"
  on public.itinerary_payments for insert
  with check (auth.uid() = tourist_id);

-- Tourist can upload proof (move unpaid/pending_proof -> pending_proof)
-- but never mark their own payment verified.
drop policy if exists "Tourists can upload proof on their own payment" on public.itinerary_payments;
create policy "Tourists can upload proof on their own payment"
  on public.itinerary_payments for update
  using (auth.uid() = tourist_id)
  with check (auth.uid() = tourist_id and status in ('unpaid', 'pending_proof'));

drop policy if exists "Admins can manage itinerary payments" on public.itinerary_payments;
create policy "Admins can manage itinerary payments"
  on public.itinerary_payments for all
  using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true))
  with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin = true));

drop policy if exists "Operators can view payments for their own packages" on public.itinerary_payments;
create policy "Operators can view payments for their own packages"
  on public.itinerary_payments for select
  using (auth.uid() = operator_id);

-- Lets operators author their own bookable itineraries directly (the
-- operator "Create New Package" flow), instead of only applying to
-- admin-authored ones. This reuses the EXISTING itineraries/itinerary_days/
-- itinerary_media tables and the `source` column's already-reserved
-- 'operator_proposed' value (see 20260910b_itineraries_base_schema.sql,
-- which added the column with a comment reserving this exact value and
-- never used it) — no new tables, no column changes. `status` is plain
-- text with no check constraint, so the new 'pending_review' value below
-- needs no schema change either.
--
-- Flow: operator creates an itinerary with source='operator_proposed',
-- created_by=their own id, status starts 'draft' while they edit, then
-- 'pending_review' once they hit Publish. Admin reviews (same "Pending
-- Approvals" screen pattern as itinerary_operators applications) and either
-- sets status='published' (goes live, same public RLS policy as
-- admin-authored itineraries) or back to 'draft' with a rejection note
-- left in itinerary_operator_rejections — out of scope here, admin can
-- communicate via existing chat/notification tables.
--
-- NOT APPLIED AUTOMATICALLY — review and run this after the three earlier
-- itinerary-model migrations.

-- Operators can create their own itineraries (only as operator_proposed —
-- they can never claim admin-sourced ones, and can't set themselves as
-- someone else's author).
drop policy if exists "Operators can create their own itineraries" on itineraries;
create policy "Operators can create their own itineraries"
  on itineraries for insert
  with check (
    auth.uid() = created_by
    and source = 'operator_proposed'
  );

-- Operators can see their own itineraries regardless of status (draft/
-- pending_review/published/archived), same pattern as
-- "Operators can view their own applications" on itinerary_operators.
drop policy if exists "Operators can view their own itineraries" on itineraries;
create policy "Operators can view their own itineraries"
  on itineraries for select
  using (auth.uid() = created_by);

-- Operators can edit their own itinerary while it's still draft or sent
-- back for changes — not once it's under review or already published,
-- so a live/reviewed listing can't be silently altered out from under a
-- pending or completed admin decision.
drop policy if exists "Operators can update their own draft itineraries" on itineraries;
create policy "Operators can update their own draft itineraries"
  on itineraries for update
  using (auth.uid() = created_by and status = 'draft')
  with check (auth.uid() = created_by and source = 'operator_proposed');

-- Same three operations, mirrored onto itinerary_days and itinerary_media,
-- scoped through the parent itinerary's created_by/status rather than
-- duplicating an operator_id column onto each table.
drop policy if exists "Operators can manage days of their own draft itineraries" on itinerary_days;
create policy "Operators can manage days of their own draft itineraries"
  on itinerary_days for all
  using (exists (
    select 1 from itineraries
    where itineraries.id = itinerary_days.itinerary_id
      and itineraries.created_by = auth.uid()
  ))
  with check (exists (
    select 1 from itineraries
    where itineraries.id = itinerary_days.itinerary_id
      and itineraries.created_by = auth.uid()
      and itineraries.status = 'draft'
  ));

drop policy if exists "Operators can manage media of their own draft itineraries" on itinerary_media;
create policy "Operators can manage media of their own draft itineraries"
  on itinerary_media for all
  using (exists (
    select 1 from itineraries
    where itineraries.id = itinerary_media.itinerary_id
      and itineraries.created_by = auth.uid()
  ))
  with check (exists (
    select 1 from itineraries
    where itineraries.id = itinerary_media.itinerary_id
      and itineraries.created_by = auth.uid()
      and itineraries.status = 'draft'
  ));

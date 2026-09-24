-- Tightens the "Operators can apply to itineraries" insert policy on
-- itinerary_operators. As originally written, it only checked
-- auth.uid() = operator_id — an operator could insert a row with
-- status = 'approved' for ANY itinerary_id, not just their own, which
-- would let them spoof a "verified operator" badge on someone else's
-- (or an admin-authored) itinerary without going through actual admin
-- approval.
--
-- The website's new operator "Create New Package" flow needs operators
-- to self-link as approved on their OWN operator-authored itinerary
-- (see 20260924_operator_authored_itineraries.sql) — otherwise a
-- published self-authored package has no operator attached to it at
-- all, since every "verified operator" badge/count and the "choose an
-- operator" booking sidebar are driven entirely by itinerary_operators,
-- not by itineraries.created_by.
--
-- This keeps that self-link working while closing the spoofing gap:
-- status = 'pending' is still allowed for any itinerary (the existing
-- "apply to an admin-authored itinerary" flow), but status = 'approved'
-- is only allowed when the operator is inserting for an itinerary they
-- themselves authored (created_by = auth.uid() and
-- source = 'operator_proposed').
--
-- NOT APPLIED AUTOMATICALLY — review and run this alongside the other
-- itinerary-model migrations.

drop policy if exists "Operators can apply to itineraries" on itinerary_operators;
create policy "Operators can apply to itineraries"
  on itinerary_operators for insert
  with check (
    auth.uid() = operator_id
    and (
      status = 'pending'
      or (
        status = 'approved'
        and exists (
          select 1 from itineraries
          where itineraries.id = itinerary_operators.itinerary_id
            and itineraries.created_by = auth.uid()
            and itineraries.source = 'operator_proposed'
        )
      )
    )
  );

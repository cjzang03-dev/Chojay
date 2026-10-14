-- The itinerary_bookings table (20260910_itinerary_bookings.sql) was created
-- with read-only access for operators by design: "operator/admin confirmation
-- UI is a later build-order step... not built yet." That later step (direct
-- "Book This Operator" UI, shipped this session) is now live, but the
-- confirm/decline half was never wired up: operators could see a booking
-- request notification but had no way to act on it, and no RLS policy would
-- have let them even if a button existed. This closes that gap.
--
-- NOT APPLIED AUTOMATICALLY. Review and run yourself (SQL editor or
-- `supabase db push`) before operators can confirm/decline bookings.

-- Operators may only move a booking directed at them to 'confirmed' or
-- 'declined' — not back to 'requested', and not any other row's booking.
-- Tourists still have no update policy (unchanged); cancellation by the
-- tourist is a separate, not-yet-built feature.
create policy "Operators can confirm or decline their itinerary bookings"
  on itinerary_bookings for update
  using (auth.uid() = operator_id)
  with check (auth.uid() = operator_id and status in ('confirmed', 'declined'));

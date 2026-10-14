-- ============================================================================
-- RUN THIS ONE FILE in Supabase's SQL Editor to add a real "events" table —
-- festivals were a hardcoded list in the website's code (app/lib/festivals.ts),
-- so there was nowhere for an admin to add one, and no way to show anything
-- other than a Tsechu festival. This table holds any dzongkhag-level event
-- (festival, market, ceremony, etc.), admin-managed, publicly readable.
--
-- Seeds the 11 festivals that were previously hardcoded, so the public page
-- keeps showing the same data once it switches to reading from this table.
-- Safe to run even if it already exists.
-- ============================================================================

create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  location text,
  dzongkhag text not null,
  category text not null default 'festival', -- 'festival' | 'event'
  icon text, -- optional emoji shown on the event card
  start_date date not null,
  end_date date not null,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists events_start_date_idx on events (start_date);
create index if not exists events_dzongkhag_idx on events (dzongkhag);

alter table events enable row level security;

drop policy if exists "Anyone can view events" on events;
create policy "Anyone can view events"
  on events for select
  using (true);

drop policy if exists "Admins can insert events" on events;
create policy "Admins can insert events"
  on events for insert
  with check (exists (select 1 from profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins can update events" on events;
create policy "Admins can update events"
  on events for update
  using (exists (select 1 from profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins can delete events" on events;
create policy "Admins can delete events"
  on events for delete
  using (exists (select 1 from profiles where id = auth.uid() and is_admin = true));

-- Seed the festivals that were previously hardoded in app/lib/festivals.ts,
-- so switching the website to read from this table doesn't lose any of them.
-- Only runs if the table is currently empty, so re-running this file is safe.
insert into events (name, description, location, dzongkhag, category, icon, start_date, end_date)
select * from (values
  ('Punakha Drubchen', 'A reenactment of a 17th-century battle, followed by the Punakha Tshechu.', 'Punakha Dzong', 'Punakha', 'festival', '⚔️', date '2026-02-22', date '2026-02-25'),
  ('Punakha Tshechu', 'Masked dances celebrating Guru Rinpoche, held right after the Drubchen.', 'Punakha Dzong', 'Punakha', 'festival', '🎭', date '2026-02-26', date '2026-02-28'),
  ('Paro Tshechu', 'One of Bhutan''s most famous festivals, ending with the unveiling of a giant sacred thangka.', 'Rinpung Dzong', 'Paro', 'festival', '🖼️', date '2026-03-29', date '2026-04-02'),
  ('Rhododendron Festival', 'A spring festival celebrating blooming rhododendrons with music, crafts, and family events.', 'Lamperi Botanical Garden', 'Thimphu', 'event', '🌸', date '2026-04-22', date '2026-04-24'),
  ('Thimphu Drubchen', 'Masked dances reenacting Bhutan''s historic victory over Tibetan invasions.', 'Tashichho Dzong', 'Thimphu', 'festival', '⚔️', date '2026-09-17', date '2026-09-17'),
  ('Wangdue Phodrang Tshechu', 'Masked dances and rituals celebrating Guru Rinpoche.', 'Wangdue Phodrang Dzong', 'Wangdue Phodrang', 'festival', '🎭', date '2026-09-19', date '2026-09-21'),
  ('Thimphu Tshechu', 'The largest festival in Bhutan, held in the capital''s courtyard with elaborate masked dances.', 'Tashichho Dzong', 'Thimphu', 'festival', '🎭', date '2026-09-21', date '2026-09-23'),
  ('Gangtey Tshechu', 'Held at the monastery overlooking the Phobjikha Valley, home to the black-necked crane.', 'Gangtey Monastery', 'Wangdue Phodrang', 'festival', '🦢', date '2026-09-24', date '2026-09-26'),
  ('Jambay Lhakhang Drup', 'Famous for the Mewang fire ceremony and the midnight Tercham dance.', 'Jambay Lhakhang', 'Bumthang', 'festival', '🔥', date '2026-11-08', date '2026-11-12'),
  ('Mongar Tshechu', 'Masked dances and prayers celebrating Guru Rinpoche in eastern Bhutan.', 'Mongar Dzong', 'Mongar', 'festival', '🎭', date '2026-11-17', date '2026-11-19'),
  ('Trashigang Tshechu', 'A district Tshechu in Bhutan''s easternmost region.', 'Trashigang Dzong', 'Trashigang', 'festival', '🎭', date '2026-11-18', date '2026-11-20')
) as seed(name, description, location, dzongkhag, category, icon, start_date, end_date)
where not exists (select 1 from events);

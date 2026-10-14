-- ============================================================================
-- RUN THIS ONE FILE in Supabase's SQL Editor to let admins attach a photo to
-- each festival/event (previously events had only an optional emoji icon).
--
-- 1. Adds events.image_url.
-- 2. Creates a public "event-photos" storage bucket admins can upload to
--    (same admin-only-write / anyone-can-read pattern as the events table
--    itself), used by the website's admin Events page.
-- 3. Backfills a real photo for the festivals that have one freely usable
--    on Wikimedia Commons; the rest are left null so an admin can upload one
--    from the admin Events page.
-- Safe to run even if it already exists.
-- ============================================================================

alter table events add column if not exists image_url text;

insert into storage.buckets (id, name, public)
values ('event-photos', 'event-photos', true)
on conflict (id) do nothing;

drop policy if exists "Anyone can view event photos" on storage.objects;
create policy "Anyone can view event photos"
  on storage.objects for select
  using (bucket_id = 'event-photos');

drop policy if exists "Admins can upload event photos" on storage.objects;
create policy "Admins can upload event photos"
  on storage.objects for insert
  with check (bucket_id = 'event-photos' and exists (select 1 from profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins can update event photos" on storage.objects;
create policy "Admins can update event photos"
  on storage.objects for update
  using (bucket_id = 'event-photos' and exists (select 1 from profiles where id = auth.uid() and is_admin = true));

drop policy if exists "Admins can delete event photos" on storage.objects;
create policy "Admins can delete event photos"
  on storage.objects for delete
  using (bucket_id = 'event-photos' and exists (select 1 from profiles where id = auth.uid() and is_admin = true));

-- Freely licensed Wikimedia Commons photos for the festivals that have a
-- clear match (the two without one — Mongar Tshechu, Rhododendron Festival —
-- are left for an admin to upload from the admin Events page).
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/PunakhaDzong.jpg?width=800'
  where name = 'Punakha Drubchen' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/PunakhaDzong.jpg?width=800'
  where name = 'Punakha Tshechu' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Dance_of_the_Black_Hats_with_Drums,_Paro_Tsechu_5.jpg?width=800'
  where name = 'Paro Tshechu' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Thimphu-Dzong-40-2015-gje.jpg?width=800'
  where name = 'Thimphu Drubchen' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Thimphu-Dzong-40-2015-gje.jpg?width=800'
  where name = 'Thimphu Tshechu' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Wangdue_Phodrang_Dzong.jpg?width=800'
  where name = 'Wangdue Phodrang Tshechu' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Gangtey_Tshechu.jpg?width=800'
  where name = 'Gangtey Tshechu' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Bumthang-Jambay_Lhakhang-06-2015-gje.jpg?width=800'
  where name = 'Jambay Lhakhang Drup' and image_url is null;
update events set image_url = 'https://commons.wikimedia.org/wiki/Special:FilePath/Tashigang_Dzong_111120.jpg?width=800'
  where name = 'Trashigang Tshechu' and image_url is null;

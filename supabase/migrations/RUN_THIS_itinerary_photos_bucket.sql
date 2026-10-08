-- ============================================================================
-- RUN THIS ONE FILE in Supabase's SQL Editor to let operators upload a real
-- cover photo for their packages from the app (previously the only option,
-- on both the app and the website, was pasting an image URL by hand).
--
-- Creates a public "itinerary-photos" storage bucket, used by
-- OperatorPackagesRepository.uploadCoverPhoto() for itineraries.cover_photo_url.
-- Safe to run even if it already exists: the bucket insert is a no-op on
-- conflict, and every policy is dropped and recreated.
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('itinerary-photos', 'itinerary-photos', true)
on conflict (id) do nothing;

drop policy if exists "Authenticated users can upload itinerary photos" on storage.objects;
create policy "Authenticated users can upload itinerary photos"
  on storage.objects for insert
  with check (bucket_id = 'itinerary-photos' and auth.role() = 'authenticated');

drop policy if exists "Anyone can view itinerary photos" on storage.objects;
create policy "Anyone can view itinerary photos"
  on storage.objects for select
  using (bucket_id = 'itinerary-photos');

-- Uploads are stored as "<uploader's user id>/<filename>" — these two
-- policies let someone replace or remove only their own uploads.
drop policy if exists "Operators can update their own itinerary photos" on storage.objects;
create policy "Operators can update their own itinerary photos"
  on storage.objects for update
  using (bucket_id = 'itinerary-photos' and auth.uid()::text = (storage.foldername(name))[1]);

drop policy if exists "Operators can delete their own itinerary photos" on storage.objects;
create policy "Operators can delete their own itinerary photos"
  on storage.objects for delete
  using (bucket_id = 'itinerary-photos' and auth.uid()::text = (storage.foldername(name))[1]);

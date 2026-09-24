-- Lets an operator attach an itinerary document they've already made
-- (PDF, Word doc, or scanned image) instead of retyping everything into
-- the day-by-day builder. Tourists see a download link on the itinerary
-- page; the day-by-day plan stays optional alongside it.

alter table public.itineraries add column if not exists itinerary_document_url text;

insert into storage.buckets (id, name, public)
values ('itinerary-documents', 'itinerary-documents', true)
on conflict (id) do nothing;

create policy "Anyone can view itinerary documents"
on storage.objects for select
using (bucket_id = 'itinerary-documents');

create policy "Authenticated users can upload their own itinerary documents"
on storage.objects for insert
with check (
  bucket_id = 'itinerary-documents'
  and auth.role() = 'authenticated'
  and auth.uid()::text = (storage.foldername(name))[1]
);

create policy "Owners can delete their own itinerary documents"
on storage.objects for delete
using (
  bucket_id = 'itinerary-documents'
  and auth.uid()::text = (storage.foldername(name))[1]
);

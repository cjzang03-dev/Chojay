-- Adds a category to itineraries so the public browse page can filter by
-- experience type (Hiking & Trekking, Cultural Tours, Wellness & Yoga,
-- Food & Cooking, Nature & Wildlife, Homestays, ...), matching the new
-- site redesign's category pill row. Purely additive: nullable, no
-- default beyond null, existing rows are unaffected and simply show under
-- no category / "More" until an admin or operator sets one.
--
-- NOT APPLIED AUTOMATICALLY — review and run this alongside the other
-- itinerary-model migrations.

alter table itineraries add column if not exists category text;

create index if not exists itineraries_category_idx on itineraries (category);

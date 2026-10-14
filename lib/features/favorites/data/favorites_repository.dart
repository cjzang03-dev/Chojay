import '../../../core/config/supabase_client.dart';

/// Backed by the website's existing `saved_itineraries` table (tourist_id,
/// itinerary_id, unique together) — a favorite set from the app shows up as
/// the same bookmark on journeyinbhutan.com and vice versa.
class FavoritesRepository {
  Future<Set<String>> fetchFavoriteIds() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return {};

    final rows = await supabase
        .from('saved_itineraries')
        .select('itinerary_id')
        .eq('tourist_id', userId);
    return rows.map((r) => r['itinerary_id'] as String).toSet();
  }

  Future<void> addFavorite(String itineraryId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase.from('saved_itineraries').upsert(
      {'tourist_id': userId, 'itinerary_id': itineraryId},
      onConflict: 'tourist_id,itinerary_id',
    );
  }

  Future<void> removeFavorite(String itineraryId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    await supabase
        .from('saved_itineraries')
        .delete()
        .eq('tourist_id', userId)
        .eq('itinerary_id', itineraryId);
  }
}

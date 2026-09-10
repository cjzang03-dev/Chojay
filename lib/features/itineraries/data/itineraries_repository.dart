import '../../../core/config/supabase_client.dart';
import '../domain/itinerary.dart';

class ItinerariesRepository {
  /// The public catalog: published itineraries only, newest first.
  Future<List<Itinerary>> fetchPublished() async {
    final rows = await supabase
        .from('itineraries')
        .select()
        .eq('status', 'published')
        .order('created_at', ascending: false);
    return rows.map(Itinerary.fromJson).toList();
  }

  Future<Itinerary> fetchById(String id) async {
    final row =
        await supabase.from('itineraries').select().eq('id', id).single();
    return Itinerary.fromJson(row);
  }

  Future<List<ItineraryDay>> fetchDays(String itineraryId) async {
    final rows = await supabase
        .from('itinerary_days')
        .select()
        .eq('itinerary_id', itineraryId)
        .order('day_number');
    return rows.map(ItineraryDay.fromJson).toList();
  }

  /// The tourist's picker list: operators who applied and were admin-approved
  /// for this specific itinerary — never auto-assigned (product decision).
  Future<List<ApprovedOperator>> fetchApprovedOperators(
    String itineraryId,
  ) async {
    final rows = await supabase
        .from('itinerary_operators')
        .select('operator_id')
        .eq('itinerary_id', itineraryId)
        .eq('status', 'approved');

    final operatorIds =
        rows.map((r) => r['operator_id'] as String).toList();
    if (operatorIds.isEmpty) return [];

    // Batched, RLS-safe profile lookup — matches ChatRepository's pattern
    // rather than embedding `profiles` directly (see ApprovedOperator.fromRow).
    final profiles = await supabase
        .rpc('get_public_profiles_by_ids', params: {'profile_ids': operatorIds});
    final profilesById = {
      for (final p in (profiles as List)) (p as Map)['id'] as String: p,
    };

    return rows
        .map((r) => ApprovedOperator.fromRow(
              r,
              profile: profilesById[r['operator_id']] as Map<String, dynamic>?,
            ))
        .toList();
  }

  Future<ItineraryDetail> fetchDetail(String itineraryId) async {
    final itinerary = await fetchById(itineraryId);
    final results = await Future.wait([
      fetchDays(itineraryId),
      fetchApprovedOperators(itineraryId),
    ]);
    return ItineraryDetail(
      itinerary: itinerary,
      days: results[0] as List<ItineraryDay>,
      approvedOperators: results[1] as List<ApprovedOperator>,
    );
  }
}

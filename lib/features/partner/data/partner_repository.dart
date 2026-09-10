import '../../../core/config/supabase_client.dart';
import '../domain/incoming_booking.dart';
import '../domain/itinerary_application.dart';

class PartnerRepository {
  String get _currentUserId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('Must be signed in.');
    return id;
  }

  /// All of this operator/guide's applications, any status, so their
  /// dashboard can show pending/rejected as well as approved.
  Future<List<ItineraryApplication>> fetchApplications() async {
    final rows = await supabase
        .from('itinerary_operators')
        .select('*, itineraries(title, cover_photo_url)')
        .eq('operator_id', _currentUserId)
        .order('applied_at', ascending: false);
    return rows.map(ItineraryApplication.fromJson).toList();
  }

  /// Applies to fulfill [itineraryId]. No-ops (via the unique constraint)
  /// if already applied — surfaced as an error the UI ignores/refreshes on.
  Future<void> applyToItinerary(String itineraryId) async {
    await supabase.from('itinerary_operators').insert({
      'itinerary_id': itineraryId,
      'operator_id': _currentUserId,
      'status': 'pending',
    });
  }

  /// Booking requests tourists have sent to this operator/guide, newest
  /// first, with tourist names filled in via the same batched public-
  /// profile RPC pattern used elsewhere (never a direct `profiles` join).
  Future<List<IncomingBooking>> fetchIncomingBookings() async {
    final rows = await supabase
        .from('itinerary_bookings')
        .select('*, itineraries(title)')
        .eq('operator_id', _currentUserId)
        .order('created_at', ascending: false);

    final bookings = rows.map(IncomingBooking.fromJson).toList();
    final touristIds = bookings.map((b) => b.touristId).toSet().toList();
    if (touristIds.isEmpty) return bookings;

    final profiles = await supabase
        .rpc('get_public_profiles_by_ids', params: {'profile_ids': touristIds});
    final namesById = {
      for (final p in (profiles as List))
        (p as Map)['id'] as String: p['full_name'] as String?,
    };

    return bookings
        .map((b) => b.copyWithTouristName(namesById[b.touristId]))
        .toList();
  }
}

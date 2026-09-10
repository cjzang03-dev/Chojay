import '../../../core/config/supabase_client.dart';
import '../domain/booking_request.dart';

class BookingsRepository {
  /// Creates a booking *request* — no payment, no final price. The operator
  /// confirms availability and exact terms (including group/room pricing)
  /// directly with the tourist once chat (build order step 6) lands.
  Future<void> createBookingRequest({
    required String itineraryId,
    required String operatorId,
    required DateTime travelStartDate,
    required int travelerCount,
    String? indicativePriceSnapshot,
    String? notes,
  }) async {
    final touristId = supabase.auth.currentUser?.id;
    if (touristId == null) {
      throw StateError('Must be signed in to request a booking.');
    }
    await supabase.from('itinerary_bookings').insert({
      'itinerary_id': itineraryId,
      'operator_id': operatorId,
      'tourist_id': touristId,
      'travel_start_date': travelStartDate.toIso8601String().split('T').first,
      'traveler_count': travelerCount,
      'indicative_price_snapshot': indicativePriceSnapshot,
      'notes': notes,
    });
  }

  /// The signed-in tourist's own booking requests, newest first, with
  /// enough of the itinerary and operator joined in for a display list.
  ///
  /// Assumes Postgres' default FK constraint naming
  /// (`itinerary_bookings_operator_id_fkey`) to disambiguate the two
  /// `profiles` relationships (operator_id and tourist_id) — verify this
  /// against the actual constraint name once the migration is applied.
  Future<List<BookingRequest>> fetchMyBookings() async {
    final touristId = supabase.auth.currentUser?.id;
    if (touristId == null) return [];

    final rows = await supabase
        .from('itinerary_bookings')
        .select(
          '*, itineraries(title, cover_photo_url), '
          'operator:profiles!itinerary_bookings_operator_id_fkey(full_name, email)',
        )
        .eq('tourist_id', touristId)
        .order('created_at', ascending: false);
    return rows.map(BookingRequest.fromJson).toList();
  }
}

import '../../../core/config/supabase_client.dart';
import '../domain/booking_request.dart';
import '../domain/booking_review.dart';

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

  /// The signed-in tourist's own reviews of their itinerary bookings,
  /// keyed by `itinerary_booking_id`, so the bookings list can show
  /// "already reviewed" state without a per-tile query.
  Future<Map<String, BookingReview>> fetchMyReviews() async {
    final touristId = supabase.auth.currentUser?.id;
    if (touristId == null) return {};

    final rows = await supabase
        .from('itinerary_booking_reviews')
        .select('itinerary_booking_id, rating, comment')
        .eq('tourist_id', touristId);
    return {
      for (final row in rows)
        row['itinerary_booking_id'] as String: BookingReview.fromJson(row),
    };
  }

  /// Leaves a review for a booking. Per product decision (matching the
  /// website's `ItineraryBookingReviewForm`), this is only meant to be
  /// called once the trip's travel start date has passed — enforced by
  /// the caller UI, not by RLS.
  Future<void> submitReview({
    required String itineraryBookingId,
    required String itineraryId,
    required String operatorId,
    required int rating,
    String? comment,
    String? itineraryTitle,
  }) async {
    final touristId = supabase.auth.currentUser?.id;
    if (touristId == null) {
      throw StateError('Must be signed in to leave a review.');
    }
    await supabase.from('itinerary_booking_reviews').insert({
      'itinerary_booking_id': itineraryBookingId,
      'itinerary_id': itineraryId,
      'operator_id': operatorId,
      'tourist_id': touristId,
      'rating': rating,
      'comment': comment,
    });

    // Best-effort: the review itself already succeeded above.
    try {
      await supabase.from('notifications').insert({
        'user_id': operatorId,
        'title': '⭐ New $rating-star review!',
        'message': comment != null && comment.isNotEmpty
            ? '"${comment.length > 80 ? '${comment.substring(0, 80)}...' : comment}"'
            : 'A traveler left you a $rating-star rating'
                '${itineraryTitle != null ? ' for "$itineraryTitle"' : ''}.',
        'type': 'success',
      });
    } catch (_) {
      // Notification failure shouldn't surface as a review-submit error.
    }
  }
}

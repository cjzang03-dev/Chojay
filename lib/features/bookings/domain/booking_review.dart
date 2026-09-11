/// A tourist's review of an itinerary booking, once submitted. Mirrors
/// `itinerary_booking_reviews` (see
/// `supabase/migrations/20260911_itinerary_booking_reviews.sql`) — a
/// separate, additive table from the website's existing `reviews` and
/// `agency_reviews`, which are keyed to the legacy `bookings` table.
class BookingReview {
  const BookingReview({
    required this.itineraryBookingId,
    required this.rating,
    this.comment,
  });

  final String itineraryBookingId;
  final int rating;
  final String? comment;

  factory BookingReview.fromJson(Map<String, dynamic> json) {
    return BookingReview(
      itineraryBookingId: json['itinerary_booking_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
    );
  }
}

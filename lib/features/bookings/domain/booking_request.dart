/// A tourist's request to book an itinerary through a chosen, approved
/// operator. Mirrors the `itinerary_bookings` table (see
/// `supabase/migrations/20260910_itinerary_bookings.sql`) — a new,
/// additive-only table for the itinerary model, separate from the
/// website's legacy `bookings` table.
///
/// This is a *request*: no payment or final price is captured here. Per
/// product decision, the platform's indicative price is shown as-is and
/// the exact price for a given group is confirmed directly between
/// operator and tourist in chat (not auto-calculated or charged).
class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.itineraryId,
    required this.operatorId,
    required this.travelStartDate,
    required this.travelerCount,
    this.indicativePriceSnapshot,
    this.notes,
    required this.status,
    required this.createdAt,
    this.itineraryTitle,
    this.itineraryCoverPhotoUrl,
    this.operatorName,
  });

  final String id;
  final String itineraryId;
  final String operatorId;
  final DateTime travelStartDate;
  final int travelerCount;
  final String? indicativePriceSnapshot;
  final String? notes;
  final String status;
  final DateTime createdAt;

  // Denormalized display fields, populated when fetched via a join
  // (fetchMyBookings); absent right after a fresh insert.
  final String? itineraryTitle;
  final String? itineraryCoverPhotoUrl;
  final String? operatorName;

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    final itinerary = json['itineraries'] as Map<String, dynamic>?;
    final operatorProfile = json['operator'] as Map<String, dynamic>?;
    return BookingRequest(
      id: json['id'] as String,
      itineraryId: json['itinerary_id'] as String,
      operatorId: json['operator_id'] as String,
      travelStartDate: DateTime.parse(json['travel_start_date'] as String),
      travelerCount: json['traveler_count'] as int? ?? 1,
      indicativePriceSnapshot: json['indicative_price_snapshot'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'requested',
      createdAt: DateTime.parse(json['created_at'] as String),
      itineraryTitle: itinerary?['title'] as String?,
      itineraryCoverPhotoUrl: itinerary?['cover_photo_url'] as String?,
      operatorName: (operatorProfile?['full_name'] as String?)?.trim().isNotEmpty == true
          ? operatorProfile!['full_name'] as String
          : operatorProfile?['email'] as String?,
    );
  }
}

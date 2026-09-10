/// A tourist's booking request directed at the signed-in operator/guide.
/// Mirrors `itinerary_bookings`, from the operator's side of the same
/// table the tourist-facing `BookingRequest` model reads.
class IncomingBooking {
  const IncomingBooking({
    required this.id,
    required this.itineraryId,
    required this.touristId,
    required this.travelStartDate,
    required this.travelerCount,
    this.indicativePriceSnapshot,
    this.notes,
    required this.status,
    required this.createdAt,
    this.itineraryTitle,
    this.touristName,
  });

  final String id;
  final String itineraryId;
  final String touristId;
  final DateTime travelStartDate;
  final int travelerCount;
  final String? indicativePriceSnapshot;
  final String? notes;
  final String status;
  final DateTime createdAt;
  final String? itineraryTitle;
  final String? touristName;

  factory IncomingBooking.fromJson(Map<String, dynamic> json) {
    final itinerary = json['itineraries'] as Map<String, dynamic>?;
    return IncomingBooking(
      id: json['id'] as String,
      itineraryId: json['itinerary_id'] as String,
      touristId: json['tourist_id'] as String,
      travelStartDate: DateTime.parse(json['travel_start_date'] as String),
      travelerCount: json['traveler_count'] as int? ?? 1,
      indicativePriceSnapshot: json['indicative_price_snapshot'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'requested',
      createdAt: DateTime.parse(json['created_at'] as String),
      itineraryTitle: itinerary?['title'] as String?,
    );
  }

  IncomingBooking copyWithTouristName(String? name) => IncomingBooking(
        id: id,
        itineraryId: itineraryId,
        touristId: touristId,
        travelStartDate: travelStartDate,
        travelerCount: travelerCount,
        indicativePriceSnapshot: indicativePriceSnapshot,
        notes: notes,
        status: status,
        createdAt: createdAt,
        itineraryTitle: itineraryTitle,
        touristName: name,
      );
}

/// One operator/guide's application to fulfill a specific itinerary.
/// Mirrors `itinerary_operators`. Only admin approval (not built in this
/// app — website step 8) moves this from 'pending' to 'approved', at
/// which point the operator appears in the tourist-facing picker list.
class ItineraryApplication {
  const ItineraryApplication({
    required this.id,
    required this.itineraryId,
    required this.status,
    this.itineraryTitle,
    this.itineraryCoverPhotoUrl,
  });

  final String id;
  final String itineraryId;
  final String status; // pending / approved / rejected
  final String? itineraryTitle;
  final String? itineraryCoverPhotoUrl;

  factory ItineraryApplication.fromJson(Map<String, dynamic> json) {
    final itinerary = json['itineraries'] as Map<String, dynamic>?;
    return ItineraryApplication(
      id: json['id'] as String,
      itineraryId: json['itinerary_id'] as String,
      status: json['status'] as String? ?? 'pending',
      itineraryTitle: itinerary?['title'] as String?,
      itineraryCoverPhotoUrl: itinerary?['cover_photo_url'] as String?,
    );
  }
}

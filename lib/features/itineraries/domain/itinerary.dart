/// A platform-curated itinerary. Field names mirror the `itineraries` table
/// from the product spec's schema sketch — the live Supabase schema wasn't
/// accessible when this was written, so verify column names/types against
/// the actual database before relying on this in a data-critical path.
class Itinerary {
  const Itinerary({
    required this.id,
    required this.title,
    this.description,
    this.durationDays,
    this.indicativePrice,
    this.includesFlight = false,
    this.coverPhotoUrl,
    required this.status,
  });

  final String id;
  final String title;
  final String? description;
  final int? durationDays;
  final String? indicativePrice;
  final bool includesFlight;
  final String? coverPhotoUrl;
  final String status;

  /// e.g. "7 Days / 6 Nights" — the common trip-length phrasing for Bhutan
  /// itineraries. Falls back to just the day count if unset.
  String get durationLabel {
    final days = durationDays;
    if (days == null || days <= 0) return '';
    if (days == 1) return '1 Day';
    return '$days Days / ${days - 1} Nights';
  }

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled itinerary',
      description: json['description'] as String?,
      durationDays: json['duration_days'] as int?,
      indicativePrice: json['indicative_price'] as String?,
      includesFlight: json['includes_flight'] as bool? ?? false,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      status: json['status'] as String? ?? 'draft',
    );
  }
}

class ItineraryDay {
  const ItineraryDay({
    required this.dayNumber,
    this.title,
    this.description,
  });

  final int dayNumber;
  final String? title;
  final String? description;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) {
    return ItineraryDay(
      dayNumber: json['day_number'] as int,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// An operator/guide approved (`itinerary_operators.status = 'approved'`)
/// to fulfill a given itinerary — the list a tourist picks from.
class ApprovedOperator {
  const ApprovedOperator({
    required this.profileId,
    this.fullName,
    this.email,
    required this.userType,
  });

  final String profileId;
  final String? fullName;
  final String? email;
  final String userType; // 'operator' or 'guide'

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email ?? 'Operator';
  }

  String get roleLabel => userType == 'guide' ? 'Licensed Guide' : 'Tour Operator';

  factory ApprovedOperator.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ApprovedOperator(
      profileId: json['operator_id'] as String,
      fullName: profile?['full_name'] as String?,
      email: profile?['email'] as String?,
      userType: profile?['user_type'] as String? ?? 'operator',
    );
  }
}

/// Everything the detail screen needs for one itinerary, fetched together.
class ItineraryDetail {
  const ItineraryDetail({
    required this.itinerary,
    required this.days,
    required this.approvedOperators,
  });

  final Itinerary itinerary;
  final List<ItineraryDay> days;
  final List<ApprovedOperator> approvedOperators;
}

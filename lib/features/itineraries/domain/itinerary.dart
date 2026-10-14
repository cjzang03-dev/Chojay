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
    this.includesHotel = false,
    this.includesMeals = false,
    this.includesTransport = false,
    this.includesGuide = false,
    this.coverPhotoUrl,
    this.category,
    required this.status,
  });

  final String id;
  final String title;
  final String? description;
  final int? durationDays;
  final String? indicativePrice;
  final bool includesFlight;
  final bool includesHotel;
  final bool includesMeals;
  final bool includesTransport;
  final bool includesGuide;
  final String? coverPhotoUrl;
  final String? category;
  final String status;

  /// e.g. "7 Days / 6 Nights" — the common trip-length phrasing for Bhutan
  /// itineraries. Falls back to just the day count if unset.
  String get durationLabel {
    final days = durationDays;
    if (days == null || days <= 0) return '';
    if (days == 1) return '1 Day';
    return '$days Days / ${days - 1} Nights';
  }

  // The website's admin form folds "Group size" / "Difficulty" into this
  // same `description` column, after this marker, rather than separate
  // columns (see app/lib/itineraryMeta.ts there) — mirrored here so this
  // app reads the same data operator_package.dart already parses the same
  // way for operator-authored packages.
  static const _metaMarker = '\n\n⚙ ';

  /// [description] with the trailing metadata line (if present) stripped,
  /// for display as the actual trip description.
  String get cleanDescription {
    final desc = description;
    if (desc == null) return '';
    final idx = desc.indexOf(_metaMarker);
    return idx == -1 ? desc : desc.substring(0, idx);
  }

  /// Parsed out of [description]'s metadata line, if present.
  String? get difficulty {
    final desc = description;
    if (desc == null) return null;
    final idx = desc.indexOf(_metaMarker);
    if (idx == -1) return null;
    final metaLine = desc.substring(idx + _metaMarker.length);
    final match = RegExp(r'Difficulty:\s*(.+)$').firstMatch(metaLine);
    return match?.group(1)?.trim();
  }

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled itinerary',
      description: json['description'] as String?,
      durationDays: json['duration_days'] as int?,
      indicativePrice: json['indicative_price'] as String?,
      includesFlight: json['includes_flight'] as bool? ?? false,
      includesHotel: json['includes_hotel'] as bool? ?? false,
      includesMeals: json['includes_meals'] as bool? ?? false,
      includesTransport: json['includes_transport'] as bool? ?? false,
      includesGuide: json['includes_guide'] as bool? ?? false,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      category: json['category'] as String?,
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

  /// [profile] comes from a separate batched `get_public_profiles_by_ids`
  /// RPC call, not a direct `profiles` embed — the website's RLS routes
  /// all cross-user profile reads through that RPC (confirmed in
  /// ChatRepository), so a direct join here would silently return null
  /// for every operator under the same policy.
  factory ApprovedOperator.fromRow(
    Map<String, dynamic> row, {
    Map<String, dynamic>? profile,
  }) {
    return ApprovedOperator(
      profileId: row['operator_id'] as String,
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

/// An operator-authored itinerary ("package") — the same `itineraries` row
/// the admin-curated catalog uses, just with `source = 'operator_proposed'`
/// and `created_by` set to the operator. Mirrors the website's
/// OperatorPackages.tsx exactly: group size/difficulty are folded into
/// `description` behind a marker line, and price is composed into one
/// human-readable string, because this phase adds no new columns.
class OperatorPackage {
  const OperatorPackage({
    required this.id,
    required this.title,
    required this.category,
    required this.shortDescription,
    required this.groupSize,
    required this.difficulty,
    required this.coverPhotoUrl,
    required this.durationDays,
    required this.priceMin,
    required this.priceMax,
    required this.priceMinIndian,
    required this.priceMaxIndian,
    required this.singleSupplement,
    required this.status,
    required this.days,
  });

  final String? id; // null until first saved
  final String title;
  final String category;
  final String shortDescription;
  final String groupSize;
  final String difficulty;
  final String coverPhotoUrl;
  final String durationDays;
  final String priceMin;
  final String priceMax;
  final String priceMinIndian;
  final String priceMaxIndian;
  final String singleSupplement;
  final String status; // draft / pending_review / published / archived
  final List<PackageDay> days;

  static const _metaMarker = '\n\n⚙ ';

  OperatorPackage copyWith({
    String? title,
    String? category,
    String? shortDescription,
    String? groupSize,
    String? difficulty,
    String? coverPhotoUrl,
    String? durationDays,
    String? priceMin,
    String? priceMax,
    String? priceMinIndian,
    String? priceMaxIndian,
    String? singleSupplement,
    List<PackageDay>? days,
  }) {
    return OperatorPackage(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      shortDescription: shortDescription ?? this.shortDescription,
      groupSize: groupSize ?? this.groupSize,
      difficulty: difficulty ?? this.difficulty,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      durationDays: durationDays ?? this.durationDays,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      priceMinIndian: priceMinIndian ?? this.priceMinIndian,
      priceMaxIndian: priceMaxIndian ?? this.priceMaxIndian,
      singleSupplement: singleSupplement ?? this.singleSupplement,
      status: status,
      days: days ?? this.days,
    );
  }

  static const blank = OperatorPackage(
    id: null,
    title: '',
    category: '',
    shortDescription: '',
    groupSize: '',
    difficulty: '',
    coverPhotoUrl: '',
    durationDays: '',
    priceMin: '',
    priceMax: '',
    priceMinIndian: '',
    priceMaxIndian: '',
    singleSupplement: '',
    status: 'draft',
    days: [],
  );

  bool get locked => id != null && status != 'draft';

  String composeDescription() {
    final base = shortDescription.trim();
    final parts = <String>[
      if (groupSize.isNotEmpty) 'Group size: $groupSize',
      if (difficulty.isNotEmpty) 'Difficulty: $difficulty',
    ];
    if (parts.isEmpty) return base;
    return '$base$_metaMarker${parts.join(' · ')}';
  }

  static String? _formatRange(String min, String max, String currencyPrefix) {
    final minDigits = min.replaceAll(RegExp(r'[^\d]'), '');
    if (minDigits.isEmpty) return null;
    final minNum = int.parse(minDigits);
    final maxDigits = max.replaceAll(RegExp(r'[^\d]'), '');
    if (maxDigits.isNotEmpty && int.parse(maxDigits) > minNum) {
      return '$currencyPrefix${_thousands(minNum)}–${_thousands(int.parse(maxDigits))}';
    }
    return '$currencyPrefix${_thousands(minNum)}';
  }

  static String _thousands(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String? composePrice() {
    final intl = _formatRange(priceMin, priceMax, '\$');
    if (intl == null) return null;
    var text = '$intl per person';
    final indian = _formatRange(priceMinIndian, priceMaxIndian, 'Nu. ');
    if (indian != null) text += ' ($indian for Indian/Regional tourists)';
    final supplementDigits = singleSupplement.replaceAll(RegExp(r'[^\d]'), '');
    if (supplementDigits.isNotEmpty) {
      text += ' + \$${_thousands(int.parse(supplementDigits))} single supplement';
    }
    return text;
  }

  factory OperatorPackage.fromRow(
    Map<String, dynamic> row, {
    List<PackageDay> days = const [],
  }) {
    final description = row['description'] as String?;
    final (shortDescription, groupSize, difficulty) =
        _parseDescription(description);
    final price = row['indicative_price'] as String?;
    final (priceMin, priceMax, priceMinIndian, priceMaxIndian, singleSupplement) =
        _parsePrice(price);
    return OperatorPackage(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      category: row['category'] as String? ?? '',
      shortDescription: shortDescription,
      groupSize: groupSize,
      difficulty: difficulty,
      coverPhotoUrl: row['cover_photo_url'] as String? ?? '',
      durationDays: (row['duration_days'] as int?)?.toString() ?? '',
      priceMin: priceMin,
      priceMax: priceMax,
      priceMinIndian: priceMinIndian,
      priceMaxIndian: priceMaxIndian,
      singleSupplement: singleSupplement,
      status: row['status'] as String? ?? 'draft',
      days: days,
    );
  }

  static (String, String, String) _parseDescription(String? full) {
    if (full == null || full.isEmpty) return ('', '', '');
    final idx = full.indexOf(_metaMarker);
    if (idx == -1) return (full, '', '');
    final shortDescription = full.substring(0, idx);
    final metaLine = full.substring(idx + _metaMarker.length);
    final groupMatch = RegExp(r'Group size:\s*([^·]+)').firstMatch(metaLine);
    final diffMatch = RegExp(r'Difficulty:\s*(.+)$').firstMatch(metaLine);
    return (
      shortDescription,
      groupMatch?.group(1)?.trim() ?? '',
      diffMatch?.group(1)?.trim() ?? '',
    );
  }

  static (String, String, String, String, String) _parsePrice(String? stored) {
    const empty = ('', '', '', '', '');
    if (stored == null || stored.isEmpty) return empty;
    final introMatch =
        RegExp(r'\$\s*([\d,]+)(?:–([\d,]+))?\s*per person').firstMatch(stored) ??
            RegExp(r'Nu\.\s*([\d,]+)(?:–([\d,]+))?\s*per person').firstMatch(stored);
    final indianMatch = RegExp(
      r'\(Nu\.\s*([\d,]+)(?:–([\d,]+))?\s*for Indian/Regional tourists\)',
    ).firstMatch(stored);
    final supplementMatch =
        RegExp(r'(?:\$|Nu\.)\s*([\d,]+)\s*single supplement').firstMatch(stored);
    String clean(String? s) => s?.replaceAll(',', '') ?? '';
    return (
      clean(introMatch?.group(1)),
      clean(introMatch?.group(2)),
      clean(indianMatch?.group(1)),
      clean(indianMatch?.group(2)),
      clean(supplementMatch?.group(1)),
    );
  }
}

class PackageDay {
  const PackageDay({this.id, required this.title, required this.description});

  /// Local-only key for Flutter's widget list/stable identity before a
  /// save; the real row has no client-visible id worth keeping once rows
  /// are deleted and reinserted on every save (see repository).
  final String? id;
  final String title;
  final String description;

  PackageDay copyWith({String? title, String? description}) => PackageDay(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
      );
}

const packageCategories = [
  ('hiking', 'Hiking & Trekking'),
  ('cultural', 'Cultural Tours'),
  ('wellness', 'Wellness & Yoga'),
  ('food', 'Food & Cooking'),
  ('nature', 'Nature & Wildlife'),
  ('homestay', 'Homestays'),
];

const packageDifficulties = ['Easy', 'Moderate', 'Challenging', 'Strenuous'];

const packageGroupSizes = [
  '1-5 people',
  '1-10 people',
  '10-15 people',
  '15-20 people',
  '20+ people',
];

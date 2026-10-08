import 'dart:typed_data';

import '../../../core/config/supabase_client.dart';
import '../domain/operator_package.dart';

/// Operator-authored itineraries ("packages") — reuses the exact same
/// `itineraries`/`itinerary_days`/`itinerary_operators` tables and
/// `source = 'operator_proposed'` convention as the website's
/// OperatorPackages.tsx, so a package authored here shows up identically
/// in the operator's website dashboard and vice versa.
class OperatorPackagesRepository {
  String get _currentUserId {
    final id = supabase.auth.currentUser?.id;
    if (id == null) throw StateError('Must be signed in.');
    return id;
  }

  Future<List<OperatorPackage>> fetchMine() async {
    final rows = await supabase
        .from('itineraries')
        .select(
          'id, title, description, duration_days, indicative_price, cover_photo_url, category, status, created_at',
        )
        .eq('created_by', _currentUserId)
        .eq('source', 'operator_proposed')
        .order('created_at', ascending: false);
    return rows.map((r) => OperatorPackage.fromRow(r)).toList();
  }

  /// Uploads a package cover photo to the public `itinerary-photos` bucket
  /// and returns its public URL. Neither the website nor this app had a
  /// real upload for `itineraries.cover_photo_url` before (both just took
  /// a pasted URL) — a path-under-my-own-id convention here keeps one
  /// operator's uploads from colliding with another's or overwriting one
  /// another, same spirit as the `avatars` bucket's per-user file name.
  Future<String> uploadCoverPhoto(Uint8List bytes, String fileExtension) async {
    final userId = _currentUserId;
    final path =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    await supabase.storage.from('itinerary-photos').uploadBinary(path, bytes);
    return supabase.storage.from('itinerary-photos').getPublicUrl(path);
  }

  Future<OperatorPackage> fetchOne(String id) async {
    final row = await supabase
        .from('itineraries')
        .select(
          'id, title, description, duration_days, indicative_price, cover_photo_url, category, status',
        )
        .eq('id', id)
        .single();
    final dayRows = await supabase
        .from('itinerary_days')
        .select('id, title, description')
        .eq('itinerary_id', id)
        .order('day_number');
    final days = dayRows
        .map((d) => PackageDay(
              id: d['id'] as String,
              title: d['title'] as String? ?? '',
              description: d['description'] as String? ?? '',
            ))
        .toList();
    return OperatorPackage.fromRow(row, days: days);
  }

  /// Saves [package], always as 'draft' status regardless of [publish] —
  /// the itinerary_days RLS policy only allows writes while the parent
  /// itinerary is 'draft' (see the website's operator_authored_itineraries
  /// migration), so this writes the itinerary as draft, replaces its days,
  /// and only then advances status to 'pending_review' if [publish]. That
  /// order avoids the admin-review flip happening before the days that
  /// would be locked out by it are safely saved.
  Future<String> save(OperatorPackage package, {required bool publish}) async {
    final userId = _currentUserId;
    final payload = {
      'title': package.title.trim(),
      'category': package.category,
      'description': package.composeDescription(),
      'duration_days': int.tryParse(package.durationDays),
      'indicative_price': package.composePrice(),
      'cover_photo_url':
          package.coverPhotoUrl.trim().isEmpty ? null : package.coverPhotoUrl.trim(),
      'status': 'draft',
    };

    String id;
    if (package.id != null) {
      id = package.id!;
      await supabase.from('itineraries').update(payload).eq('id', id);
    } else {
      final inserted = await supabase
          .from('itineraries')
          .insert({
            ...payload,
            'created_by': userId,
            'source': 'operator_proposed',
          })
          .select('id')
          .single();
      id = inserted['id'] as String;
    }

    // Every "verified operator" badge/count and the tourist-facing booking
    // picker is driven by itinerary_operators, not by created_by alone —
    // link the operator to their own package as pre-approved (no separate
    // admin approval needed: they wrote it). 23505 = already linked.
    try {
      await supabase.from('itinerary_operators').insert({
        'itinerary_id': id,
        'operator_id': userId,
        'status': 'approved',
        'approved_at': DateTime.now().toIso8601String(),
      });
    } on Object catch (e) {
      if (!'$e'.contains('23505')) rethrow;
    }

    await supabase.from('itinerary_days').delete().eq('itinerary_id', id);
    if (package.days.isNotEmpty) {
      await supabase.from('itinerary_days').insert([
        for (var i = 0; i < package.days.length; i++)
          {
            'itinerary_id': id,
            'day_number': i + 1,
            'title': package.days[i].title.trim().isEmpty
                ? null
                : package.days[i].title.trim(),
            'description': package.days[i].description.trim().isEmpty
                ? null
                : package.days[i].description.trim(),
          },
      ]);
    }

    if (publish) {
      await supabase
          .from('itineraries')
          .update({'status': 'pending_review'}).eq('id', id);
    }

    return id;
  }
}

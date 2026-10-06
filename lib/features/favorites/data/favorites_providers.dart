import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

/// The signed-in tourist's favorited itinerary IDs. A set, not a list — every
/// screen only needs fast "is this one favorited?" lookups and a toggle.
final favoriteIdsProvider =
    AsyncNotifierProvider<FavoriteIdsNotifier, Set<String>>(
  FavoriteIdsNotifier.new,
);

class FavoriteIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    return ref.watch(favoritesRepositoryProvider).fetchFavoriteIds();
  }

  /// Flips one itinerary's favorite state optimistically, reverting if the
  /// write fails — so the heart icon feels instant rather than waiting on
  /// a round trip.
  Future<void> toggle(String itineraryId) async {
    final repo = ref.read(favoritesRepositoryProvider);
    final previous = state.valueOrNull ?? <String>{};
    final isFavorite = previous.contains(itineraryId);
    final next = Set<String>.from(previous);
    isFavorite ? next.remove(itineraryId) : next.add(itineraryId);
    state = AsyncData(next);

    try {
      if (isFavorite) {
        await repo.removeFavorite(itineraryId);
      } else {
        await repo.addFavorite(itineraryId);
      }
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

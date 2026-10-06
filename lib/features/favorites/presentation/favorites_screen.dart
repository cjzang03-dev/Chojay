import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../../itineraries/data/itineraries_providers.dart';
import '../../itineraries/presentation/itinerary_card.dart';
import '../../itineraries/presentation/itinerary_detail_screen.dart';
import '../data/favorites_providers.dart';

/// The tourist's saved itineraries — reachable from the heart icon on the
/// home screen. Reuses the same published-itineraries list rather than a
/// separate query, filtered down to the favorited IDs.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(publishedItinerariesProvider);
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: itinerariesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(publishedItinerariesProvider),
        ),
        data: (all) {
          final favoriteIds = favoriteIdsAsync.valueOrNull ?? const {};
          final favorites =
              all.where((i) => favoriteIds.contains(i.id)).toList();

          if (favorites.isEmpty) {
            return const ComingSoon(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              message: 'Tap the heart on an itinerary to save it here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final itinerary = favorites[index];
              return ItineraryCard(
                itinerary: itinerary,
                isFavorite: true,
                onFavoriteToggle: () =>
                    ref.read(favoriteIdsProvider.notifier).toggle(itinerary.id),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ItineraryDetailScreen(itineraryId: itinerary.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

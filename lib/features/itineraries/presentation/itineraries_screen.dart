import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../data/itineraries_providers.dart';
import 'itinerary_card.dart';
import 'itinerary_detail_screen.dart';

/// The public itinerary catalog — the tourist's main browsing surface
/// (build order step 4). Read-only: picking an operator and booking come
/// in later steps.
class ItinerariesScreen extends ConsumerWidget {
  const ItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(publishedItinerariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Itineraries')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(publishedItinerariesProvider.future),
        child: itinerariesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(publishedItinerariesProvider),
                ),
              ),
            ],
          ),
          data: (itineraries) {
            if (itineraries.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 500,
                    child: ComingSoon(
                      icon: Icons.explore_outlined,
                      title: 'No itineraries yet',
                      message: 'Check back soon for curated Bhutan trips.',
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itineraries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final itinerary = itineraries[index];
                return ItineraryCard(
                  itinerary: itinerary,
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
      ),
    );
  }
}

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../auth/data/auth_providers.dart';
import '../../favorites/data/favorites_providers.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../data/itineraries_providers.dart';
import '../domain/itinerary.dart';
import 'itinerary_card.dart';
import 'itinerary_detail_screen.dart';

/// The tourist's home/browse screen: a greeting, search, category filters,
/// and the itinerary catalog — the main surface of the app, styled closer
/// to Klook/Grab's browse-first home tab than a bare list.
class ItinerariesScreen extends ConsumerStatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  ConsumerState<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends ConsumerState<ItinerariesScreen> {
  String _query = '';
  String? _selectedCategory;

  List<Itinerary> _filtered(List<Itinerary> all) {
    return all.where((itinerary) {
      if (_selectedCategory != null &&
          itinerary.category != _selectedCategory) {
        return false;
      }
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return itinerary.title.toLowerCase().contains(q) ||
          (itinerary.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final itinerariesAsync = ref.watch(publishedItinerariesProvider);
    final favoritesAsync = ref.watch(favoriteIdsProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final firstName = (user?.userMetadata?['full_name'] as String? ??
            user?.userMetadata?['name'] as String? ??
            '')
        .split(' ')
        .firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(publishedItinerariesProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              firstName == null || firstName.isEmpty
                                  ? 'Where to next?'
                                  : 'Hi $firstName, where to next?',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FavoritesScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.favorite_border_rounded),
                          ),
                          const NotificationBell(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Curated Bhutan itineraries, matched with licensed '
                        'local guides and operators.',
                        style: TextStyle(color: AppColors.stoneGrey),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppSearchField(
                        hintText: 'Search itineraries',
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ],
                  ),
                ),
              ),
              itinerariesAsync.when(
                loading: () => SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList.separated(
                    itemCount: 3,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, _) => const ItineraryCardSkeleton(),
                  ),
                ),
                error: (error, stackTrace) => SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: ErrorState(
                      message: '$error',
                      onRetry: () =>
                          ref.invalidate(publishedItinerariesProvider),
                    ),
                  ),
                ),
                data: (all) {
                  if (all.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 460,
                        child: ComingSoon(
                          icon: Icons.explore_outlined,
                          title: 'No itineraries yet',
                          message: 'Check back soon for curated Bhutan trips.',
                        ),
                      ),
                    );
                  }

                  final categories = all
                      .map((i) => i.category)
                      .whereType<String>()
                      .where((c) => c.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
                  final filtered = _filtered(all);
                  final favoriteIds = favoritesAsync.valueOrNull ?? const {};

                  return SliverMainAxisGroup(
                    slivers: [
                      if (categories.isNotEmpty)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm),
                              itemCount: categories.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: AppSpacing.sm),
                              itemBuilder: (context, index) {
                                final label =
                                    index == 0 ? 'All' : categories[index - 1];
                                final selected = index == 0
                                    ? _selectedCategory == null
                                    : _selectedCategory == label;
                                return ChoiceChip(
                                  label: Text(label),
                                  selected: selected,
                                  onSelected: (_) => setState(() {
                                    _selectedCategory =
                                        index == 0 ? null : label;
                                  }),
                                );
                              },
                            ),
                          ),
                        ),
                      if (filtered.isEmpty)
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 360,
                            child: ComingSoon(
                              icon: Icons.search_off_rounded,
                              title: 'No matches',
                              message: 'Try a different search or category.',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.lg),
                          sliver: SliverList.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final itinerary = filtered[index];
                              return ItineraryCard(
                                itinerary: itinerary,
                                isFavorite: favoriteIds.contains(itinerary.id),
                                onFavoriteToggle: () => ref
                                    .read(favoriteIdsProvider.notifier)
                                    .toggle(itinerary.id),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ItineraryDetailScreen(
                                        itineraryId: itinerary.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

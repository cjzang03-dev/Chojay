import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/shimmer_box.dart';
import '../../auth/data/auth_providers.dart';
import '../../notifications/presentation/notification_bell.dart';
import '../data/itineraries_providers.dart';
import '../domain/itinerary.dart';
import 'itinerary_card.dart';
import 'itinerary_detail_screen.dart';

/// Duration buckets for the Explore screen's filter panel. Kept as a plain
/// enum (rather than a free-text range) since the itinerary list is small
/// enough that coarse buckets are simpler for a tourist to reason about
/// than typing exact day counts.
enum _DurationFilter {
  any('Any length', null, null),
  short('Up to 5 days', null, 5),
  medium('6–10 days', 6, 10),
  long('11+ days', 11, null);

  const _DurationFilter(this.label, this.min, this.max);

  final String label;
  final int? min;
  final int? max;

  bool matches(int? days) {
    if (this == _DurationFilter.any) return true;
    if (days == null) return false;
    if (min != null && days < min!) return false;
    if (max != null && days > max!) return false;
    return true;
  }
}

/// The tourist's home/browse screen: a greeting, a cover photo card, search
/// + a duration filter, category chips, and the itinerary catalog.
class ItinerariesScreen extends ConsumerStatefulWidget {
  const ItinerariesScreen({super.key});

  @override
  ConsumerState<ItinerariesScreen> createState() => _ItinerariesScreenState();
}

class _ItinerariesScreenState extends ConsumerState<ItinerariesScreen> {
  String _query = '';
  String? _selectedCategory;
  _DurationFilter _durationFilter = _DurationFilter.any;

  bool get _hasActiveFilter =>
      _query.trim().isNotEmpty ||
      _selectedCategory != null ||
      _durationFilter != _DurationFilter.any;

  void _resetFilters() {
    setState(() {
      _query = '';
      _selectedCategory = null;
      _durationFilter = _DurationFilter.any;
    });
  }

  List<Itinerary> _filtered(List<Itinerary> all) {
    return all.where((itinerary) {
      if (_selectedCategory != null &&
          itinerary.category != _selectedCategory) {
        return false;
      }
      if (!_durationFilter.matches(itinerary.durationDays)) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return itinerary.title.toLowerCase().contains(q) ||
          (itinerary.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _openDurationFilter() async {
    final picked = await showModalBottomSheet<_DurationFilter>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trip length', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              for (final option in _DurationFilter.values)
                RadioListTile<_DurationFilter>(
                  value: option,
                  groupValue: _durationFilter,
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.label),
                  onChanged: (value) => Navigator.of(context).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _durationFilter = picked);
  }

  @override
  Widget build(BuildContext context) {
    final itinerariesAsync = ref.watch(publishedItinerariesProvider);
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstName == null || firstName.isEmpty
                                      ? 'Kuzuzangpo'
                                      : 'Kuzuzangpo, $firstName',
                                  style: const TextStyle(
                                    color: AppColors.stoneGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Discover Bhutan',
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                              ],
                            ),
                          ),
                          const NotificationBell(),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _HeroCard(),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppSearchField(
                              hintText: 'Search places, journeys, experiences…',
                              onChanged: (value) =>
                                  setState(() => _query = value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _FilterButton(
                            active: _durationFilter != _DurationFilter.any,
                            onTap: _openDurationFilter,
                          ),
                        ],
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
                      child: _EmptyState(
                        icon: Icons.explore_outlined,
                        title: 'No journeys yet',
                        message: 'Check back soon for curated Bhutan trips.',
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
                        SliverToBoxAdapter(
                          child: _EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No matches',
                            message: 'Try a different search, category, or trip length.',
                            onReset: _hasActiveFilter ? _resetFilters : null,
                            resetLabel: 'Show all journeys',
                          ),
                        )
                      else
                        SliverPadding(
                          // Extra bottom padding so the last card clears the
                          // bottom nav bar fully, rather than sitting flush
                          // against it.
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.xl + AppSpacing.lg),
                          sliver: SliverList.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final itinerary = filtered[index];
                              return ItineraryCard(
                                itinerary: itinerary,
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

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/tigers_nest.jpg', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: Text(
                'PARO, BHUTAN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A little closer\nto extraordinary.',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Find your journey ↗',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'Tiger\'s Nest · 3,120 m',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.himalayanGreen : AppColors.mist,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            Icons.tune_rounded,
            color: active ? Colors.white : AppColors.himalayanGreenDark,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.onReset,
    this.resetLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onReset;
  final String? resetLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.stoneGrey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
          ),
          if (onReset != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onReset, child: Text(resetLabel ?? 'Reset')),
          ],
        ],
      ),
    );
  }
}

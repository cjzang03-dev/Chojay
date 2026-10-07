import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../bookings/presentation/booking_request_screen.dart';
import '../../favorites/data/favorites_providers.dart';
import '../data/itineraries_providers.dart';
import '../domain/itinerary.dart';

/// Itinerary detail, including the approved-operators list a tourist picks
/// from to request a booking (build order step 5).
class ItineraryDetailScreen extends ConsumerWidget {
  const ItineraryDetailScreen({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(itineraryDetailProvider(itineraryId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(itineraryDetailProvider(itineraryId)),
        ),
      ),
      data: (detail) => _DetailBody(detail: detail, itineraryId: itineraryId),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.detail, required this.itineraryId});

  final ItineraryDetail detail;
  final String itineraryId;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  final _operatorsKey = GlobalKey();

  void _scrollToOperators() {
    final context = _operatorsKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final itinerary = detail.itinerary;
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favoriteIds.contains(widget.itineraryId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: () => ref
                      .read(favoriteIdsProvider.notifier)
                      .toggle(widget.itineraryId),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(url: itinerary.coverPhotoUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (itinerary.category != null &&
                      itinerary.category!.isNotEmpty) ...[
                    _CategoryPill(label: itinerary.category!),
                    const SizedBox(height: 10),
                  ],
                  Text(itinerary.title,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  _FactsRow(
                    itinerary: itinerary,
                    operatorCount: detail.approvedOperators.length,
                  ),
                  if (itinerary.description != null &&
                      itinerary.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('About this trip',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(itinerary.description!,
                        style: const TextStyle(height: 1.5)),
                  ],
                  if (detail.days.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text('Day by day',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...detail.days.map((day) => _DayTile(day: day)),
                  ],
                  SizedBox(height: 28, key: _operatorsKey),
                  Text('Choose your operator',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    detail.approvedOperators.isEmpty
                        ? 'No operators approved for this itinerary yet.'
                        : 'Tap an operator to request a booking.',
                    style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ...detail.approvedOperators.map(
                    (operator) => _OperatorTile(
                      operator: operator,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingRequestScreen(
                            itinerary: itinerary,
                            operator: operator,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: itinerary.indicativePrice == null
          ? null
          : _BottomPriceBar(
              price: itinerary.indicativePrice!,
              hasOperators: detail.approvedOperators.isNotEmpty,
              onPressed: _scrollToOperators,
            ),
    );
  }
}

class _BottomPriceBar extends StatelessWidget {
  const _BottomPriceBar({
    required this.price,
    required this.hasOperators,
    required this.onPressed,
  });

  final String price;
  final bool hasOperators;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.himalayanGreenDark,
                    ),
                  ),
                  const Text(
                    'per person · indicative',
                    style: TextStyle(fontSize: 11, color: AppColors.stoneGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 170,
              child: ElevatedButton(
                onPressed: hasOperators ? onPressed : null,
                child: Text(hasOperators ? 'Book Now' : 'Not yet bookable'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.himalayanGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.himalayanGreen,
        ),
      ),
    );
  }
}

/// A row of quick facts (duration, flights, operator count) styled like a
/// hotel-booking app's "facilities" row — adapted to what this product
/// actually has data for.
class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.itinerary, required this.operatorCount});

  final Itinerary itinerary;
  final int operatorCount;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      if (itinerary.durationLabel.isNotEmpty)
        (Icons.schedule_rounded, itinerary.durationLabel),
      if (itinerary.includesFlight) (Icons.flight_rounded, 'Flights included'),
      if (operatorCount > 0)
        (
          Icons.groups_rounded,
          '$operatorCount operator${operatorCount == 1 ? '' : 's'}',
        ),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final (icon, label) in facts) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.himalayanGreenDark),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.stoneGrey),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.himalayanGreen,
        child: const Center(
          child: Icon(Icons.landscape_rounded, size: 56, color: Colors.white),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.himalayanGreen,
        child: const Center(
          child: Icon(Icons.landscape_rounded, size: 56, color: Colors.white),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.himalayanGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.dayNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.himalayanGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.title != null && day.title!.isNotEmpty)
                  Text(day.title!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                if (day.description != null && day.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      day.description!,
                      style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  const _OperatorTile({required this.operator, required this.onTap});

  final ApprovedOperator operator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.himalayanGreen.withValues(alpha: 0.1),
          child: Icon(
            operator.userType == 'guide'
                ? Icons.hiking_rounded
                : Icons.business_center_rounded,
            color: AppColors.himalayanGreen,
          ),
        ),
        title: Text(operator.displayName),
        subtitle: Text(operator.roleLabel),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

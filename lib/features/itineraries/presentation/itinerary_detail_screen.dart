import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../data/itineraries_providers.dart';
import '../domain/itinerary.dart';

/// Read-only itinerary detail, including the approved-operators list a
/// tourist will eventually pick from to book (build order step 5). No
/// booking action here yet.
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
      data: (detail) => Scaffold(body: _DetailBody(detail: detail)),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final ItineraryDetail detail;

  @override
  Widget build(BuildContext context) {
    final itinerary = detail.itinerary;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroImage(url: itinerary.coverPhotoUrl),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(itinerary.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                if (itinerary.durationLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(itinerary.durationLabel,
                      style: TextStyle(color: AppColors.stoneGrey)),
                ],
                if (itinerary.indicativePrice != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    itinerary.indicativePrice!,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.himalayanGreenDark,
                    ),
                  ),
                  Text(
                    'Indicative price — same for every approved operator',
                    style: TextStyle(fontSize: 12, color: AppColors.stoneGrey),
                  ),
                ],
                if (itinerary.description != null &&
                    itinerary.description!.isNotEmpty) ...[
                  const SizedBox(height: 20),
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
                const SizedBox(height: 28),
                Text('Choose your operator',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  detail.approvedOperators.isEmpty
                      ? 'No operators approved for this itinerary yet.'
                      : 'These operators are approved to run this trip. '
                          'Booking is coming soon.',
                  style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
                ),
                const SizedBox(height: 12),
                ...detail.approvedOperators
                    .map((operator) => _OperatorTile(operator: operator)),
              ],
            ),
          ),
        ),
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
  const _OperatorTile({required this.operator});

  final ApprovedOperator operator;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
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
      ),
    );
  }
}

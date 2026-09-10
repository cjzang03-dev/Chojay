import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../../itineraries/data/itineraries_providers.dart';
import '../../itineraries/domain/itinerary.dart';
import '../data/partner_providers.dart';
import '../domain/itinerary_application.dart';

/// Build order step 7: where operators/guides apply to fulfill a published
/// itinerary. Applying creates a 'pending' itinerary_operators row; only
/// admin approval (website, step 8) makes them appear in the tourist-facing
/// picker list — this screen just shows each itinerary and this partner's
/// current standing on it.
class PartnerItinerariesScreen extends ConsumerWidget {
  const PartnerItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(publishedItinerariesProvider);
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Itineraries')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(publishedItinerariesProvider);
          ref.invalidate(myApplicationsProvider);
          await Future.wait([
            ref.read(publishedItinerariesProvider.future),
            ref.read(myApplicationsProvider.future),
          ]);
        },
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
                      message: 'Published itineraries you can apply to will '
                          'show up here.',
                    ),
                  ),
                ],
              );
            }
            final applications = applicationsAsync.valueOrNull ?? [];
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: itineraries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final itinerary = itineraries[index];
                final application = applications
                    .where((a) => a.itineraryId == itinerary.id)
                    .firstOrNull;
                return _ItineraryApplyCard(
                  itinerary: itinerary,
                  application: application,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ItineraryApplyCard extends ConsumerStatefulWidget {
  const _ItineraryApplyCard({required this.itinerary, this.application});

  final Itinerary itinerary;
  final ItineraryApplication? application;

  @override
  ConsumerState<_ItineraryApplyCard> createState() => _ItineraryApplyCardState();
}

class _ItineraryApplyCardState extends ConsumerState<_ItineraryApplyCard> {
  bool _applying = false;

  Future<void> _apply() async {
    setState(() => _applying = true);
    try {
      await ref
          .read(partnerRepositoryProvider)
          .applyToItinerary(widget.itinerary.id);
      ref.invalidate(myApplicationsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t apply: $e')),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(itinerary.title, style: Theme.of(context).textTheme.titleLarge),
            if (itinerary.durationLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(itinerary.durationLabel, style: TextStyle(color: AppColors.stoneGrey)),
            ],
            if (itinerary.indicativePrice != null) ...[
              const SizedBox(height: 8),
              Text(
                itinerary.indicativePrice!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.himalayanGreenDark,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: widget.application == null
                  ? OutlinedButton(
                      onPressed: _applying ? null : _apply,
                      child: _applying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Apply to fulfill this itinerary'),
                    )
                  : _StatusBanner(status: widget.application!.status),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      'approved' => (AppColors.himalayanGreen, 'Approved — visible to tourists', Icons.check_circle_outline),
      'rejected' => (AppColors.errorRed, 'Application not approved', Icons.cancel_outlined),
      _ => (AppColors.saffron, 'Application pending admin review', Icons.hourglass_top_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

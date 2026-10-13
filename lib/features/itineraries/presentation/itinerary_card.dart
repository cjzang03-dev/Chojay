import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../favorites/data/favorites_providers.dart';
import '../domain/itinerary.dart';

/// A journey card: photo, category + save button, title, duration +
/// difficulty, then a price row labeled as a sample price (never a final
/// charge) with an arrow into the details. Watches its own favorite state
/// via Riverpod rather than taking it as a prop, so every call site (the
/// Explore list, the Saved tab) stays in sync without wiring it through.
class ItineraryCard extends ConsumerWidget {
  const ItineraryCard({super.key, required this.itinerary, this.onTap});

  final Itinerary itinerary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favoriteIds.contains(itinerary.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverImage(url: itinerary.coverPhotoUrl),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (itinerary.category != null &&
                      itinerary.category!.isNotEmpty)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _Badge(label: itinerary.category!, dark: true),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: FavoriteButton(
                      isFavorite: isFavorite,
                      onPressed: () => ref
                          .read(favoriteIdsProvider.notifier)
                          .toggle(itinerary.id),
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itinerary.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (itinerary.durationLabel.isNotEmpty ||
                      itinerary.difficulty != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        if (itinerary.durationLabel.isNotEmpty)
                          _IconLabel(
                            icon: Icons.schedule_rounded,
                            label: itinerary.durationLabel,
                          ),
                        if (itinerary.difficulty != null)
                          _IconLabel(
                            icon: Icons.landscape_rounded,
                            label: itinerary.difficulty!,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (itinerary.indicativePrice != null) ...[
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.himalayanGreenDark,
                          fontSize: 16,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Sample price · from ',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: AppColors.stoneGrey,
                            ),
                          ),
                          TextSpan(text: itinerary.indicativePrice!),
                          const TextSpan(
                            text: ' / person',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: AppColors.stoneGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Government fees & flights extra',
                            style: TextStyle(fontSize: 11, color: AppColors.stoneGrey),
                          ),
                        ),
                        if (itinerary.includesFlight)
                          const _Badge(label: 'Flights included'),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.stoneGrey),
                      ],
                    ),
                  ] else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.stoneGrey),
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

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.stoneGrey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.stoneGrey)),
      ],
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.himalayanGreen.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.landscape_rounded,
              size: 40, color: AppColors.himalayanGreen),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.himalayanGreen.withValues(alpha: 0.05),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.himalayanGreen.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.landscape_rounded,
              size: 40, color: AppColors.himalayanGreen),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.dark = false});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.45)
            : AppColors.saffron.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: dark ? Colors.white : AppColors.saffron,
        ),
      ),
    );
  }
}

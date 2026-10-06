import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/favorite_button.dart';
import '../domain/itinerary.dart';

class ItineraryCard extends StatelessWidget {
  const ItineraryCard({
    super.key,
    required this.itinerary,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final Itinerary itinerary;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
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
                  if (onFavoriteToggle != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: FavoriteButton(
                        isFavorite: isFavorite,
                        onPressed: onFavoriteToggle!,
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
                  if (itinerary.durationLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 14, color: AppColors.stoneGrey),
                        const SizedBox(width: 4),
                        Text(
                          itinerary.durationLabel,
                          style: const TextStyle(color: AppColors.stoneGrey),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (itinerary.indicativePrice != null)
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.himalayanGreenDark,
                                fontSize: 17,
                              ),
                              children: [
                                TextSpan(text: itinerary.indicativePrice!),
                                const TextSpan(
                                  text: '  per person',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: AppColors.stoneGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (itinerary.includesFlight)
                        const _Badge(label: 'Flights included'),
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

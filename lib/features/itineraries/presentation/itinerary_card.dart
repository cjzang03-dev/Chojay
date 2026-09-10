import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/itinerary.dart';

class ItineraryCard extends StatelessWidget {
  const ItineraryCard({super.key, required this.itinerary, this.onTap});

  final Itinerary itinerary;
  final VoidCallback? onTap;

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
              child: _CoverImage(url: itinerary.coverPhotoUrl),
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
                    Text(
                      itinerary.durationLabel,
                      style: TextStyle(color: AppColors.stoneGrey),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (itinerary.indicativePrice != null)
                        Expanded(
                          child: Text(
                            itinerary.indicativePrice!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.himalayanGreenDark,
                              fontSize: 16,
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
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.saffron.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.saffron,
        ),
      ),
    );
  }
}

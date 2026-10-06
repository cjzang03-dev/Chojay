import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A pulsing placeholder box for loading states — used instead of a bare
/// spinner so list/card-shaped content doesn't jump once it arrives.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppRadius.sm,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.mist,
              AppColors.mist.withValues(alpha: 0.4),
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// A full itinerary-card-shaped skeleton, shown in a list while the real
/// data loads.
class ItineraryCardSkeleton extends StatelessWidget {
  const ItineraryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 10,
            child: ShimmerBox(borderRadius: 0),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 160, height: 18),
                SizedBox(height: 8),
                ShimmerBox(width: 100, height: 14),
                SizedBox(height: 12),
                ShimmerBox(width: 80, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

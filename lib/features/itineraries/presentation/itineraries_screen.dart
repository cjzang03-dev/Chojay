import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Placeholder for the curated itinerary catalog (build order step 4):
/// browsing + detail screens backed by the `itineraries` table, including
/// the "approved operators for this itinerary" list.
class ItinerariesScreen extends StatelessWidget {
  const ItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ComingSoon(
        icon: Icons.explore_outlined,
        title: 'Itineraries',
        message: 'Browse curated Bhutan itineraries here soon.',
      ),
    );
  }
}

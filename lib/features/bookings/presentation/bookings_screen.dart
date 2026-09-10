import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

/// Placeholder for the booking flow (build order step 5): pick an approved
/// operator, show the itinerary's indicative price as-is, confirm exact
/// terms in chat.
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ComingSoon(
        icon: Icons.calendar_month_outlined,
        title: 'Bookings',
        message: 'Your trip bookings will show up here.',
      ),
    );
  }
}

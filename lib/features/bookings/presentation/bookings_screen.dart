import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../data/bookings_providers.dart';
import '../domain/booking_request.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myBookingsProvider.future),
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(myBookingsProvider),
                ),
              ),
            ],
          ),
          data: (bookings) {
            if (bookings.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 500,
                    child: ComingSoon(
                      icon: Icons.calendar_month_outlined,
                      title: 'No bookings yet',
                      message: 'Browse itineraries and request to book with '
                          'an approved operator to see it here.',
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _BookingTile(booking: bookings[index]),
            );
          },
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final BookingRequest booking;

  @override
  Widget build(BuildContext context) {
    final date = booking.travelStartDate;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.itineraryTitle ?? 'Itinerary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 4),
            if (booking.operatorName != null)
              Text('with ${booking.operatorName}',
                  style: TextStyle(color: AppColors.stoneGrey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 16, color: AppColors.stoneGrey),
                const SizedBox(width: 6),
                Text(dateLabel, style: TextStyle(color: AppColors.stoneGrey)),
                const SizedBox(width: 16),
                const Icon(Icons.group_outlined,
                    size: 16, color: AppColors.stoneGrey),
                const SizedBox(width: 6),
                Text('${booking.travelerCount}',
                    style: TextStyle(color: AppColors.stoneGrey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' => (AppColors.himalayanGreen, 'Confirmed'),
      'declined' => (AppColors.errorRed, 'Declined'),
      'cancelled' => (AppColors.stoneGrey, 'Cancelled'),
      _ => (AppColors.saffron, 'Requested'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

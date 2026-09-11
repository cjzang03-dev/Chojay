import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../../chat/data/chat_providers.dart';
import '../../chat/presentation/chat_thread_screen.dart';
import '../data/partner_providers.dart';
import '../domain/incoming_booking.dart';

/// Booking requests tourists have sent this operator/guide. Read-only for
/// now — confirming/declining needs an UPDATE policy on itinerary_bookings
/// that isn't in the migration yet (deferred, see README); coordinating on
/// the actual request happens in chat, which this screen links straight to.
class PartnerBookingsScreen extends ConsumerWidget {
  const PartnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(incomingBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(incomingBookingsProvider.future),
        child: bookingsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(incomingBookingsProvider),
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
                      title: 'No booking requests yet',
                      message: 'Requests from tourists who choose you for an '
                          'itinerary will show up here.',
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _IncomingBookingTile(booking: bookings[index]),
            );
          },
        ),
      ),
    );
  }
}

class _IncomingBookingTile extends ConsumerStatefulWidget {
  const _IncomingBookingTile({required this.booking});

  final IncomingBooking booking;

  @override
  ConsumerState<_IncomingBookingTile> createState() => _IncomingBookingTileState();
}

class _IncomingBookingTileState extends ConsumerState<_IncomingBookingTile> {
  bool _openingChat = false;

  Future<void> _openChat() async {
    setState(() => _openingChat = true);
    try {
      final conversationId = await ref
          .read(chatRepositoryProvider)
          .startOrGetConversation(widget.booking.touristId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            conversationId: conversationId,
            otherUserId: widget.booking.touristId,
            otherDisplayName: widget.booking.touristName ?? 'Tourist',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t open chat: $e')),
      );
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final date = booking.travelStartDate;
    final dateLabel =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booking.itineraryTitle ?? 'Itinerary',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('from ${booking.touristName ?? 'a tourist'}',
                style: TextStyle(color: AppColors.stoneGrey)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.stoneGrey),
                const SizedBox(width: 6),
                Text(dateLabel, style: TextStyle(color: AppColors.stoneGrey)),
                const SizedBox(width: 16),
                const Icon(Icons.group_outlined, size: 16, color: AppColors.stoneGrey),
                const SizedBox(width: 6),
                Text('${booking.travelerCount}', style: TextStyle(color: AppColors.stoneGrey)),
              ],
            ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(booking.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openingChat ? null : _openChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

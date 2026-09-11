import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../../chat/data/chat_providers.dart';
import '../../chat/presentation/chat_thread_screen.dart';
import '../data/bookings_providers.dart';
import '../domain/booking_request.dart';
import '../domain/booking_review.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final reviewsAsync = ref.watch(myBookingReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(myBookingReviewsProvider);
          return ref.refresh(myBookingsProvider.future);
        },
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
            final reviews = reviewsAsync.valueOrNull ?? const {};
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _BookingTile(
                booking: bookings[index],
                review: reviews[bookings[index].id],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BookingTile extends ConsumerStatefulWidget {
  const _BookingTile({required this.booking, this.review});

  final BookingRequest booking;
  final BookingReview? review;

  @override
  ConsumerState<_BookingTile> createState() => _BookingTileState();
}

class _BookingTileState extends ConsumerState<_BookingTile> {
  bool _openingChat = false;
  bool _submittingReview = false;

  Future<void> _leaveReview() async {
    final result = await showDialog<({int rating, String? comment})>(
      context: context,
      builder: (context) => _ReviewDialog(
        operatorName: widget.booking.operatorName ?? 'the operator',
      ),
    );
    if (result == null) return;

    setState(() => _submittingReview = true);
    try {
      await ref.read(bookingsRepositoryProvider).submitReview(
            itineraryBookingId: widget.booking.id,
            itineraryId: widget.booking.itineraryId,
            operatorId: widget.booking.operatorId,
            rating: result.rating,
            comment: result.comment,
            itineraryTitle: widget.booking.itineraryTitle,
          );
      ref.invalidate(myBookingReviewsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t submit review: $e')),
      );
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  Future<void> _openChat() async {
    setState(() => _openingChat = true);
    try {
      final conversationId = await ref
          .read(chatRepositoryProvider)
          .startOrGetConversation(widget.booking.operatorId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            conversationId: conversationId,
            otherUserId: widget.booking.operatorId,
            otherDisplayName: widget.booking.operatorName ?? 'Operator',
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openingChat ? null : _openChat,
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Message'),
              ),
            ),
            if (widget.review != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < widget.review!.rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: AppColors.saffron,
                    ),
                  ),
                ],
              ),
              if (widget.review!.comment != null &&
                  widget.review!.comment!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(widget.review!.comment!,
                    style: TextStyle(color: AppColors.stoneGrey)),
              ],
            ] else if (!booking.travelStartDate.isAfter(DateTime.now())) ...[
              const Divider(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _submittingReview ? null : _leaveReview,
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: const Text('Leave a review'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.operatorName});

  final String operatorName;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.operatorName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  color: AppColors.saffron,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Share your experience (optional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.of(context).pop((
                    rating: _rating,
                    comment: _commentController.text.trim().isEmpty
                        ? null
                        : _commentController.text.trim(),
                  )),
          child: const Text('Submit'),
        ),
      ],
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

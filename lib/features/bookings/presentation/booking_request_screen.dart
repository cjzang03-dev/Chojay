import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../itineraries/domain/itinerary.dart';
import '../data/bookings_providers.dart';

/// Build order step 5: pick an operator from the approved list (already
/// done on the detail screen), show the itinerary's indicative price as-is
/// (never recalculated here), and submit a booking *request* — exact
/// terms, including group/room pricing, are confirmed with the operator
/// once chat (step 6) exists.
class BookingRequestScreen extends ConsumerStatefulWidget {
  const BookingRequestScreen({
    super.key,
    required this.itinerary,
    required this.operator,
  });

  final Itinerary itinerary;
  final ApprovedOperator operator;

  @override
  ConsumerState<BookingRequestScreen> createState() =>
      _BookingRequestScreenState();
}

class _BookingRequestScreenState extends ConsumerState<BookingRequestScreen> {
  DateTime? _travelStartDate;
  int _travelerCount = 2;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelStartDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _travelStartDate = picked);
  }

  Future<void> _submit() async {
    final travelStartDate = _travelStartDate;
    if (travelStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a travel start date first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(bookingsRepositoryProvider).createBookingRequest(
            itineraryId: widget.itinerary.id,
            operatorId: widget.operator.profileId,
            travelStartDate: travelStartDate,
            travelerCount: _travelerCount,
            indicativePriceSnapshot: widget.itinerary.indicativePrice,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request sent to ${widget.operator.displayName}. '
            'Track it in the Bookings tab.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t send request: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = widget.itinerary;
    final dateLabel = _travelStartDate == null
        ? 'Choose a date'
        : '${_travelStartDate!.year}-${_travelStartDate!.month.toString().padLeft(2, '0')}-${_travelStartDate!.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Request to book')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itinerary.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('with ${widget.operator.displayName} · ${widget.operator.roleLabel}',
                      style: TextStyle(color: AppColors.stoneGrey)),
                  if (itinerary.indicativePrice != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      itinerary.indicativePrice!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.himalayanGreenDark,
                      ),
                    ),
                    Text(
                      'Indicative price, same for every approved operator. '
                      'Exact pricing for your group (e.g. shared rooms) is '
                      'confirmed directly with the operator — this isn\'t a '
                      'final charge.',
                      style: TextStyle(fontSize: 12, color: AppColors.stoneGrey, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Travel start date', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(dateLabel),
          ),
          const SizedBox(height: 24),
          Text('Number of travelers', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: _isSubmitting || _travelerCount <= 1
                    ? null
                    : () => setState(() => _travelerCount--),
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$_travelerCount',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                onPressed: _isSubmitting || _travelerCount >= 20
                    ? null
                    : () => setState(() => _travelerCount++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Anything the operator should know? (optional)',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            enabled: !_isSubmitting,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. dietary needs, flexible dates, group size',
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Send booking request'),
          ),
        ],
      ),
    );
  }
}

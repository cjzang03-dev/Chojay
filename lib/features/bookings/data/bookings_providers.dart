import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/booking_request.dart';
import 'bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository();
});

final myBookingsProvider = FutureProvider.autoDispose<List<BookingRequest>>((ref) {
  return ref.watch(bookingsRepositoryProvider).fetchMyBookings();
});

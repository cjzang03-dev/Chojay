import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/incoming_booking.dart';
import '../domain/itinerary_application.dart';
import 'partner_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository();
});

final myApplicationsProvider =
    FutureProvider.autoDispose<List<ItineraryApplication>>((ref) {
  return ref.watch(partnerRepositoryProvider).fetchApplications();
});

final incomingBookingsProvider =
    FutureProvider.autoDispose<List<IncomingBooking>>((ref) {
  return ref.watch(partnerRepositoryProvider).fetchIncomingBookings();
});

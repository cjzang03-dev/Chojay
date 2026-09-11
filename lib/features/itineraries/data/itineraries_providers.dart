import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/itinerary.dart';
import 'itineraries_repository.dart';

final itinerariesRepositoryProvider = Provider<ItinerariesRepository>((ref) {
  return ItinerariesRepository();
});

final publishedItinerariesProvider =
    FutureProvider.autoDispose<List<Itinerary>>((ref) {
  return ref.watch(itinerariesRepositoryProvider).fetchPublished();
});

final itineraryDetailProvider = FutureProvider.autoDispose
    .family<ItineraryDetail, String>((ref, itineraryId) {
  return ref.watch(itinerariesRepositoryProvider).fetchDetail(itineraryId);
});

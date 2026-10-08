import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/operator_package.dart';
import 'operator_packages_repository.dart';

final operatorPackagesRepositoryProvider =
    Provider<OperatorPackagesRepository>((ref) {
  return OperatorPackagesRepository();
});

final myPackagesProvider = FutureProvider.autoDispose<List<OperatorPackage>>((ref) {
  return ref.watch(operatorPackagesRepositoryProvider).fetchMine();
});

final packageDetailProvider =
    FutureProvider.autoDispose.family<OperatorPackage, String>((ref, id) {
  return ref.watch(operatorPackagesRepositoryProvider).fetchOne(id);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coming_soon.dart';
import '../../../core/widgets/error_state.dart';
import '../data/operator_packages_providers.dart';
import '../domain/operator_package.dart';
import 'package_editor_screen.dart';

/// An operator's own authored itineraries ("packages") — distinct from
/// [PartnerItinerariesScreen]'s "apply to an admin-curated itinerary" flow.
/// Mirrors the website's "Itinerary Proposals" tab: draft -> submit for
/// admin review -> published, only editable while still a draft.
class MyPackagesScreen extends ConsumerWidget {
  const MyPackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(myPackagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Packages')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PackageEditorScreen()),
          );
          ref.invalidate(myPackagesProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New package'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myPackagesProvider.future),
        child: packagesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: ErrorState(
                  message: '$error',
                  onRetry: () => ref.invalidate(myPackagesProvider),
                ),
              ),
            ],
          ),
          data: (packages) {
            if (packages.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(
                    height: 500,
                    child: ComingSoon(
                      icon: Icons.card_travel_rounded,
                      title: 'No packages yet',
                      message: 'Design a day-by-day itinerary, set your '
                          'price, and submit it for review. Once approved '
                          'it goes live on the public itineraries page.',
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: packages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final package = packages[index];
                return _PackageCard(
                  package: package,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PackageEditorScreen(packageId: package.id),
                      ),
                    );
                    ref.invalidate(myPackagesProvider);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, required this.onTap});

  final OperatorPackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (package.status) {
      'published' => ('Published', AppColors.himalayanGreen),
      'pending_review' => ('Pending review', AppColors.saffron),
      'archived' => ('Archived', AppColors.stoneGrey),
      _ => ('Draft', AppColors.stoneGrey),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      package.title.isEmpty ? 'Untitled package' : package.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (package.shortDescription.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  package.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                package.composePrice() ?? 'Price not set',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.himalayanGreenDark,
                ),
              ),
              if (package.status == 'pending_review') ...[
                const SizedBox(height: 8),
                Text(
                  'Awaiting admin review — you\'ll be notified once it\'s '
                  'approved.',
                  style: TextStyle(fontSize: 12, color: AppColors.stoneGrey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

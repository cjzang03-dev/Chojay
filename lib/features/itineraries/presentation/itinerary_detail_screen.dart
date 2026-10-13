import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../bookings/presentation/booking_request_screen.dart';
import '../../favorites/data/favorites_providers.dart';
import '../data/itineraries_providers.dart';
import '../domain/itinerary.dart';

enum _DetailTab { overview, dayByDay, included, bookingTerms }

/// Itinerary detail: Overview / Day-by-day / Included / Booking terms, then
/// the approved-operators list a tourist picks from to request a quote.
///
/// Tab switching here is plain conditional rendering on a local enum
/// (rather than Flutter's TabBarView, which needs a bounded height) so the
/// whole page — hero, facts, tabs, and the operator list below them — stays
/// one single scrollable column, same approach the website's equivalent
/// panel uses.
class ItineraryDetailScreen extends ConsumerWidget {
  const ItineraryDetailScreen({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(itineraryDetailProvider(itineraryId));

    return detailAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: '$error',
          onRetry: () => ref.invalidate(itineraryDetailProvider(itineraryId)),
        ),
      ),
      data: (detail) => _DetailBody(detail: detail, itineraryId: itineraryId),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.detail, required this.itineraryId});

  final ItineraryDetail detail;
  final String itineraryId;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  final _operatorsKey = GlobalKey();
  _DetailTab _activeTab = _DetailTab.overview;

  void _scrollToOperators() {
    final context = _operatorsKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final itinerary = detail.itinerary;
    final favoriteIds = ref.watch(favoriteIdsProvider).valueOrNull ?? const {};
    final isFavorite = favoriteIds.contains(widget.itineraryId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FavoriteButton(
                  isFavorite: isFavorite,
                  onPressed: () => ref
                      .read(favoriteIdsProvider.notifier)
                      .toggle(widget.itineraryId),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroImage(url: itinerary.coverPhotoUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (itinerary.category != null &&
                      itinerary.category!.isNotEmpty) ...[
                    _CategoryPill(label: itinerary.category!),
                    const SizedBox(height: 10),
                  ],
                  Text(itinerary.title,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 14),
                  _FactsRow(
                    itinerary: itinerary,
                    operatorCount: detail.approvedOperators.length,
                  ),
                  if (itinerary.indicativePrice != null &&
                      itinerary.indicativePrice!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _PriceSection(price: itinerary.indicativePrice!),
                  ],
                  const SizedBox(height: 24),
                  _TabRow(
                    active: _activeTab,
                    onChanged: (tab) => setState(() => _activeTab = tab),
                  ),
                  const SizedBox(height: 16),
                  switch (_activeTab) {
                    _DetailTab.overview => _OverviewTab(itinerary: itinerary),
                    _DetailTab.dayByDay => _DayByDayTab(days: detail.days),
                    _DetailTab.included => _IncludedTab(itinerary: itinerary),
                    _DetailTab.bookingTerms => const _BookingTermsTab(),
                  },
                  SizedBox(height: 28, key: _operatorsKey),
                  Text('Choose your operator',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    detail.approvedOperators.isEmpty
                        ? 'No operators approved for this itinerary yet.'
                        : 'Tap an operator to request a quote.',
                    style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  ...detail.approvedOperators.map(
                    (operator) => _OperatorTile(
                      operator: operator,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingRequestScreen(
                            itinerary: itinerary,
                            operator: operator,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: itinerary.indicativePrice == null
          ? null
          : _BottomPriceBar(
              price: itinerary.indicativePrice!,
              hasOperators: detail.approvedOperators.isNotEmpty,
              onPressed: _scrollToOperators,
            ),
    );
  }
}

class _PriceSection extends StatelessWidget {
  const _PriceSection({required this.price});

  final String price;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sample price', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'from $price',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.himalayanGreenDark,
            height: 1.4,
          ),
        ),
        const Text(
          'Government fees & flights extra',
          style: TextStyle(fontSize: 12, color: AppColors.stoneGrey),
        ),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: const Text(
              'Price details',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            children: const [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This is a sample price to help you compare trips, not a '
                  'final charge. Government fees (the Sustainable '
                  'Development Fee) vary by nationality and age, and '
                  'flights aren\'t included. Request a quote and your '
                  'operator will send an itemized price for your exact '
                  'dates and group.',
                  style: TextStyle(fontSize: 12, color: AppColors.stoneGrey, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabRow extends StatelessWidget {
  const _TabRow({required this.active, required this.onChanged});

  final _DetailTab active;
  final ValueChanged<_DetailTab> onChanged;

  static const _labels = {
    _DetailTab.overview: 'Overview',
    _DetailTab.dayByDay: 'Day-by-day',
    _DetailTab.included: 'Included',
    _DetailTab.bookingTerms: 'Booking terms',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _DetailTab.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tab = _DetailTab.values[index];
          final selected = tab == active;
          return ChoiceChip(
            label: Text(_labels[tab]!),
            selected: selected,
            onSelected: (_) => onChanged(tab),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    final description = itinerary.cleanDescription;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description.isNotEmpty) ...[
          Text(description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_outlined, size: 18, color: AppColors.himalayanGreen),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Planned with local expertise — every operator below is a '
                  'licensed Bhutanese operator or guide, verified before you '
                  'commit to anything.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.himalayanGreenDark, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayByDayTab extends StatelessWidget {
  const _DayByDayTab({required this.days});

  final List<ItineraryDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Text(
        'A day-by-day plan hasn\'t been added for this journey yet.',
        style: TextStyle(color: AppColors.stoneGrey),
      );
    }
    return Column(
      children: [for (final day in days) _DayTile(day: day)],
    );
  }
}

class _IncludedTab extends StatelessWidget {
  const _IncludedTab({required this.itinerary});

  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    final tracked = <String, bool>{
      'Hotel / accommodation': itinerary.includesHotel,
      'Meals': itinerary.includesMeals,
      'Private transport': itinerary.includesTransport,
      'Licensed guide': itinerary.includesGuide,
      'International flights': itinerary.includesFlight,
    };
    final included = [
      for (final entry in tracked.entries)
        if (entry.value) entry.key,
    ];
    final notIncluded = [
      for (final entry in tracked.entries)
        if (!entry.value) entry.key,
      'Bhutan government fees (Sustainable Development Fee)',
      'Visa',
      'Travel insurance',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What this operator includes in the price shown:',
          style: TextStyle(color: AppColors.stoneGrey, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        if (included.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'This operator hasn\'t specified any inclusions yet — confirm with them directly.',
              style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
            ),
          )
        else
          for (final item in included)
            _ChecklistRow(label: item, icon: Icons.check_circle_rounded, color: AppColors.success),
        const SizedBox(height: 18),
        const Text(
          'Not included:',
          style: TextStyle(color: AppColors.stoneGrey, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        for (final item in notIncluded)
          _ChecklistRow(label: item, icon: Icons.cancel_rounded, color: AppColors.stoneGreyLight),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(height: 1.3))),
        ],
      ),
    );
  }
}

class _BookingTermsTab extends StatelessWidget {
  const _BookingTermsTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'A quote is not a booking.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8),
        Text(
          'Requesting a quote starts a conversation with the operator — it '
          'doesn\'t charge you or confirm anything. Before you pay a '
          'deposit or final payment, review directly with the operator:',
          style: TextStyle(height: 1.5, color: AppColors.stoneGrey),
        ),
        SizedBox(height: 10),
        _TermBullet('Exact travel dates'),
        _TermBullet('Total price for your group'),
        _TermBullet('Deposit amount and when it\'s due'),
        _TermBullet('Cancellation policy'),
        _TermBullet('Refund terms'),
      ],
    );
  }
}

class _TermBullet extends StatelessWidget {
  const _TermBullet(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.stoneGrey)),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.stoneGrey, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _BottomPriceBar extends StatelessWidget {
  const _BottomPriceBar({
    required this.price,
    required this.hasOperators,
    required this.onPressed,
  });

  final String price;
  final bool hasOperators;
  final VoidCallback onPressed;

  /// Some itineraries' price text is a full sentence with a parenthetical
  /// regional-pricing note (e.g. "$300 – 700 per person (Nu. 2,000 – 5,000
  /// for Indian/Regional tourists)") — fine in the scrollable body (added
  /// above, under "Sample price"), but left unbounded here it wrapped
  /// across many lines and inflated this sticky bar to take up most of the
  /// screen, squeezing the entire page above it into a sliver and making
  /// the CTA look broken (nothing visible to scroll to). Keep this bar's
  /// own copy short and single-line; the full text always has room up in
  /// the body.
  String get _shortPrice {
    final parenIndex = price.indexOf('(');
    final head = parenIndex == -1 ? price : price.substring(0, parenIndex);
    return head.trim().isEmpty ? price : head.trim();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sample price · from $_shortPrice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.himalayanGreenDark,
                    ),
                  ),
                  const Text(
                    'per person · fees & flights extra',
                    style: TextStyle(fontSize: 11, color: AppColors.stoneGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 170,
              child: ElevatedButton(
                onPressed: hasOperators ? onPressed : null,
                child: Text(hasOperators ? 'Request a quote' : 'Not yet bookable'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.himalayanGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.himalayanGreen,
        ),
      ),
    );
  }
}

/// A row of quick facts (duration, difficulty, flights, operator count)
/// styled like a hotel-booking app's "facilities" row — adapted to what
/// this product actually has data for.
class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.itinerary, required this.operatorCount});

  final Itinerary itinerary;
  final int operatorCount;

  @override
  Widget build(BuildContext context) {
    final facts = <(IconData, String)>[
      if (itinerary.durationLabel.isNotEmpty)
        (Icons.schedule_rounded, itinerary.durationLabel),
      if (itinerary.difficulty != null)
        (Icons.landscape_rounded, itinerary.difficulty!),
      (Icons.verified_user_outlined, 'Private journey'),
      if (itinerary.includesFlight) (Icons.flight_rounded, 'Flights included'),
      if (operatorCount > 0)
        (
          Icons.groups_rounded,
          '$operatorCount operator${operatorCount == 1 ? '' : 's'}',
        ),
    ];
    if (facts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final (icon, label) in facts) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.himalayanGreenDark),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.stoneGrey),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        color: AppColors.himalayanGreen,
        child: const Center(
          child: Icon(Icons.landscape_rounded, size: 56, color: Colors.white),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.himalayanGreen,
        child: const Center(
          child: Icon(Icons.landscape_rounded, size: 56, color: Colors.white),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.himalayanGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.dayNumber}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.himalayanGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.title != null && day.title!.isNotEmpty)
                  Text(day.title!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                if (day.description != null && day.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      day.description!,
                      style: TextStyle(color: AppColors.stoneGrey, height: 1.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorTile extends StatelessWidget {
  const _OperatorTile({required this.operator, required this.onTap});

  final ApprovedOperator operator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.himalayanGreen.withValues(alpha: 0.1),
          child: Icon(
            operator.userType == 'guide'
                ? Icons.hiking_rounded
                : Icons.business_center_rounded,
            color: AppColors.himalayanGreen,
          ),
        ),
        title: Text(operator.displayName),
        subtitle: Text(operator.roleLabel),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

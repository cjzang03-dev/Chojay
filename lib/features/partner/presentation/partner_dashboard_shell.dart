import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'my_packages_screen.dart';
import 'partner_bookings_screen.dart';
import 'partner_itineraries_screen.dart';

/// The signed-in guide/operator's shell — routed here instead of the
/// tourist [HomeShell] based on `profiles.user_type`. Chat and Profile are
/// reused as-is: messaging and account info aren't role-specific. Operators
/// (not guides) additionally get a "My Packages" tab to author their own
/// itineraries, matching the website's operator-only "Itinerary Proposals"
/// tab.
class PartnerDashboardShell extends ConsumerStatefulWidget {
  const PartnerDashboardShell({super.key});

  @override
  ConsumerState<PartnerDashboardShell> createState() =>
      _PartnerDashboardShellState();
}

class _PartnerDashboardShellState extends ConsumerState<PartnerDashboardShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isOperator =
        ref.watch(currentProfileProvider).valueOrNull?.userType == 'operator';

    final tabs = [
      const PartnerItinerariesScreen(),
      if (isOperator) const MyPackagesScreen(),
      const PartnerBookingsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Itineraries',
      ),
      if (isOperator)
        const NavigationDestination(
          icon: Icon(Icons.card_travel_outlined),
          selectedIcon: Icon(Icons.card_travel),
          label: 'My Packages',
        ),
      const NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: 'Bookings',
      ),
      const NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: 'Chat',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    final index = _index >= tabs.length ? 0 : _index;

    return Scaffold(
      body: IndexedStack(index: index, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}

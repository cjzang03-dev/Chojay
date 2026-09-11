import 'package:flutter/material.dart';

import '../../chat/presentation/chat_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'partner_bookings_screen.dart';
import 'partner_itineraries_screen.dart';

/// The signed-in guide/operator's shell — routed here instead of the
/// tourist [HomeShell] based on `profiles.user_type`. Chat and Profile are
/// reused as-is: messaging and account info aren't role-specific.
class PartnerDashboardShell extends StatefulWidget {
  const PartnerDashboardShell({super.key});

  @override
  State<PartnerDashboardShell> createState() => _PartnerDashboardShellState();
}

class _PartnerDashboardShellState extends State<PartnerDashboardShell> {
  int _index = 0;

  static const _tabs = [
    PartnerItinerariesScreen(),
    PartnerBookingsScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Itineraries',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

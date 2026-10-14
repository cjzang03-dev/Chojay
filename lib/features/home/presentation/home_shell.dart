import 'package:flutter/material.dart';

import '../../bookings/presentation/bookings_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../itineraries/presentation/itineraries_screen.dart';
import '../../profile/presentation/profile_screen.dart';

/// The signed-in tourist's main shell: Explore, Saved, My trips, Chat,
/// Profile. Chat was dropped as its own tab in an earlier pass (the
/// assumption being every conversation here starts from a booking) but
/// that made it undiscoverable as a standalone inbox — restored as a tab
/// per explicit feedback.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    ItinerariesScreen(),
    FavoritesScreen(),
    BookingsScreen(),
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
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'My trips',
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

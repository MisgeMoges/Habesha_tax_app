import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),

        NavigationDestination(
          icon: Icon(Icons.volunteer_activism_outlined),
          selectedIcon: Icon(Icons.volunteer_activism),
          label: 'Donate',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.church_outlined),
          selectedIcon: Icon(Icons.church),
          label: 'About',
        ),
        NavigationDestination(
          icon: Icon(Icons.contact_support_outlined),
          selectedIcon: Icon(Icons.contact_support),
          label: 'Contact',
        ),
      ],
    );
  }
}

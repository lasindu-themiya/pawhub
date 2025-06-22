import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'GPS'),
        BottomNavigationBarItem(
          icon: Icon(Icons.thermostat),
          label: 'Temperature',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services),
          label: 'Vaccination',
        ),
      ],
    );
  }
}

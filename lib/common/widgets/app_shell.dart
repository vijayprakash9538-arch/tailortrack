import 'package:flutter/material.dart';

/// Bottom-nav scaffold shared by the four main tabs. [navigationShell] is
/// provided by GoRouter's StatefulShellRoute so each tab keeps its own
/// navigation stack and scroll position when switching.
class AppShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppShell({super.key, required this.child, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Insights'),
        ],
      ),
    );
  }
}

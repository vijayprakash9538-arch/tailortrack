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
    // Lift the bar above the phone's gesture / home-indicator strip. Use the
    // real safe-area inset when reported, but keep a minimum so the tabs never
    // sit flush against the bottom edge (where they'd overlap the system bar).
    final systemInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomInset = systemInset > 0 ? systemInset : 10.0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? Colors.transparent)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_rounded), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Customers'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Insights'),
          ],
        ),
      ),
    );
  }
}

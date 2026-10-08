import 'package:flutter/material.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import '../dashboard/home_dashboard_screen.dart';
import '../orders/order_history_screen.dart';
import '../rewards/rewards_loyalty_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static const int ordersTab = 1;

  /// Switch the bottom-nav tab from anywhere below this screen
  static void selectTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainNavigationScreenState>()?._select(
      index,
    );
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _select(int index) => setState(() => _currentIndex = index);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      HomeDashboardScreen(),
      OrderHistoryScreen(),
      RewardsLoyaltyScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _select,
        items: [
          BottomNavItem(icon: Icons.home, label: 'Home'),
          BottomNavItem(icon: Icons.assignment, label: 'Orders'),
          BottomNavItem(icon: Icons.card_giftcard, label: 'Rewards'),
          BottomNavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }
}

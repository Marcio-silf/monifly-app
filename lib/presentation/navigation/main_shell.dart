import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bottom_nav_bar.dart';
import 'package:monifly/presentation/screens/home/home_screen.dart';
import 'package:monifly/presentation/screens/transactions/transactions_screen.dart';
import 'package:monifly/presentation/screens/goals/goals_screen.dart';
import 'package:monifly/presentation/screens/reports/reports_screen.dart';
import 'package:monifly/presentation/screens/profile/profile_screen.dart';
import 'package:monifly/data/providers/navigation_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:monifly/data/providers/transaction_provider.dart';
import 'package:monifly/data/providers/goal_provider.dart';
import 'package:monifly/data/providers/budget_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        // Automatically refresh data when back online
        ref.read(transactionsProvider.notifier).refresh();
        ref.read(goalsProvider.notifier).refresh();
        
        final now = DateTime.now();
        final month = now.year * 100 + now.month;
        ref.read(budgetsProvider.notifier).refresh(month);
      }
    });
  }

  static const List<Widget> _screens = [
    const HomeScreen(),
    const TransactionsScreen(),
    const GoalsScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) =>
            ref.read(navigationIndexProvider.notifier).state = index,
      ),
    );
  }
}

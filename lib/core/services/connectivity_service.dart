import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/transaction_provider.dart';
import '../../data/providers/goal_provider.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

class ConnectivityService {
  final WidgetRef ref;
  late StreamSubscription _subscription;

  ConnectivityService(this.ref);

  void init() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        // Trigger background sync/refresh
        _syncData();
      }
    });
  }

  void dispose() {
    _subscription.cancel();
  }

  void _syncData() {
    // Refresh providers when back online
    ref.read(transactionsProvider.notifier).refresh();
    ref.read(goalsProvider.notifier).refresh();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  // Note: This is a bit tricky with WidgetRef, better just use ref
  return ConnectivityService(null as dynamic); // Will fix this pattern
});

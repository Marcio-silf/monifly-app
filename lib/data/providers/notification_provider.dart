import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_provider.dart';
import 'goal_provider.dart';

class NotificationItem {
  final String id;
  final IconData icon;
  final String title;
  final String message;
  final String time;
  final bool isNew;

  NotificationItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
    this.isNew = true,
  });

  NotificationItem copyWith({bool? isNew}) {
    return NotificationItem(
      id: id,
      icon: icon,
      title: title,
      message: message,
      time: time,
      isNew: isNew ?? this.isNew,
    );
  }
}

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super(_initialNotifications);

  static final List<NotificationItem> _initialNotifications = [
    NotificationItem(
      id: 'welcome',
      icon: Icons.notifications_active_rounded,
      title: 'Bem-vindo ao Monifly!',
      message: 'Comece adicionando sua primeira transação para gerenciar suas finanças.',
      time: 'Agora',
    ),
  ];

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isNew: false) else n
    ];
  }

  void markAllAsRead() {
    state = [for (final n in state) n.copyWith(isNew: false)];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
  return NotificationNotifier();
});

final displayableNotificationsProvider =
    Provider<List<NotificationItem>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final goals = ref.watch(goalsProvider).valueOrNull ?? [];
  final pendingBills = ref.watch(pendingBillsProvider);
  
  final now = DateTime.now();
  final List<NotificationItem> dynamicNotifications = [];

  // 1. Notificações de contas não pagas (1 dia antes da data)
  for (final bill in pendingBills) {
    if (bill.dueDate != null) {
      final diff = bill.dueDate!.difference(now).inDays;
      // Verificamos se falta exatamente 1 dia (podendo ser entre 24h e 48h dependendo da hora, 
      // mas inDays costuma aproximar bem se compararmos datas puras)
      final sameDayPlusOne = DateTime(now.year, now.month, now.day + 1);
      final billDay = DateTime(bill.dueDate!.year, bill.dueDate!.month, bill.dueDate!.day);
      
      if (billDay.isAtSameMomentAs(sameDayPlusOne)) {
        dynamicNotifications.add(
          NotificationItem(
            id: 'bill_due_${bill.id}',
            icon: Icons.priority_high_rounded,
            title: 'Conta vence amanhã!',
            message: 'Sua conta "${bill.description}" vence amanhã. Não esqueça de pagar!',
            time: '1 dia restante',
          ),
        );
      }
    }
  }

  // 2. Notificações de metas sem atualização há mais de 15 dias
  for (final goal in goals) {
    if (goal.isActive) {
      final daysSinceUpdate = now.difference(goal.updatedAt).inDays;
      if (daysSinceUpdate >= 15) {
        dynamicNotifications.add(
          NotificationItem(
            id: 'goal_stale_${goal.id}',
            icon: Icons.trending_up_rounded,
            title: 'Sua meta precisa de atenção!',
            message: 'Você não atualiza sua meta "${goal.name}" há mais de 15 dias. Vamos poupar um pouco?',
            time: '$daysSinceUpdate dias',
          ),
        );
      }
    }
  }

  final allNotifications = [...dynamicNotifications, ...notifications];

  if (transactions.isNotEmpty) {
    // Filter out welcome notification if there are transactions
    return allNotifications.where((n) => n.id != 'welcome').toList();
  }

  return allNotifications;
});



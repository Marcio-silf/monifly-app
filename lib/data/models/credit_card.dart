import 'package:uuid/uuid.dart';

class CreditCard {
  final String id;
  final String userId;
  final String name;
  final double limit;
  final int closingDay;
  final int dueDay;
  final double currentBalance;
  final String? lastFourDigits;
  final String color;
  final DateTime createdAt;

  const CreditCard({
    required this.id,
    required this.userId,
    required this.name,
    required this.limit,
    required this.closingDay,
    required this.dueDay,
    this.currentBalance = 0.0,
    this.lastFourDigits,
    this.color = '#06B6D4',
    required this.createdAt,
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      limit: (json['limit'] as num).toDouble(),
      closingDay: json['closing_day'] as int,
      dueDay: json['due_day'] as int,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      lastFourDigits: json['last_four_digits'] as String?,
      color: json['color'] as String? ?? '#06B6D4',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'limit': limit,
    'closing_day': closingDay,
    'due_day': dueDay,
    'current_balance': currentBalance,
    'last_four_digits': lastFourDigits,
    'color': color,
    'created_at': createdAt.toIso8601String(),
  };

  static CreditCard empty(String userId) {
    return CreditCard(
      id: const Uuid().v4(),
      userId: userId,
      name: '',
      limit: 0,
      closingDay: 1,
      dueDay: 10,
      createdAt: DateTime.now(),
    );
  }

  double get availableLimit => (limit - currentBalance).clamp(0, limit);
  double get usedPercent =>
      limit > 0 ? (currentBalance / limit * 100).clamp(0, 100) : 0;
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // reminder, goal, budget, income, tip
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'reminder',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  AppNotification markAsRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    isRead: true,
    createdAt: createdAt,
  );
}


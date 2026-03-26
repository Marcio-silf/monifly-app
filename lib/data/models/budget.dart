import 'package:uuid/uuid.dart';

class Budget {
  final String id;
  final String userId;
  final String category;
  final int month; // YYYYMM
  final double limitAmount;
  final double spentAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.month,
    required this.limitAmount,
    this.spentAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      category: json['category'] as String,
      month: json['month'] as int,
      limitAmount: (json['amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'category': category,
        'month': month,
        'amount': limitAmount,
        if (id.isNotEmpty) 'id': id,
      };

  Budget copyWith({double? limitAmount, double? spentAmount}) {
    return Budget(
      id: id,
      userId: userId,
      category: category,
      month: month,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static Budget empty(String userId, String category, int month) {
    final now = DateTime.now();
    return Budget(
      id: const Uuid().v4(),
      userId: userId,
      category: category,
      month: month,
      limitAmount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  double get percentUsed =>
      limitAmount > 0 ? (spentAmount / limitAmount * 100).clamp(0, 200) : 0;
  double get remaining =>
      (limitAmount - spentAmount).clamp(-double.infinity, double.infinity);
  bool get isOverBudget => spentAmount > limitAmount;
  bool get isWarning => percentUsed >= 80 && !isOverBudget;
}

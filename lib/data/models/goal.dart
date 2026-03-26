import 'package:uuid/uuid.dart';

class Goal {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String category;
  final String? iconName;
  final String color;
  final String status; // active, completed, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.category = 'outros',
    this.iconName,
    this.color = '#06B6D4',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      category: json['category'] as String? ?? 'outros',
      iconName: json['icon_name'] as String?,
      color: json['color'] as String? ?? '#06B6D4',
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'description': description,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'target_date': targetDate?.toIso8601String(),
    'category': category,
    'icon_name': iconName,
    'color': color,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Goal copyWith({
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? iconName,
    String? color,
    String? status,
  }) {
    return Goal(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static Goal empty(String userId) {
    final now = DateTime.now();
    return Goal(
      id: const Uuid().v4(),
      userId: userId,
      name: '',
      targetAmount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  double get progressPercent =>
      targetAmount > 0 ? (currentAmount / targetAmount * 100).clamp(0, 100) : 0;

  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  bool get isCompleted =>
      status == 'completed' || currentAmount >= targetAmount;
  bool get isActive => status == 'active';

  int get daysRemaining {
    if (targetDate == null) return -1;
    final diff = targetDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  double get monthlyContributionNeeded {
    if (targetDate == null || remaining <= 0) return 0;
    final months =
        (targetDate!.year - DateTime.now().year) * 12 +
        (targetDate!.month - DateTime.now().month);
    if (months <= 0) return remaining;
    return remaining / months;
  }
}


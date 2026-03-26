import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String userId;
  final String type; // income, expense, investment_in, investment_out
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String paymentStatus; // paid, pending, scheduled
  final String? paymentMethod;
  final DateTime? dueDate;
  final String? notes;
  final bool isRecurring;
  final String? recurringFrequency;
  final String? attachmentUrl;
  final String? goalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.paymentStatus = 'paid',
    this.paymentMethod,
    this.dueDate,
    this.notes,
    this.isRecurring = false,
    this.recurringFrequency,
    this.attachmentUrl,
    this.goalId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String? ?? 'outros',
      paymentStatus: json['payment_status'] as String? ?? 'paid',
      paymentMethod: json['payment_method'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      notes: json['notes'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringFrequency: json['recurring_frequency'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      goalId: json['goal_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'description': description,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'payment_status': paymentStatus,
    'payment_method': paymentMethod,
    'due_date': dueDate?.toIso8601String(),
    'notes': notes,
    'is_recurring': isRecurring,
    'recurring_frequency': recurringFrequency,
    'attachment_url': attachmentUrl,
    'goal_id': goalId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Transaction copyWith({
    String? type,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? dueDate,
    String? notes,
    bool? isRecurring,
    String? recurringFrequency,
    String? attachmentUrl,
    String? goalId,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      dueDate: dueDate ?? this.dueDate,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      goalId: goalId ?? this.goalId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static Transaction empty(String userId) {
    final now = DateTime.now();
    return Transaction(
      id: const Uuid().v4(),
      userId: userId,
      type: 'expense',
      description: '',
      amount: 0,
      date: now,
      category: 'outros',
      createdAt: now,
      updatedAt: now,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isInvestmentIn => type == 'investment_in';
  bool get isInvestmentOut => type == 'investment_out';
  bool get isPaid => paymentStatus == 'paid';
  bool get isPending => paymentStatus == 'pending';
  bool get isScheduled => paymentStatus == 'scheduled';

  double get signedAmount {
    if (isIncome || isInvestmentOut) return amount;
    return -amount;
  }
}


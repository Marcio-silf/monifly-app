import 'package:uuid/uuid.dart';

class SpendingPlan {
  final String id;
  final String userId;
  final int month; // format YYYYMM
  final double plannedIncome;
  final List<PlanDetail> details;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpendingPlan({
    required this.id,
    required this.userId,
    required this.month,
    required this.plannedIncome,
    this.details = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpendingPlan.fromJson(Map<String, dynamic> json, [List<PlanDetail> details = const []]) {
    return SpendingPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      month: json['month'] as int,
      plannedIncome: (json['planned_income'] as num).toDouble(),
      details: details,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id': userId,
      'month': month,
      'planned_income': plannedIncome,
      'updated_at': updatedAt.toIso8601String(),
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  SpendingPlan copyWith({
    double? plannedIncome,
    List<PlanDetail>? details,
    int? month,
  }) {
    return SpendingPlan(
      id: id,
      userId: userId,
      month: month ?? this.month,
      plannedIncome: plannedIncome ?? this.plannedIncome,
      details: details ?? this.details,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static SpendingPlan empty(String userId, int month) {
    final now = DateTime.now();
    return SpendingPlan(
      id: const Uuid().v4(),
      userId: userId,
      month: month,
      plannedIncome: 0,
      details: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  double get totalPlanned => details.fold(0, (sum, item) => sum + item.plannedAmount);
  double get remainingIncome => plannedIncome - totalPlanned;
  double get distributionPercentage => plannedIncome > 0 ? (totalPlanned / plannedIncome) : 0;
}

class PlanDetail {
  final String id;
  final String planId;
  final String category;
  final double plannedAmount;

  PlanDetail({
    required this.id,
    required this.planId,
    required this.category,
    required this.plannedAmount,
  });

  factory PlanDetail.fromJson(Map<String, dynamic> json) {
    return PlanDetail(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      category: json['category'] as String,
      plannedAmount: (json['planned_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'category': category,
      'planned_amount': plannedAmount,
    };
    if (id.isNotEmpty) map['id'] = id;
    if (planId.isNotEmpty) map['plan_id'] = planId;
    return map;
  }
}

class CategoryAnalysis {
  final String category;
  final double planned;
  final double actual;

  CategoryAnalysis({
    required this.category,
    required this.planned,
    required this.actual,
  });

  double get difference => actual - planned;
  double get percentageDiff => planned > 0 ? (difference / planned) : (actual > 0 ? 1.0 : 0.0);
  
  bool get isWithinBudget => (difference / planned).abs() <= 0.05 || (planned == 0 && actual == 0); 
  bool get isOverBudget => difference > 0 && (planned == 0 || (difference / planned) > 0.05);
  bool get isUnderBudget => difference < 0 && planned > 0 && (difference / planned).abs() > 0.05;

  String get status {
    if (isOverBudget) return 'above';
    if (isUnderBudget) return 'below';
    return 'within';
  }
}

class MonthlyReport {
  final int month;
  final double plannedIncome;
  final double actualIncome;
  final double plannedExpenses;
  final double actualExpenses;
  final List<CategoryAnalysis> categories;

  MonthlyReport({
    required this.month,
    required this.plannedIncome,
    required this.actualIncome,
    required this.plannedExpenses,
    required this.actualExpenses,
    required this.categories,
  });

  double get incomeVariance => actualIncome - plannedIncome;
  double get expenseVariance => actualExpenses - plannedExpenses;
  double get plannedSavings => plannedIncome - plannedExpenses;
  double get actualSavings => actualIncome - actualExpenses;
  double get savingsVariance => actualSavings - plannedSavings;
  
  int get categoriesWithinBudget => categories.where((c) => c.isWithinBudget).length;
  int get categoriesOverBudget => categories.where((c) => c.isOverBudget).length;
  int get categoriesUnderBudget => categories.where((c) => c.isUnderBudget).length;
}

import 'package:uuid/uuid.dart';

class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? email;
  final double monthlySalary;
  final String preferredCurrency;
  final String planType;
  final DateTime? premiumUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.email,
    this.monthlySalary = 0.0,
    this.preferredCurrency = 'BRL',
    this.planType = 'free',
    this.premiumUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      monthlySalary: (json['monthly_salary'] as num?)?.toDouble() ?? 0.0,
      preferredCurrency: json['currency'] as String? ?? json['preferred_currency'] as String? ?? 'BRL',
      planType: json['plan_type'] as String? ?? 'free',
      premiumUntil: json['premium_until'] != null ? DateTime.parse(json['premium_until'] as String) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'monthly_salary': monthlySalary,
        'currency': preferredCurrency,
        'plan_type': planType,
        if (premiumUntil != null) 'premium_until': premiumUntil!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    String? email,
    double? monthlySalary,
    String? preferredCurrency,
    String? planType,
    DateTime? premiumUntil,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      planType: planType ?? this.planType,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static UserProfile empty() {
    final now = DateTime.now();
    return UserProfile(
      id: const Uuid().v4(),
      name: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  String get firstName {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty ? parts.first : name;
  }
}


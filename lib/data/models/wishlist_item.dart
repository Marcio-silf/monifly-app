class WishlistItem {
  final String id;
  final String userId;
  final String name;
  final double value;
  final String category;
  final DateTime registeredAt;
  final DateTime releaseAt;
  final String status; // 'observing', 'bought', 'discarded'
  final bool notifiedDay15;
  final bool notifiedDay30;

  WishlistItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.value,
    required this.category,
    required this.registeredAt,
    required this.releaseAt,
    this.status = 'observing',
    this.notifiedDay15 = false,
    this.notifiedDay30 = false,
  });

  WishlistItem copyWith({
    String? status,
    bool? notifiedDay15,
    bool? notifiedDay30,
  }) {
    return WishlistItem(
      id: id,
      userId: userId,
      name: name,
      value: value,
      category: category,
      registeredAt: registeredAt,
      releaseAt: releaseAt,
      status: status ?? this.status,
      notifiedDay15: notifiedDay15 ?? this.notifiedDay15,
      notifiedDay30: notifiedDay30 ?? this.notifiedDay30,
    );
  }

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'],
      userId: json['userId'] ?? '',
      name: json['name'],
      value: (json['value'] as num).toDouble(),
      category: json['category'],
      registeredAt: DateTime.parse(json['registeredAt']),
      releaseAt: DateTime.parse(json['releaseAt']),
      status: json['status'] ?? 'observing',
      notifiedDay15: json['notifiedDay15'] ?? false,
      notifiedDay30: json['notifiedDay30'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'value': value,
      'category': category,
      'registeredAt': registeredAt.toIso8601String(),
      'releaseAt': releaseAt.toIso8601String(),
      'status': status,
      'notifiedDay15': notifiedDay15,
      'notifiedDay30': notifiedDay30,
    };
  }

  int get daysRemaining {
    final now = DateTime.now();
    return releaseAt.difference(now).inDays;
  }

  bool get canBuy => daysRemaining <= 0;
}

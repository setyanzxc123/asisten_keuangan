class WishlistModel {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? targetDate;
  final bool isAchieved;
  final DateTime createdAt;

  const WishlistModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.targetDate,
    this.isAchieved = false,
    required this.createdAt,
  });

  double get progressRatio {
    if (targetAmount <= 0) return 0.0;
    return (savedAmount / targetAmount).clamp(0.0, 1.0);
  }

  double get progressPercentage => progressRatio * 100;

  double get remainingAmount {
    final diff = targetAmount - savedAmount;
    return diff > 0 ? diff : 0.0;
  }

  WishlistModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    bool? isAchieved,
    DateTime? createdAt,
  }) {
    return WishlistModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      targetDate: targetDate ?? this.targetDate,
      isAchieved: isAchieved ?? this.isAchieved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate?.toIso8601String(),
      'isAchieved': isAchieved,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WishlistModel.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    return WishlistModel(
      id: (map['id'] as String?) ?? fallbackId ?? '',
      title: (map['title'] as String?) ?? 'Target Belanja',
      targetAmount: ((map['targetAmount'] as num?) ?? 0).toDouble(),
      savedAmount: ((map['savedAmount'] as num?) ?? 0).toDouble(),
      targetDate: map['targetDate'] != null
          ? DateTime.tryParse(map['targetDate'].toString())
          : null,
      isAchieved: (map['isAchieved'] as bool?) ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

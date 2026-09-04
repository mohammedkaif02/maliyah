import 'transaction_model.dart';

class BudgetModel {
  final String id;
  final CategoryModel category;
  final double limit;
  final double spent;
  final String period;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    this.period = 'Monthly',
  });

  double get percentUsed => limit <= 0 ? 0 : (spent / limit).clamp(0, 1.4);
  double get remaining => limit - spent;
  bool get isExceeded => spent > limit;
  bool get isNearLimit => limit > 0 && (spent / limit >= 0.8) && !isExceeded;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category.toJson(),
    'limit': limit,
    'spent': spent,
    'period': period,
  };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id: json['id'] as String,
    category: CategoryModel.fromJson(json['category'] as Map<String, dynamic>),
    limit: (json['limit'] as num).toDouble(),
    spent: (json['spent'] as num).toDouble(),
    period: (json['period'] as String?) ?? 'Monthly',
  );

  BudgetModel copyWith({
    String? id,
    CategoryModel? category,
    double? limit,
    double? spent,
    String? period,
  }) => BudgetModel(
    id: id ?? this.id,
    category: category ?? this.category,
    limit: limit ?? this.limit,
    spent: spent ?? this.spent,
    period: period ?? this.period,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

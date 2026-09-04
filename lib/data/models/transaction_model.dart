import 'package:flutter/material.dart';
import 'category_icon_helper.dart';

enum TxType { income, expense, lent, borrowed }

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final TxType type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon.codePoint,
    'color': color.toARGB32(),
    'type': type.name,
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String;
    final iconCode = json['icon'] as int?;
    return CategoryModel(
      id: json['id'] as String,
      name: name,
      icon: CategoryIconHelper.getIcon(name, iconCode),
      color: Color(json['color'] as int),
      type: TxType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TxType.expense,
      ),
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    TxType? type,
  }) => CategoryModel(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    type: type ?? this.type,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TxType type;
  final CategoryModel category;
  final DateTime date;
  final String? note;
  final String paymentMethod;
  final bool isRecurring;

  final String? receiptPath;
  final String? debtPerson;
  final DateTime? debtDueDate;
  final bool isDebtSettled;

  final int? recurringDay;
  final DateTime? recurringEndDate;
  final String? recurringTag;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.paymentMethod = 'UPI',
    this.isRecurring = false,
    this.receiptPath,
    this.debtPerson,
    this.debtDueDate,
    this.isDebtSettled = false,
    this.recurringDay,
    this.recurringEndDate,
    this.recurringTag,
  });

  bool get isDebt => type == TxType.lent || type == TxType.borrowed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type.name,
    'category': category.toJson(),
    'date': date.toIso8601String(),
    'note': note,
    'paymentMethod': paymentMethod,
    'isRecurring': isRecurring,
    'receiptPath': receiptPath,
    'debtPerson': debtPerson,
    'debtDueDate': debtDueDate?.toIso8601String(),
    'isDebtSettled': isDebtSettled,
    'recurringDay': recurringDay,
    'recurringEndDate': recurringEndDate?.toIso8601String(),
    'recurringTag': recurringTag,
  };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TxType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TxType.expense,
        ),
        category: CategoryModel.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
        date: DateTime.parse(json['date'] as String),
        note: json['note'] as String?,
        paymentMethod: (json['paymentMethod'] as String?) ?? 'UPI',
        isRecurring: (json['isRecurring'] as bool?) ?? false,
        receiptPath: json['receiptPath'] as String?,
        debtPerson: json['debtPerson'] as String?,
        debtDueDate: json['debtDueDate'] != null
            ? DateTime.parse(json['debtDueDate'] as String)
            : null,
        isDebtSettled: (json['isDebtSettled'] as bool?) ?? false,
        recurringDay: json['recurringDay'] as int?,
        recurringEndDate: json['recurringEndDate'] != null
            ? DateTime.parse(json['recurringEndDate'] as String)
            : null,
        recurringTag: json['recurringTag'] as String?,
      );

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TxType? type,
    CategoryModel? category,
    DateTime? date,
    String? note,
    String? paymentMethod,
    bool? isRecurring,
    String? receiptPath,
    String? debtPerson,
    DateTime? debtDueDate,
    bool? isDebtSettled,
    int? recurringDay,
    DateTime? recurringEndDate,
    String? recurringTag,
  }) => TransactionModel(
    id: id ?? this.id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    category: category ?? this.category,
    date: date ?? this.date,
    note: note ?? this.note,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    isRecurring: isRecurring ?? this.isRecurring,
    receiptPath: receiptPath ?? this.receiptPath,
    debtPerson: debtPerson ?? this.debtPerson,
    debtDueDate: debtDueDate ?? this.debtDueDate,
    isDebtSettled: isDebtSettled ?? this.isDebtSettled,
    recurringDay: recurringDay ?? this.recurringDay,
    recurringEndDate: recurringEndDate ?? this.recurringEndDate,
    recurringTag: recurringTag ?? this.recurringTag,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

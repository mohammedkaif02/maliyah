import 'package:equatable/equatable.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';

enum FinanceStatus { initial, loading, success, failure }

enum AnalyticsPeriod { daily, weekly, monthly, yearly }

class FinanceState extends Equatable {
  final FinanceStatus status;
  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets;
  final AnalyticsPeriod selectedPeriod;
  final String? errorMessage;
  final String? successMessage;
  final bool isOffline;

  const FinanceState({
    this.status = FinanceStatus.initial,
    this.transactions = const [],
    this.budgets = const [],
    this.selectedPeriod = AnalyticsPeriod.weekly,
    this.errorMessage,
    this.successMessage,
    this.isOffline = false,
  });

  bool get isLoadingData => status == FinanceStatus.loading;

  double get balance => totalIncome - totalExpense;

  double get totalIncome => transactions
      .where((t) => t.type == TxType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == TxType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get savingsRate => totalIncome <= 0
      ? 0.0
      : ((totalIncome - totalExpense) / totalIncome).clamp(0.0, 1.0);

  List<TransactionModel> get recentTransactions {
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  Map<String, double> get spendByCategory {
    final map = <String, double>{};
    for (final t in transactions.where((t) => t.type == TxType.expense)) {
      map[t.category.name] = (map[t.category.name] ?? 0) + t.amount;
    }
    return map;
  }

  List<TransactionModel> get lentTransactions =>
      transactions.where((t) => t.type == TxType.lent).toList();

  List<TransactionModel> get borrowedTransactions =>
      transactions.where((t) => t.type == TxType.borrowed).toList();

  double get totalUnsettledLent => lentTransactions
      .where((t) => !t.isDebtSettled)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalUnsettledBorrowed => borrowedTransactions
      .where((t) => !t.isDebtSettled)
      .fold(0.0, (sum, t) => sum + t.amount);

  List<TransactionModel> get recurringTransactions => transactions
      .where((t) => t.isRecurring || t.recurringDay != null)
      .toList();

  List<TransactionModel> get filteredPeriodTransactions {
    final now = DateTime.now();
    DateTime cutoff;
    switch (selectedPeriod) {
      case AnalyticsPeriod.daily:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case AnalyticsPeriod.weekly:
        cutoff = now.subtract(Duration(days: now.weekday - 1));
        cutoff = DateTime(cutoff.year, cutoff.month, cutoff.day);
        break;
      case AnalyticsPeriod.monthly:
        cutoff = DateTime(now.year, now.month, 1);
        break;
      case AnalyticsPeriod.yearly:
        cutoff = DateTime(now.year, 1, 1);
        break;
    }
    return transactions
        .where(
          (t) => t.date.isAfter(cutoff.subtract(const Duration(seconds: 1))),
        )
        .toList();
  }

  List<double> get periodSpendTrend {
    final now = DateTime.now();
    if (selectedPeriod == AnalyticsPeriod.weekly) {
      final days = List.generate(7, (i) => 0.0);
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      for (final t in transactions.where((t) => t.type == TxType.expense)) {
        final diff = t.date.difference(weekStart).inDays;
        if (diff >= 0 && diff < 7) {
          days[diff] += t.amount;
        }
      }
      return days;
    } else if (selectedPeriod == AnalyticsPeriod.daily) {
      final hours = List.generate(6, (i) => 0.0);
      final todayStart = DateTime(now.year, now.month, now.day);
      for (final t in transactions.where(
        (t) => t.type == TxType.expense && t.date.isAfter(todayStart),
      )) {
        final slot = (t.date.hour / 4).floor().clamp(0, 5);
        hours[slot] += t.amount;
      }
      return hours;
    } else if (selectedPeriod == AnalyticsPeriod.monthly) {
      final weeks = List.generate(4, (i) => 0.0);
      final monthStart = DateTime(now.year, now.month, 1);
      for (final t in transactions.where(
        (t) => t.type == TxType.expense && t.date.isAfter(monthStart),
      )) {
        final weekIdx = ((t.date.day - 1) / 7).floor().clamp(0, 3);
        weeks[weekIdx] += t.amount;
      }
      return weeks;
    } else {
      final months = List.generate(12, (i) => 0.0);
      final yearStart = DateTime(now.year, 1, 1);
      for (final t in transactions.where(
        (t) => t.type == TxType.expense && t.date.isAfter(yearStart),
      )) {
        final mIdx = (t.date.month - 1).clamp(0, 11);
        months[mIdx] += t.amount;
      }
      return months;
    }
  }

  List<String> get periodLabels {
    switch (selectedPeriod) {
      case AnalyticsPeriod.daily:
        return const ['4am', '8am', '12pm', '4pm', '8pm', '12am'];
      case AnalyticsPeriod.weekly:
        return const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      case AnalyticsPeriod.monthly:
        return const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      case AnalyticsPeriod.yearly:
        return const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
    }
  }

  FinanceState copyWith({
    FinanceStatus? status,
    List<TransactionModel>? transactions,
    List<BudgetModel>? budgets,
    AnalyticsPeriod? selectedPeriod,
    String? errorMessage,
    String? successMessage,
    bool? isOffline,
  }) {
    return FinanceState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      budgets: budgets ?? this.budgets,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    budgets,
    selectedPeriod,
    successMessage,
    errorMessage,
    isOffline,
  ];
}

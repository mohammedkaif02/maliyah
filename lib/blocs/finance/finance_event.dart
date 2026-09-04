import 'package:equatable/equatable.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/blocs/finance/finance_state.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();
}

class LoadFinanceDataEvent extends FinanceEvent {
  final String? userId;

  const LoadFinanceDataEvent({this.userId});

  @override
  List<Object?> get props => [userId];
}

class AddTransactionEvent extends FinanceEvent {
  final TransactionModel transaction;

  const AddTransactionEvent({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends FinanceEvent {
  final String transactionId;

  const DeleteTransactionEvent({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

class EditTransactionEvent extends FinanceEvent {
  final TransactionModel updatedTransaction;

  const EditTransactionEvent({required this.updatedTransaction});

  @override
  List<Object?> get props => [updatedTransaction];
}

class UndoDeleteTransactionEvent extends FinanceEvent {
  const UndoDeleteTransactionEvent();

  @override
  List<Object?> get props => [];
}

class ToggleDebtSettledEvent extends FinanceEvent {
  final String transactionId;

  const ToggleDebtSettledEvent({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

class AddBudgetEvent extends FinanceEvent {
  final BudgetModel budget;

  const AddBudgetEvent({required this.budget});

  @override
  List<Object?> get props => [budget];
}

class DeleteBudgetEvent extends FinanceEvent {
  final String budgetId;

  const DeleteBudgetEvent({required this.budgetId});

  @override
  List<Object?> get props => [budgetId];
}

class ChangeAnalyticsPeriodEvent extends FinanceEvent {
  final AnalyticsPeriod period;

  const ChangeAnalyticsPeriodEvent({required this.period});

  @override
  List<Object?> get props => [period];
}

class ResetAllDataEvent extends FinanceEvent {
  const ResetAllDataEvent();

  @override
  List<Object?> get props => [];
}

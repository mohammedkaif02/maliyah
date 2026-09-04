import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/blocs/finance/finance_state.dart';
import 'package:maliyah/data/mock/mock_data.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/data/services/storage_service.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  final StorageService _storage;
  TransactionModel? _lastDeletedTransaction;

  FinanceBloc({required StorageService storage})
    : _storage = storage,
      super(const FinanceState()) {
    on<LoadFinanceDataEvent>(_onLoadFinanceData);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<EditTransactionEvent>(_onEditTransaction);
    on<UndoDeleteTransactionEvent>(_onUndoDeleteTransaction);
    on<ToggleDebtSettledEvent>(_onToggleDebtSettled);
    on<AddBudgetEvent>(_onAddBudget);
    on<DeleteBudgetEvent>(_onDeleteBudget);
    on<ChangeAnalyticsPeriodEvent>(_onChangeAnalyticsPeriod);
    on<ResetAllDataEvent>(_onResetAllData);
  }

  Future<void> _onLoadFinanceData(
    LoadFinanceDataEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));

    try {
      final targetUserId = event.userId ?? _storage.currentUserId;
      await _storage.switchUser(targetUserId);

      final now = DateTime.now();

      final savedTx = _storage.loadTransactions();
      final List<TransactionModel> transactions;

      if (savedTx != null) {
        transactions = savedTx;
      } else {
        if (targetUserId == 'guest') {
          transactions = MockData.transactions(now);
          await _storage.saveTransactions(transactions);
        } else {
          transactions = [];
          await _storage.saveTransactions(transactions);
        }
      }

      final savedBudgets = _storage.loadBudgets();
      List<BudgetModel> budgets;

      if (savedBudgets != null) {
        budgets = savedBudgets;
      } else {
        budgets = MockData.budgets.map((b) => b.copyWith(spent: 0)).toList();
        await _storage.saveBudgets(budgets);
      }

      budgets = _recalculateBudgetSpent(budgets, transactions);

      emit(
        state.copyWith(
          status: FinanceStatus.success,
          transactions: transactions,
          budgets: budgets,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FinanceStatus.failure,
          errorMessage: 'Failed to load data: $e',
        ),
      );
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final updatedTx = [event.transaction, ...state.transactions];
    final updatedBudgets = _recalculateBudgetSpent(state.budgets, updatedTx);

    await _storage.saveTransactions(updatedTx);
    await _storage.saveBudgets(updatedBudgets);

    emit(
      state.copyWith(
        transactions: updatedTx,
        budgets: updatedBudgets,
        successMessage: 'Transaction added',
      ),
    );
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    _lastDeletedTransaction = state.transactions
        .where((t) => t.id == event.transactionId)
        .firstOrNull;

    final updatedTx = state.transactions
        .where((t) => t.id != event.transactionId)
        .toList();

    final updatedBudgets = _recalculateBudgetSpent(state.budgets, updatedTx);

    await _storage.saveTransactions(updatedTx);
    await _storage.saveBudgets(updatedBudgets);

    emit(
      state.copyWith(
        transactions: updatedTx,
        budgets: updatedBudgets,
        successMessage: 'Transaction deleted',
      ),
    );
  }

  Future<void> _onEditTransaction(
    EditTransactionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final updatedTx = state.transactions.map((t) {
      return t.id == event.updatedTransaction.id ? event.updatedTransaction : t;
    }).toList();

    final updatedBudgets = _recalculateBudgetSpent(state.budgets, updatedTx);

    await _storage.saveTransactions(updatedTx);
    await _storage.saveBudgets(updatedBudgets);

    emit(
      state.copyWith(
        transactions: updatedTx,
        budgets: updatedBudgets,
        successMessage: 'Transaction updated',
      ),
    );
  }

  Future<void> _onUndoDeleteTransaction(
    UndoDeleteTransactionEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final tx = _lastDeletedTransaction;
    if (tx == null) return;

    final updatedTx = [tx, ...state.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    final updatedBudgets = _recalculateBudgetSpent(state.budgets, updatedTx);

    await _storage.saveTransactions(updatedTx);
    await _storage.saveBudgets(updatedBudgets);

    _lastDeletedTransaction = null;

    emit(
      state.copyWith(
        transactions: updatedTx,
        budgets: updatedBudgets,
        successMessage: 'Transaction restored',
      ),
    );
  }

  Future<void> _onToggleDebtSettled(
    ToggleDebtSettledEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final updatedTx = state.transactions.map((tx) {
      if (tx.id == event.transactionId) {
        return tx.copyWith(isDebtSettled: !tx.isDebtSettled);
      }
      return tx;
    }).toList();

    await _storage.saveTransactions(updatedTx);

    emit(
      state.copyWith(transactions: updatedTx, successMessage: 'Status updated'),
    );
  }

  Future<void> _onAddBudget(
    AddBudgetEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final budgetWithSpent = _computeSpentForBudget(
      event.budget,
      state.transactions,
    );

    final existingIndex = state.budgets.indexWhere(
      (b) =>
          b.id == event.budget.id || b.category.id == event.budget.category.id,
    );

    final List<BudgetModel> updatedBudgets;
    if (existingIndex != -1) {
      updatedBudgets = List<BudgetModel>.from(state.budgets);
      updatedBudgets[existingIndex] = budgetWithSpent;
    } else {
      updatedBudgets = [...state.budgets, budgetWithSpent];
    }

    await _storage.saveBudgets(updatedBudgets);

    emit(
      state.copyWith(
        budgets: updatedBudgets,
        successMessage: existingIndex != -1 ? 'Budget updated' : 'Budget added',
      ),
    );
  }

  Future<void> _onDeleteBudget(
    DeleteBudgetEvent event,
    Emitter<FinanceState> emit,
  ) async {
    final updatedBudgets = state.budgets
        .where((b) => b.id != event.budgetId)
        .toList();

    await _storage.saveBudgets(updatedBudgets);

    emit(
      state.copyWith(budgets: updatedBudgets, successMessage: 'Budget removed'),
    );
  }

  void _onChangeAnalyticsPeriod(
    ChangeAnalyticsPeriodEvent event,
    Emitter<FinanceState> emit,
  ) {
    emit(state.copyWith(selectedPeriod: event.period));
  }

  Future<void> _onResetAllData(
    ResetAllDataEvent event,
    Emitter<FinanceState> emit,
  ) async {
    emit(state.copyWith(status: FinanceStatus.loading));

    await _storage.clearAll();
    _lastDeletedTransaction = null;

    final now = DateTime.now();
    final freshTx = MockData.transactions(now);
    final freshBudgets = _recalculateBudgetSpent(MockData.budgets, freshTx);

    await _storage.saveTransactions(freshTx);
    await _storage.saveBudgets(freshBudgets);

    emit(
      state.copyWith(
        status: FinanceStatus.success,
        transactions: freshTx,
        budgets: freshBudgets,
        successMessage: 'All data has been reset',
      ),
    );
  }

  List<BudgetModel> _recalculateBudgetSpent(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    return budgets.map((budget) {
      return _computeSpentForBudget(budget, transactions);
    }).toList();
  }

  BudgetModel _computeSpentForBudget(
    BudgetModel budget,
    List<TransactionModel> transactions,
  ) {
    final spent = transactions
        .where(
          (t) =>
              t.type == TxType.expense && t.category.id == budget.category.id,
        )
        .fold(0.0, (sum, t) => sum + t.amount);

    return budget.copyWith(spent: spent);
  }
}

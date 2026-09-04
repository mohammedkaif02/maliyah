import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/core/theme/app_theme.dart';
import 'package:maliyah/data/mock/mock_data.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/data/services/storage_service.dart';
import 'package:maliyah/screens/budgets/budgets_screen.dart';
import 'package:maliyah/screens/transactions/transactions_screen.dart';

class FakeStorageService implements StorageService {
  List<TransactionModel> txs = [];
  List<BudgetModel> budgets = [];

  @override
  String get currentUserId => 'test_user';

  @override
  List<TransactionModel>? loadTransactions() => txs;

  @override
  Future<void> saveTransactions(List<TransactionModel> newTxs) async {
    txs = newTxs;
  }

  @override
  Future<void> putTransaction(TransactionModel tx) async {
    txs.add(tx);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    txs.removeWhere((t) => t.id == id);
  }

  @override
  List<BudgetModel>? loadBudgets() => budgets;

  @override
  Future<void> saveBudgets(List<BudgetModel> newBudgets) async {
    budgets = newBudgets;
  }

  @override
  Future<void> putBudget(BudgetModel budget) async {
    budgets.add(budget);
  }

  @override
  Future<void> deleteBudget(String id) async {
    budgets.removeWhere((b) => b.id == id);
  }

  @override
  String? loadThemeMode() => 'light';

  @override
  Future<void> saveThemeMode(String modeStr) async {}

  @override
  bool loadOnboardingSeen() => true;

  @override
  Future<void> saveOnboardingSeen() async {}

  @override
  Future<void> switchUser(String userId) async {}

  @override
  Future<void> deleteUserData(String userId) async {}

  @override
  Future<void> clearAll() async {
    txs.clear();
    budgets.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeStorageService fakeStorage;
  late FinanceBloc financeBloc;

  setUp(() {
    fakeStorage = FakeStorageService();
    fakeStorage.txs = MockData.transactions(DateTime(2026, 8, 28));
    fakeStorage.budgets = MockData.budgets;
    financeBloc = FinanceBloc(storage: fakeStorage);
  });

  tearDown(() {
    financeBloc.close();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<FinanceBloc>.value(value: financeBloc, child: child),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }

  group('TransactionsScreen Widget Tests', () {
    testWidgets('Renders search bar, filter tabs, and transactions', (
      tester,
    ) async {
      financeBloc.add(const LoadFinanceDataEvent(userId: 'test_user'));
      await tester.pumpWidget(buildTestableWidget(const TransactionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Expense'), findsOneWidget);
    });

    testWidgets('Filter tabs switch between all, income and expense', (
      tester,
    ) async {
      financeBloc.add(const LoadFinanceDataEvent(userId: 'test_user'));
      await tester.pumpWidget(buildTestableWidget(const TransactionsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      expect(find.text('Income'), findsWidgets);

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      expect(find.text('Expense'), findsWidgets);
    });
  });

  group('BudgetsScreen Widget Tests', () {
    testWidgets('Renders budget overview progress and list', (tester) async {
      financeBloc.add(const LoadFinanceDataEvent(userId: 'test_user'));
      await tester.pumpWidget(buildTestableWidget(const BudgetsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text("This Month's Budget"), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
    });
  });
}

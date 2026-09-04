import 'package:flutter_test/flutter_test.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/blocs/finance/finance_state.dart';
import 'package:maliyah/data/mock/mock_data.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/data/services/storage_service.dart';

class MockableStorageService implements StorageService {
  String _activeUser = 'guest';
  final Map<String, List<TransactionModel>> _userTxs = {};
  final Map<String, List<BudgetModel>> _userBudgets = {};

  @override
  String get currentUserId => _activeUser;

  @override
  Future<void> switchUser(String userId) async {
    _activeUser = userId;
  }

  @override
  List<TransactionModel>? loadTransactions() => _userTxs[_activeUser];

  @override
  Future<void> saveTransactions(List<TransactionModel> txs) async {
    _userTxs[_activeUser] = List.from(txs);
  }

  @override
  List<BudgetModel>? loadBudgets() => _userBudgets[_activeUser];

  @override
  Future<void> saveBudgets(List<BudgetModel> budgets) async {
    _userBudgets[_activeUser] = List.from(budgets);
  }

  @override
  Future<void> putTransaction(TransactionModel tx) async {
    _userTxs.putIfAbsent(_activeUser, () => []).insert(0, tx);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _userTxs[_activeUser]?.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> putBudget(BudgetModel budget) async {
    final list = _userBudgets.putIfAbsent(_activeUser, () => []);
    final idx = list.indexWhere((b) => b.id == budget.id);
    if (idx >= 0) {
      list[idx] = budget;
    } else {
      list.add(budget);
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    _userBudgets[_activeUser]?.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> clearAll() async {
    _userTxs[_activeUser]?.clear();
    _userBudgets[_activeUser]?.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('FinanceBloc - Multi-User Persistence & Refresh Isolation', () {
    late MockableStorageService storage;
    late FinanceBloc bloc;

    setUp(() {
      storage = MockableStorageService();
      bloc = FinanceBloc(storage: storage);
    });

    tearDown(() {
      bloc.close();
    });

    test(
      'Fresh registered user starts with 0 transactions and does not load guest data',
      () async {
        bloc.add(const LoadFinanceDataEvent(userId: 'user_kaif'));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            predicate<FinanceState>((s) => s.status == FinanceStatus.loading),
            predicate<FinanceState>(
              (s) =>
                  s.status == FinanceStatus.success && s.transactions.isEmpty,
            ),
          ]),
        );
        expect(storage.currentUserId, equals('user_kaif'));
      },
    );

    test(
      'Pull-to-refresh without userId preserves active user session and data',
      () async {
        bloc.add(const LoadFinanceDataEvent(userId: 'user_kaif'));
        await bloc.stream.firstWhere((s) => s.status == FinanceStatus.success);

        final customTx = TransactionModel(
          id: 'tx_kaif_1',
          title: 'Freelance Project Payment',
          amount: 25000,
          type: TxType.income,
          category: MockData.catFreelance,
          date: DateTime.now(),
        );
        bloc.add(AddTransactionEvent(transaction: customTx));
        await bloc.stream.firstWhere((s) => s.transactions.isNotEmpty);

        expect(bloc.state.transactions.length, equals(1));
        expect(
          bloc.state.transactions.first.title,
          equals('Freelance Project Payment'),
        );

        bloc.add(const LoadFinanceDataEvent());
        await bloc.stream.firstWhere((s) => s.status == FinanceStatus.loading);
        final refreshedState = await bloc.stream.firstWhere(
          (s) => s.status == FinanceStatus.success,
        );

        expect(storage.currentUserId, equals('user_kaif'));
        expect(refreshedState.transactions.length, equals(1));
        expect(
          refreshedState.transactions.first.title,
          equals('Freelance Project Payment'),
        );
        expect(refreshedState.balance, equals(25000.0));
      },
    );

    test('Guest session still loads mock data as expected', () async {
      bloc.add(const LoadFinanceDataEvent(userId: 'guest'));
      final state = await bloc.stream.firstWhere(
        (s) => s.status == FinanceStatus.success,
      );

      expect(storage.currentUserId, equals('guest'));
      expect(state.transactions.isNotEmpty, isTrue);
    });
  });
}

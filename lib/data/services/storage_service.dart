import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/hive_adapters.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/data/models/user_model.dart';

class StorageService {
  static const String _settingsBoxName = 'fintrack_global_settings_v1';
  static const String _themeKey = 'theme_mode';
  static const String _onboardingSeenKey = 'onboarding_seen';
  static const String _authUserKey = 'auth_user';
  static const String _authCredentialsKey = 'auth_credentials';

  final Box<dynamic> _settingsBox;
  Box<TransactionModel> _txBox;
  Box<BudgetModel> _budgetBox;
  String _currentUserId;

  StorageService({
    required Box<dynamic> settingsBox,
    required Box<TransactionModel> txBox,
    required Box<BudgetModel> budgetBox,
    required String currentUserId,
  }) : _settingsBox = settingsBox,
       _txBox = txBox,
       _budgetBox = budgetBox,
       _currentUserId = currentUserId;

  String get currentUserId => _currentUserId;

  static String _sanitizeBoxName(String userId) {
    return userId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  static Future<StorageService> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TxTypeAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(TransactionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(BudgetModelAdapter());
    }

    final settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

    String initialUserId = 'guest';
    final savedAuthUserStr = settingsBox.get(_authUserKey) as String?;
    if (savedAuthUserStr != null && savedAuthUserStr.isNotEmpty) {
      try {
        final map = jsonDecode(savedAuthUserStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(map);
        if (user.id.isNotEmpty) {
          initialUserId = user.id;
        }
      } catch (_) {}
    }

    final safeId = _sanitizeBoxName(initialUserId);
    final txBox = await Hive.openBox<TransactionModel>('fintrack_tx_$safeId');
    final budgetBox = await Hive.openBox<BudgetModel>(
      'fintrack_budgets_$safeId',
    );

    return StorageService(
      settingsBox: settingsBox,
      txBox: txBox,
      budgetBox: budgetBox,
      currentUserId: initialUserId,
    );
  }

  Future<void> switchUser(String userId) async {
    final effectiveId = userId.trim().isEmpty ? 'guest' : userId.trim();
    if (_currentUserId == effectiveId && _txBox.isOpen && _budgetBox.isOpen) {
      return;
    }

    final safeId = _sanitizeBoxName(effectiveId);
    final newTxBox = await Hive.openBox<TransactionModel>(
      'fintrack_tx_$safeId',
    );
    final newBudgetBox = await Hive.openBox<BudgetModel>(
      'fintrack_budgets_$safeId',
    );

    _txBox = newTxBox;
    _budgetBox = newBudgetBox;
    _currentUserId = effectiveId;
  }

  Future<void> deleteUserData(String userId) async {
    final safeId = _sanitizeBoxName(userId);
    final txBoxName = 'fintrack_tx_$safeId';
    final budgetBoxName = 'fintrack_budgets_$safeId';

    if (Hive.isBoxOpen(txBoxName)) {
      await Hive.box<TransactionModel>(txBoxName).clear();
      await Hive.box<TransactionModel>(txBoxName).close();
    }
    if (Hive.isBoxOpen(budgetBoxName)) {
      await Hive.box<BudgetModel>(budgetBoxName).clear();
      await Hive.box<BudgetModel>(budgetBoxName).close();
    }

    await Hive.deleteBoxFromDisk(txBoxName);
    await Hive.deleteBoxFromDisk(budgetBoxName);

    if (_currentUserId == userId) {
      await switchUser('guest');
    }
  }

  List<TransactionModel>? loadTransactions() {
    if (!_txBox.isOpen || _txBox.isEmpty) return null;
    return _txBox.values.toList();
  }

  Future<void> saveTransactions(List<TransactionModel> txs) async {
    if (!_txBox.isOpen) return;
    await _txBox.clear();
    final map = {for (final t in txs) t.id: t};
    await _txBox.putAll(map);
  }

  Future<void> putTransaction(TransactionModel tx) async {
    if (!_txBox.isOpen) return;
    await _txBox.put(tx.id, tx);
  }

  Future<void> deleteTransaction(String id) async {
    if (!_txBox.isOpen) return;
    await _txBox.delete(id);
  }

  List<BudgetModel>? loadBudgets() {
    if (!_budgetBox.isOpen || _budgetBox.isEmpty) return null;
    return _budgetBox.values.toList();
  }

  Future<void> saveBudgets(List<BudgetModel> budgets) async {
    if (!_budgetBox.isOpen) return;
    await _budgetBox.clear();
    final map = {for (final b in budgets) b.id: b};
    await _budgetBox.putAll(map);
  }

  Future<void> putBudget(BudgetModel budget) async {
    if (!_budgetBox.isOpen) return;
    await _budgetBox.put(budget.id, budget);
  }

  Future<void> deleteBudget(String id) async {
    if (!_budgetBox.isOpen) return;
    await _budgetBox.delete(id);
  }

  String? loadThemeMode() {
    return _settingsBox.get(_themeKey) as String?;
  }

  Future<void> saveThemeMode(String modeStr) async {
    await _settingsBox.put(_themeKey, modeStr);
  }

  bool loadOnboardingSeen() {
    return (_settingsBox.get(_onboardingSeenKey) as bool?) ?? false;
  }

  Future<void> saveOnboardingSeen() async {
    await _settingsBox.put(_onboardingSeenKey, true);
  }

  UserModel? loadAuthUser() {
    final jsonStr = _settingsBox.get(_authUserKey) as String?;
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAuthUser(UserModel user) async {
    await _settingsBox.put(_authUserKey, jsonEncode(user.toJson()));
  }

  Future<void> clearAuthUser() async {
    await _settingsBox.delete(_authUserKey);
  }

  Map<String, dynamic>? loadAuthCredentials() {
    final jsonStr = _settingsBox.get(_authCredentialsKey) as String?;
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAuthCredentials({
    required String id,
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    await _settingsBox.put(
      _authCredentialsKey,
      jsonEncode({
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
      }),
    );
  }

  Future<void> clearAll() async {
    if (_txBox.isOpen) await _txBox.clear();
    if (_budgetBox.isOpen) await _budgetBox.clear();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/hive_adapters.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/data/models/user_model.dart';

void main() {
  group('Hive Adapters Registry Tests', () {
    test('TypeIds match specification', () {
      expect(TxTypeAdapter().typeId, equals(0));
      expect(CategoryModelAdapter().typeId, equals(1));
      expect(TransactionModelAdapter().typeId, equals(2));
      expect(BudgetModelAdapter().typeId, equals(3));
    });
  });

  group('Data Models Integrity Tests', () {
    const category = CategoryModel(
      id: 'cat_food',
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      color: Colors.amber,
      type: TxType.expense,
    );

    test('CategoryModel JSON serialization roundtrip', () {
      final json = category.toJson();
      final restored = CategoryModel.fromJson(json);
      expect(restored.id, equals(category.id));
      expect(restored.name, equals(category.name));
      expect(restored.type, equals(category.type));
    });

    test('TransactionModel JSON serialization roundtrip', () {
      final tx = TransactionModel(
        id: 'tx_001',
        title: 'Grocery Shopping',
        amount: 1540.50,
        type: TxType.expense,
        category: category,
        date: DateTime(2026, 8, 28, 14, 30),
        note: 'Weekly essentials',
        paymentMethod: 'UPI',
        isRecurring: false,
      );

      final json = tx.toJson();
      final restored = TransactionModel.fromJson(json);
      expect(restored.id, equals(tx.id));
      expect(restored.title, equals(tx.title));
      expect(restored.amount, equals(tx.amount));
      expect(restored.category.name, equals('Food & Dining'));
      expect(restored.paymentMethod, equals('UPI'));
    });

    test('BudgetModel computations', () {
      const budget = BudgetModel(
        id: 'b_001',
        category: category,
        limit: 5000.0,
        spent: 4200.0,
      );

      expect(budget.percentUsed, closeTo(0.84, 0.01));
      expect(budget.remaining, equals(800.0));
      expect(budget.isNearLimit, isTrue);
      expect(budget.isExceeded, isFalse);

      final exceededBudget = budget.copyWith(spent: 5500.0);
      expect(exceededBudget.isExceeded, isTrue);
      expect(exceededBudget.remaining, equals(-500.0));
    });

    test('UserModel helper getters', () {
      const userWithFullName = UserModel(
        id: '1',
        name: 'Kaif Mohammed',
        email: 'kaif@gmail.com',
      );
      expect(userWithFullName.initials, equals('KM'));
      expect(userWithFullName.firstName, equals('Kaif'));

      const userWithSingleName = UserModel(
        id: '2',
        name: 'Arif',
        email: 'arif@gmail.com',
      );
      expect(userWithSingleName.initials, equals('A'));
      expect(userWithSingleName.firstName, equals('Arif'));

      const blankUser = UserModel(
        id: '3',
        name: '',
        email: 'guest@fintrack.app',
      );
      expect(blankUser.initials, equals('?'));
      expect(blankUser.firstName, equals('User'));
    });
  });
}

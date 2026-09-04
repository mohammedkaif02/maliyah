import 'package:flutter_test/flutter_test.dart';
import 'package:maliyah/core/utils/validators.dart';
import 'package:maliyah/data/models/hive_adapters.dart';
import 'package:maliyah/data/models/user_model.dart';

void main() {
  group('Validators Unit Tests', () {
    test('Valid email addresses return true', () {
      expect(Validators.isValidEmail('test@example.com'), isTrue);
      expect(Validators.isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(Validators.isValidEmail('name+tag@sub.domain.org'), isTrue);
    });

    test('Invalid email addresses return false', () {
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail(null), isFalse);
      expect(Validators.isValidEmail('plainaddress'), isFalse);
      expect(Validators.isValidEmail('@missingusername.com'), isFalse);
    });

    test('Password validator validates minimum length', () {
      expect(
        Validators.passwordValidator(''),
        equals('Please enter your password'),
      );
      expect(
        Validators.passwordValidator('12345'),
        equals('Password must be at least 6 characters'),
      );
      expect(Validators.passwordValidator('123456'), isNull);
    });

    test('Name validator validates length', () {
      expect(Validators.nameValidator(''), equals('Please enter your name'));
      expect(
        Validators.nameValidator('A'),
        equals('Name must be at least 2 characters'),
      );
      expect(Validators.nameValidator('Mohammed Arif'), isNull);
    });
  });

  group('UserModel Unit Tests', () {
    test('UserModel initials handles normal and multi-part names', () {
      const user = UserModel(
        id: '1',
        name: 'Mohammed Arif',
        email: 'arif@example.com',
      );
      expect(user.initials, equals('MA'));
      expect(user.firstName, equals('Mohammed'));
    });

    test('UserModel initials handles single name', () {
      const user = UserModel(id: '2', name: 'Arif', email: 'arif@example.com');
      expect(user.initials, equals('A'));
      expect(user.firstName, equals('Arif'));
    });

    test('UserModel initials handles empty or whitespace name defensively', () {
      const user = UserModel(id: '3', name: '', email: 'guest@example.com');
      expect(user.initials, equals('?'));
      expect(user.firstName, equals('User'));
    });
  });

  group('Hive Adapters Unit Tests', () {
    test('TxTypeAdapter writes and reads correctly', () {
      final adapter = TxTypeAdapter();
      expect(adapter.typeId, equals(0));
    });

    test('CategoryModelAdapter typeId is 1', () {
      final adapter = CategoryModelAdapter();
      expect(adapter.typeId, equals(1));
    });

    test('TransactionModelAdapter typeId is 2', () {
      final adapter = TransactionModelAdapter();
      expect(adapter.typeId, equals(2));
    });

    test('BudgetModelAdapter typeId is 3', () {
      final adapter = BudgetModelAdapter();
      expect(adapter.typeId, equals(3));
    });
  });
}

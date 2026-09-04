import 'package:flutter_test/flutter_test.dart';
import 'package:maliyah/core/utils/validators.dart';

void main() {
  group('Validators - Email', () {
    test('Valid email addresses pass validation', () {
      expect(Validators.isValidEmail('test@example.com'), isTrue);
      expect(Validators.isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(Validators.isValidEmail('name+tag@sub.domain.org'), isTrue);
      expect(Validators.isValidEmail('kaif@gmail.com'), isTrue);
      expect(Validators.emailValidator('test@example.com'), isNull);
    });

    test('Invalid email addresses return error messages', () {
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail(null), isFalse);
      expect(Validators.isValidEmail('plainaddress'), isFalse);
      expect(Validators.isValidEmail('@missingusername.com'), isFalse);
      expect(Validators.isValidEmail('username@.com'), isFalse);

      expect(Validators.emailValidator(''), equals('Please enter your email'));
      expect(
        Validators.emailValidator('invalid'),
        equals('Enter a valid email address'),
      );
    });
  });

  group('Validators - Password', () {
    test('Empty password returns prompt', () {
      expect(
        Validators.passwordValidator(''),
        equals('Please enter your password'),
      );
      expect(
        Validators.passwordValidator(null),
        equals('Please enter your password'),
      );
    });

    test('Short password returns minimum length requirement', () {
      expect(
        Validators.passwordValidator('12345'),
        equals('Password must be at least 6 characters'),
      );
    });

    test('Valid password returns null', () {
      expect(Validators.passwordValidator('123456'), isNull);
      expect(Validators.passwordValidator('StrongP@ssw0rd!'), isNull);
    });
  });

  group('Validators - Name', () {
    test('Empty name returns prompt', () {
      expect(Validators.nameValidator(''), equals('Please enter your name'));
      expect(Validators.nameValidator('   '), equals('Please enter your name'));
      expect(Validators.nameValidator(null), equals('Please enter your name'));
    });

    test('Short name returns minimum length requirement', () {
      expect(
        Validators.nameValidator('A'),
        equals('Name must be at least 2 characters'),
      );
    });

    test('Valid name returns null', () {
      expect(Validators.nameValidator('Mohammed Kaif'), isNull);
      expect(Validators.nameValidator('Arif'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:maliyah/data/services/receipt_scanner_service.dart';
import 'package:maliyah/data/mock/mock_data.dart';

void main() {
  final scanner = ReceiptScannerService();

  group('ReceiptScannerService - Amount Extraction', () {
    test('Extracts whole rupee amounts with ₹ symbol', () {
      expect(
        scanner.extractAmountForTesting(
          'Paid to Muhammad Iliyaz\n₹500\nCompleted',
        ),
        equals(500.0),
      );
      expect(
        scanner.extractAmountForTesting('Payment of ₹ 1500 to Store'),
        equals(1500.0),
      );
      expect(
        scanner.extractAmountForTesting('₹150.00 transferred successfully'),
        equals(150.0),
      );
    });

    test('Extracts amounts with Rs and INR abbreviations', () {
      expect(
        scanner.extractAmountForTesting('Total Amount: Rs. 2450.50'),
        equals(2450.50),
      );
      expect(
        scanner.extractAmountForTesting('INR 750 debited from account'),
        equals(750.0),
      );
    });

    test('Extracts amount when OCR misreads rupee symbol as ? or F or *', () {
      expect(
        scanner.extractAmountForTesting('Paid to Merchant\n?240\nSuccess'),
        equals(240.0),
      );
      expect(scanner.extractAmountForTesting('Amount: F1200'), equals(1200.0));
    });

    test('Extracts action phrases without explicit currency symbols', () {
      expect(
        scanner.extractAmountForTesting('Paid 350 to Chai Point'),
        equals(350.0),
      );
      expect(
        scanner.extractAmountForTesting('Debited 1200 from your bank'),
        equals(1200.0),
      );
      expect(scanner.extractAmountForTesting('Amount: 480'), equals(480.0));
    });

    test('Ignores years, phone numbers, and 12-digit UPI reference IDs', () {
      const gpayText = '''
Paid to
Muhammad Iliyaz
₹500
Completed • 4 Sep 2026, 2:26 pm
UPI transaction ID: 424888123456
Google Pay
''';
      expect(scanner.extractAmountForTesting(gpayText), equals(500.0));
    });
  });

  group('ReceiptScannerService - Merchant Extraction', () {
    test('Extracts merchant name after Paid to', () {
      expect(
        scanner.extractMerchantForTesting('Paid to Muhammad Iliyaz\n₹500'),
        equals('Muhammad Iliyaz'),
      );
    });

    test('Extracts medical store or business name', () {
      expect(
        scanner.extractMerchantForTesting('Paid to MHATRE MEDICAL\n₹240'),
        equals('MHATRE MEDICAL'),
      );
    });
  });

  group('ReceiptScannerService - Category Inference & MockData Alignment', () {
    test('Medical and pharmacy keywords map to Healthcare', () {
      final cat = scanner.inferCategoryForTesting(
        'MHATRE MEDICAL',
        'MHATRE MEDICAL PHARMACY ₹240',
      );
      expect(cat, equals('Healthcare'));
      expect(MockData.allCategories.any((c) => c.name == cat), isTrue);
    });

    test('Food and restaurant keywords map to Dining', () {
      final cat = scanner.inferCategoryForTesting(
        'Swiggy',
        'Swiggy order #1234 ₹350',
      );
      expect(cat, equals('Dining'));
      expect(MockData.allCategories.any((c) => c.name == cat), isTrue);
    });

    test('Grocery and quick-commerce keywords map to Groceries', () {
      final cat = scanner.inferCategoryForTesting(
        'Blinkit',
        'Blinkit Commerce Pvt Ltd ₹450',
      );
      expect(cat, equals('Groceries'));
      expect(MockData.allCategories.any((c) => c.name == cat), isTrue);
    });

    test('Transport and fuel keywords map to Transportation', () {
      final cat = scanner.inferCategoryForTesting(
        'Uber India',
        'Uber trip receipt ₹280',
      );
      expect(cat, equals('Transportation'));
      expect(MockData.allCategories.any((c) => c.name == cat), isTrue);
    });

    test('E-commerce keywords map to Shopping', () {
      final cat = scanner.inferCategoryForTesting(
        'Amazon Pay',
        'Amazon Retail India ₹1299',
      );
      expect(cat, equals('Shopping'));
      expect(MockData.allCategories.any((c) => c.name == cat), isTrue);
    });

    test('Utilities and recharge map to Utilities', () {
      final cat = scanner.inferCategoryForTesting(
        'Airtel Prepaid',
        'Airtel recharge ₹299',
      );
      expect(cat, equals('Utilities'));
      expect(MockData.allCategories.any((c) => c.name == cat), isTrue);
    });
  });
}

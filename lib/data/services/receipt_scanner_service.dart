import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ScannedReceiptData {
  final double? amount;
  final String? merchant;
  final String? paymentMethod;
  final String? suggestedCategory;
  final DateTime? date;
  final String? imagePath;
  final String rawText;

  const ScannedReceiptData({
    this.amount,
    this.merchant,
    this.paymentMethod,
    this.suggestedCategory,
    this.date,
    this.imagePath,
    required this.rawText,
  });
}

class ReceiptScannerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickReceiptImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
      );
      if (picked == null) return null;

      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${appDir.path}/receipts');
      if (!receiptsDir.existsSync()) {
        receiptsDir.createSync(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(
        picked.path,
      ).copy('${receiptsDir.path}/$fileName');
      return savedFile;
    } catch (e) {
      debugPrint('Error picking receipt image: $e');
      return null;
    }
  }

  Future<ScannedReceiptData> parseReceiptImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      final amount = _extractAmount(rawText, recognizedText.blocks);
      final merchant = _extractMerchant(rawText, recognizedText.blocks);
      final paymentMethod = _extractPaymentMethod(rawText);
      final suggestedCategory = _inferCategory(merchant, rawText);
      final date = _extractDate(rawText);

      return ScannedReceiptData(
        amount: amount,
        merchant: merchant,
        paymentMethod: paymentMethod,
        suggestedCategory: suggestedCategory,
        date: date,
        imagePath: imageFile.path,
        rawText: rawText,
      );
    } catch (e) {
      debugPrint('Error recognizing text: $e');
      return ScannedReceiptData(imagePath: imageFile.path, rawText: '');
    } finally {
      await textRecognizer.close();
    }
  }

  @visibleForTesting
  double? extractAmountForTesting(
    String text, [
    List<TextBlock> blocks = const [],
  ]) => _extractAmount(text, blocks);

  @visibleForTesting
  String? inferCategoryForTesting(String? merchant, String rawText) =>
      _inferCategory(merchant, rawText);

  @visibleForTesting
  String? extractMerchantForTesting(
    String text, [
    List<TextBlock> blocks = const [],
  ]) => _extractMerchant(text, blocks);

  double? _extractAmount(String text, List<TextBlock> blocks) {
    final currencyPatterns = [
      RegExp(
        r'(?:₹|Rs\.?|INR|\$|\u20B9|\u0930|(?<![a-zA-Z0-9])[\?F\*])\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:paid|amount|total|debited|transfer(?:red)?|payment(?:\s+of)?|sent)\s*[:\-]?\s*(?:₹|Rs\.?|INR|\$|\u20B9|\?|F)?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in currencyPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final rawNum = match.group(1)?.replaceAll(',', '');
        if (rawNum != null) {
          final val = double.tryParse(rawNum);
          if (val != null && _isValidAmount(val, rawNum)) {
            return val;
          }
        }
      }
    }

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      final lineMatch = RegExp(
        r'^(?:₹|Rs\.?|INR|\$|\u20B9|\u0930|[\?F\*])\s*([\d,]+(?:\.\d{1,2})?)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (lineMatch != null) {
        final rawNum = lineMatch.group(1)?.replaceAll(',', '');
        if (rawNum != null) {
          final val = double.tryParse(rawNum);
          if (val != null && _isValidAmount(val, rawNum)) return val;
        }
      }
    }

    for (int bIdx = 0; bIdx < blocks.length; bIdx++) {
      final block = blocks[bIdx];
      for (int lIdx = 0; lIdx < block.lines.length; lIdx++) {
        final line = block.lines[lIdx].text.trim();

        final symbolLineMatch = RegExp(
          r'^[₹RsINR\$\u20B9\u0930\?F\*]\s*([\d,]+(?:\.\d{1,2})?)$',
          caseSensitive: false,
        ).firstMatch(line);
        if (symbolLineMatch != null) {
          final rawNum = symbolLineMatch.group(1)?.replaceAll(',', '');
          if (rawNum != null) {
            final val = double.tryParse(rawNum);
            if (val != null && _isValidAmount(val, rawNum)) return val;
          }
        }

        if (RegExp(
          r'^[₹RsINR\$\u20B9\u0930\?F\*]+$',
          caseSensitive: false,
        ).hasMatch(line)) {
          if (lIdx + 1 < block.lines.length) {
            final nextLine = block.lines[lIdx + 1].text.trim().replaceAll(
              ',',
              '',
            );
            final val = double.tryParse(nextLine);
            if (val != null && _isValidAmount(val, nextLine)) return val;
          } else if (bIdx + 1 < blocks.length &&
              blocks[bIdx + 1].lines.isNotEmpty) {
            final nextLine = blocks[bIdx + 1].lines.first.text
                .trim()
                .replaceAll(',', '');
            final val = double.tryParse(nextLine);
            if (val != null && _isValidAmount(val, nextLine)) return val;
          }
        }
      }
    }

    final decimalPattern = RegExp(r'\b([\d,]+\.\d{2})\b');
    for (final m in decimalPattern.allMatches(text)) {
      final cleanNum = m.group(1)?.replaceAll(',', '');
      if (cleanNum != null) {
        final val = double.tryParse(cleanNum);
        if (val != null && _isValidAmount(val, cleanNum)) return val;
      }
    }

    for (final block in blocks.take(6)) {
      for (final line in block.lines) {
        final clean = line.text.trim().replaceAll(',', '');
        if (RegExp(r'^\d{2,6}$').hasMatch(clean)) {
          final val = double.tryParse(clean);
          if (val != null && _isValidAmount(val, clean)) {
            return val;
          }
        }
      }
    }

    return null;
  }

  bool _isValidAmount(double val, String raw) {
    if (val <= 0 || val > 50000000) return false;
    if (val >= 2020 && val <= 2035 && !raw.contains('.')) return false;
    if (raw.length >= 10 && !raw.contains('.')) return false;
    return true;
  }

  String? _extractMerchant(String text, List<TextBlock> blocks) {
    final paidToPattern = RegExp(
      r'(?:Paid to|To|Sent to|Transfer to|Payment to|Merchant)\s*[:\-]?\s*([A-Za-z0-9\s&.\-]+)',
      caseSensitive: false,
    );

    final match = paidToPattern.firstMatch(text);
    if (match != null) {
      final candidate = match.group(1)?.trim().split('\n').first.trim();
      if (candidate != null && candidate.isNotEmpty && candidate.length <= 40) {
        return candidate.replaceAll(RegExp(r'\(.*?\)|<.*?>'), '').trim();
      }
    }

    for (final block in blocks.take(4)) {
      final line = block.text.trim();
      final lower = line.toLowerCase();
      if (line.isNotEmpty &&
          !lower.contains('payment') &&
          !lower.contains('success') &&
          !lower.contains('completed') &&
          !lower.contains('gpay') &&
          !lower.contains('google pay') &&
          !lower.contains('phonepe') &&
          !lower.contains('paytm') &&
          !lower.contains('bhim') &&
          !lower.contains('upi') &&
          !lower.contains('transaction') &&
          !RegExp(r'^\d+$').hasMatch(line) &&
          line.length >= 3 &&
          line.length < 40) {
        return line;
      }
    }

    return null;
  }

  String _extractPaymentMethod(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('upi') ||
        lower.contains('gpay') ||
        lower.contains('google pay') ||
        lower.contains('phonepe') ||
        lower.contains('paytm')) {
      return 'UPI';
    }
    if (lower.contains('card') ||
        lower.contains('visa') ||
        lower.contains('mastercard') ||
        lower.contains('rupay') ||
        lower.contains('debit') ||
        lower.contains('credit')) {
      return 'Card';
    }
    if (lower.contains('apple pay')) {
      return 'Apple Pay';
    }
    if (lower.contains('cash')) {
      return 'Cash';
    }
    if (lower.contains('net banking') ||
        lower.contains('neft') ||
        lower.contains('imps')) {
      return 'Bank Transfer';
    }
    return 'UPI';
  }

  String? _inferCategory(String? merchant, String rawText) {
    final combined = '${merchant ?? ''} $rawText'.toLowerCase();

    if (combined.contains('blinkit') ||
        combined.contains('zepto') ||
        combined.contains('instamart') ||
        combined.contains('bigbasket') ||
        combined.contains('dmart') ||
        combined.contains('grocer') ||
        combined.contains('supermarket') ||
        combined.contains('provision') ||
        combined.contains('nature basket') ||
        combined.contains('reliance fresh') ||
        combined.contains('spencer')) {
      return 'Groceries';
    }

    if (combined.contains('swiggy') ||
        combined.contains('zomato') ||
        combined.contains('restaurant') ||
        combined.contains('cafe') ||
        combined.contains('coffee') ||
        combined.contains('tea') ||
        combined.contains('starbucks') ||
        combined.contains('mcdonald') ||
        combined.contains('kfc') ||
        combined.contains('burger') ||
        combined.contains('pizza') ||
        combined.contains('food') ||
        combined.contains('dining') ||
        combined.contains('bakery') ||
        combined.contains('sweets') ||
        combined.contains('dhaba') ||
        combined.contains('hotel')) {
      return 'Dining';
    }

    if (combined.contains('uber') ||
        combined.contains('ola') ||
        combined.contains('rapido') ||
        combined.contains('petrol') ||
        combined.contains('fuel') ||
        combined.contains('shell') ||
        combined.contains('metro') ||
        combined.contains('irctc') ||
        combined.contains('railway') ||
        combined.contains('flight') ||
        combined.contains('airline') ||
        combined.contains('auto') ||
        combined.contains('toll') ||
        combined.contains('fastag') ||
        combined.contains('parking') ||
        combined.contains('cab')) {
      return 'Transportation';
    }

    if (combined.contains('amazon') ||
        combined.contains('flipkart') ||
        combined.contains('myntra') ||
        combined.contains('zara') ||
        combined.contains('h&m') ||
        combined.contains('retail') ||
        combined.contains('store') ||
        combined.contains('mart') ||
        combined.contains('shopping') ||
        combined.contains('mall') ||
        combined.contains('cloth') ||
        combined.contains('fashion')) {
      return 'Shopping';
    }

    if (combined.contains('airtel') ||
        combined.contains('jio') ||
        combined.contains('vi ') ||
        combined.contains('vodafone') ||
        combined.contains('electricity') ||
        combined.contains('bescom') ||
        combined.contains('recharge') ||
        combined.contains('broadband') ||
        combined.contains('wifi') ||
        combined.contains('water') ||
        combined.contains('cylinder') ||
        combined.contains('indane') ||
        combined.contains('bharat gas') ||
        combined.contains('gas')) {
      return 'Utilities';
    }

    if (combined.contains('cinema') ||
        combined.contains('pvr') ||
        combined.contains('inox') ||
        combined.contains('netflix') ||
        combined.contains('spotify') ||
        combined.contains('prime') ||
        combined.contains('hotstar') ||
        combined.contains('bookmyshow') ||
        combined.contains('movie') ||
        combined.contains('theatre') ||
        combined.contains('gaming') ||
        combined.contains('game')) {
      return 'Entertainment';
    }

    if (combined.contains('pharmacy') ||
        combined.contains('medical') ||
        combined.contains('apollo') ||
        combined.contains('medplus') ||
        combined.contains('1mg') ||
        combined.contains('pharma') ||
        combined.contains('chemist') ||
        combined.contains('hospital') ||
        combined.contains('clinic') ||
        combined.contains('doctor') ||
        combined.contains('dr.') ||
        combined.contains('diagnostic') ||
        combined.contains('pathology') ||
        combined.contains('dental') ||
        combined.contains('lab')) {
      return 'Healthcare';
    }

    if (combined.contains('salary') ||
        combined.contains('bonus') ||
        combined.contains('dividend') ||
        combined.contains('interest') ||
        combined.contains('payout')) {
      return 'Salary';
    }

    return null;
  }

  DateTime? _extractDate(String text) {
    final datePattern = RegExp(r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b');
    final match = datePattern.firstMatch(text);
    if (match != null) {
      try {
        final d = int.parse(match.group(1)!);
        final m = int.parse(match.group(2)!);
        var y = int.parse(match.group(3)!);
        if (y < 100) y += 2000;
        return DateTime(y, m, d);
      } catch (_) {}
    }
    return null;
  }
}

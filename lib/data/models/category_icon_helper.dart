import 'package:flutter/material.dart';

class CategoryIconHelper {
  CategoryIconHelper._();

  static const Map<String, IconData> _namedIcons = {
    'Salary': Icons.account_balance_wallet_outlined,
    'Freelance': Icons.laptop_mac_outlined,
    'Cashback': Icons.card_giftcard_outlined,
    'Groceries': Icons.local_grocery_store_outlined,
    'Rent': Icons.home_outlined,
    'Transportation': Icons.directions_bus_outlined,
    'Transport': Icons.directions_bus_outlined,
    'Dining': Icons.restaurant_outlined,
    'Food & Dining': Icons.restaurant_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Utilities': Icons.bolt_outlined,
    'Bills & Utilities': Icons.bolt_outlined,
    'Entertainment': Icons.movie_outlined,
    'Healthcare': Icons.local_hospital_outlined,
    'Health & Medical': Icons.local_hospital_outlined,
    'Money Lent': Icons.arrow_outward_rounded,
    'Money Borrowed': Icons.south_west_rounded,
  };

  static IconData getIcon(String categoryName, [int? codePoint]) {
    if (_namedIcons.containsKey(categoryName)) {
      return _namedIcons[categoryName]!;
    }
    if (codePoint != null) {
      return _fromCodePoint(codePoint);
    }
    return Icons.category_rounded;
  }

  static IconData _fromCodePoint(int codePoint) {
    switch (codePoint) {
      case 0xe047:
        return Icons.account_balance_wallet_outlined;
      case 0xe362:
        return Icons.laptop_mac_outlined;
      case 0xe133:
        return Icons.card_giftcard_outlined;
      case 0xe395:
        return Icons.local_grocery_store_outlined;
      case 0xe318:
        return Icons.home_outlined;
      case 0xe1d5:
        return Icons.directions_bus_outlined;
      case 0xe532:
        return Icons.restaurant_outlined;
      case 0xe59c:
        return Icons.shopping_bag_outlined;
      case 0xe0e9:
        return Icons.bolt_outlined;
      case 0xe3f9:
        return Icons.movie_outlined;
      case 0xe397:
        return Icons.local_hospital_outlined;
      case 0xf05d2:
        return Icons.arrow_outward_rounded;
      case 0xf07d4:
        return Icons.south_west_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

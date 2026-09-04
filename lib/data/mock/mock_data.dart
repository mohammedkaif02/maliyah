import 'package:flutter/material.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';

class MockData {
  MockData._();

  static const catSalary = CategoryModel(
    id: 'cat_salary',
    name: 'Salary',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF2F9E5C),
    type: TxType.income,
  );
  static const catFreelance = CategoryModel(
    id: 'cat_freelance',
    name: 'Freelance',
    icon: Icons.laptop_mac_outlined,
    color: Color(0xFF3D5AFE),
    type: TxType.income,
  );
  static const catCashback = CategoryModel(
    id: 'cat_cashback',
    name: 'Cashback',
    icon: Icons.card_giftcard_outlined,
    color: Color(0xFF1E9BA8),
    type: TxType.income,
  );
  static const catGroceries = CategoryModel(
    id: 'cat_groceries',
    name: 'Groceries',
    icon: Icons.local_grocery_store_outlined,
    color: Color(0xFFCC8A1E),
    type: TxType.expense,
  );
  static const catRent = CategoryModel(
    id: 'cat_rent',
    name: 'Rent',
    icon: Icons.home_outlined,
    color: Color(0xFF9C5FD0),
    type: TxType.expense,
  );
  static const catTransport = CategoryModel(
    id: 'cat_transport',
    name: 'Transportation',
    icon: Icons.directions_bus_outlined,
    color: Color(0xFF5C6BC0),
    type: TxType.expense,
  );
  static const catDining = CategoryModel(
    id: 'cat_dining',
    name: 'Dining',
    icon: Icons.restaurant_outlined,
    color: Color(0xFFD16B3F),
    type: TxType.expense,
  );
  static const catShopping = CategoryModel(
    id: 'cat_shopping',
    name: 'Shopping',
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFF528C63),
    type: TxType.expense,
  );
  static const catUtilities = CategoryModel(
    id: 'cat_utilities',
    name: 'Utilities',
    icon: Icons.bolt_outlined,
    color: Color(0xFF1E9BA8),
    type: TxType.expense,
  );
  static const catEntertainment = CategoryModel(
    id: 'cat_entertainment',
    name: 'Entertainment',
    icon: Icons.movie_outlined,
    color: Color(0xFF3D5AFE),
    type: TxType.expense,
  );
  static const catHealthcare = CategoryModel(
    id: 'cat_healthcare',
    name: 'Healthcare',
    icon: Icons.local_hospital_outlined,
    color: Color(0xFFD64545),
    type: TxType.expense,
  );
  static const catLent = CategoryModel(
    id: 'cat_lent',
    name: 'Money Lent',
    icon: Icons.arrow_outward_rounded,
    color: Color(0xFF0D9488),
    type: TxType.lent,
  );
  static const catBorrowed = CategoryModel(
    id: 'cat_borrowed',
    name: 'Money Borrowed',
    icon: Icons.south_west_rounded,
    color: Color(0xFFE11D48),
    type: TxType.borrowed,
  );

  static List<CategoryModel> get expenseCategories => [
    catGroceries,
    catRent,
    catTransport,
    catDining,
    catShopping,
    catUtilities,
    catEntertainment,
    catHealthcare,
  ];

  static List<CategoryModel> get incomeCategories => [
    catSalary,
    catFreelance,
    catCashback,
  ];

  static List<CategoryModel> get debtCategories => [catLent, catBorrowed];

  static List<CategoryModel> get allCategories => [
    ...incomeCategories,
    ...expenseCategories,
    ...debtCategories,
  ];

  static List<TransactionModel> transactions(DateTime now) => [
    TransactionModel(
      id: 't1',
      title: 'Monthly Salary',
      amount: 68000,
      type: TxType.income,
      category: catSalary,
      date: now.subtract(const Duration(days: 1)),
      paymentMethod: 'Bank Transfer',
    ),
    TransactionModel(
      id: 't2',
      title: 'Whole Foods',
      amount: 2450,
      type: TxType.expense,
      category: catGroceries,
      date: now,
      note: 'Weekly groceries',
      paymentMethod: 'Card',
    ),
    TransactionModel(
      id: 't3',
      title: 'Apartment Rent',
      amount: 18000,
      type: TxType.expense,
      category: catRent,
      date: now.subtract(const Duration(days: 2)),
      paymentMethod: 'Bank Transfer',
      isRecurring: true,
    ),
    TransactionModel(
      id: 't4',
      title: 'Uber rides',
      amount: 640,
      type: TxType.expense,
      category: catTransport,
      date: now.subtract(const Duration(days: 1)),
      paymentMethod: 'UPI',
    ),
    TransactionModel(
      id: 't5',
      title: 'Freelance Payment — Logo design',
      amount: 12000,
      type: TxType.income,
      category: catFreelance,
      date: now.subtract(const Duration(days: 3)),
      paymentMethod: 'UPI',
    ),
    TransactionModel(
      id: 't6',
      title: 'Zomato',
      amount: 540,
      type: TxType.expense,
      category: catDining,
      date: now.subtract(const Duration(days: 1)),
      paymentMethod: 'Card',
    ),
    TransactionModel(
      id: 't7',
      title: 'Electricity Bill',
      amount: 1850,
      type: TxType.expense,
      category: catUtilities,
      date: now.subtract(const Duration(days: 4)),
      paymentMethod: 'UPI',
      isRecurring: true,
    ),
    TransactionModel(
      id: 't8',
      title: 'Netflix Subscription',
      amount: 649,
      type: TxType.expense,
      category: catEntertainment,
      date: now.subtract(const Duration(days: 5)),
      paymentMethod: 'Card',
      isRecurring: true,
    ),
    TransactionModel(
      id: 't9',
      title: 'Amazon — Headphones',
      amount: 3299,
      type: TxType.expense,
      category: catShopping,
      date: now.subtract(const Duration(days: 6)),
      paymentMethod: 'Card',
    ),
    TransactionModel(
      id: 't10',
      title: 'Cashback Reward',
      amount: 150,
      type: TxType.income,
      category: catCashback,
      date: now.subtract(const Duration(days: 6)),
      paymentMethod: 'Card',
    ),
    TransactionModel(
      id: 't11',
      title: 'Pharmacy',
      amount: 480,
      type: TxType.expense,
      category: catHealthcare,
      date: now.subtract(const Duration(days: 8)),
      paymentMethod: 'Card',
    ),
    TransactionModel(
      id: 't12',
      title: 'Big Bazaar',
      amount: 1920,
      type: TxType.expense,
      category: catGroceries,
      date: now.subtract(const Duration(days: 9)),
      paymentMethod: 'Card',
    ),
  ];

  static List<BudgetModel> budgets = const [
    BudgetModel(id: 'b1', category: catGroceries, limit: 6000, spent: 4370),
    BudgetModel(id: 'b2', category: catDining, limit: 3000, spent: 2680),
    BudgetModel(id: 'b3', category: catTransport, limit: 2500, spent: 640),
    BudgetModel(id: 'b4', category: catEntertainment, limit: 1500, spent: 1649),
    BudgetModel(id: 'b5', category: catShopping, limit: 5000, spent: 3299),
  ];

  static const List<double> weeklySpend = [
    1800,
    2200,
    1500,
    3100,
    2600,
    4200,
    3400,
  ];
  static const List<String> weekLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
}

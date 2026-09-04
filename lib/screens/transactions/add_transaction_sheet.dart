import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/finance/finance_bloc.dart';
import '../../blocs/finance/finance_event.dart';
import '../../core/constants/constants.dart';
import '../../core/format.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/receipt_scanner_service.dart';

class AddTransactionSheet extends StatefulWidget {
  final TxType initialType;
  final ScannedReceiptData? initialScannedData;

  const AddTransactionSheet({
    super.key,
    this.initialType = TxType.expense,
    this.initialScannedData,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TxType _selectedType;
  late final TextEditingController amountCtrl;
  late final TextEditingController titleCtrl;
  late final TextEditingController noteCtrl;
  late final TextEditingController personCtrl;

  CategoryModel? selectedCategory;
  DateTime selectedDate = DateTime.now();
  DateTime? debtDueDate;

  // Recurring / EMI
  bool isRecurring = false;
  int recurringDay = DateTime.now().day;
  DateTime? recurringEndDate;
  String recurringTag = 'Subscription';

  String paymentMethod = 'UPI';
  String? receiptPath;
  bool isScanning = false;

  final ReceiptScannerService _scanner = ReceiptScannerService();
  final List<String> paymentMethods = [
    'UPI',
    'Card',
    'Cash',
    'Net Banking',
    'Apple Pay',
  ];
  final List<String> recurringTags = [
    'EMI',
    'Rent',
    'Subscription',
    'Insurance',
    'Loan',
    'Utilities',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    amountCtrl = TextEditingController();
    titleCtrl = TextEditingController();
    noteCtrl = TextEditingController();
    personCtrl = TextEditingController();

    if (widget.initialScannedData != null) {
      _applyScannedData(widget.initialScannedData!);
    }

    amountCtrl.addListener(_rebuild);
    titleCtrl.addListener(_rebuild);
  }

  void _applyScannedData(ScannedReceiptData data) {
    if (data.amount != null) {
      amountCtrl.text = data.amount! == data.amount!.roundToDouble()
          ? data.amount!.toStringAsFixed(0)
          : data.amount!.toStringAsFixed(2);
    }
    if (data.merchant != null && data.merchant!.isNotEmpty) {
      titleCtrl.text = data.merchant!;
    }
    if (data.paymentMethod != null) {
      paymentMethod = data.paymentMethod!;
    }
    if (data.date != null) {
      selectedDate = data.date!;
    }
    if (data.imagePath != null) {
      receiptPath = data.imagePath;
    }
    if (data.suggestedCategory != null) {
      final match = _matchCategory(data.suggestedCategory);
      if (match != null) {
        selectedCategory = match;
        _selectedType = match.type;
      }
    } else if (selectedCategory == null && _selectedType == TxType.expense) {
      selectedCategory = MockData.catGroceries;
    }
  }

  CategoryModel? _matchCategory(String? categoryName) {
    if (categoryName == null || categoryName.trim().isEmpty) return null;
    final lower = categoryName.trim().toLowerCase();

    // 1. Direct name match
    for (final cat in MockData.allCategories) {
      if (cat.name.toLowerCase() == lower) return cat;
    }

    // 2. Alias / Synonym mappings
    if (lower.contains('grocer') ||
        lower.contains('supermarket') ||
        lower.contains('provision')) {
      return MockData.catGroceries;
    }
    if (lower.contains('food') ||
        lower.contains('dining') ||
        lower.contains('restaurant') ||
        lower.contains('cafe')) {
      return MockData.catDining;
    }
    if (lower.contains('transport') ||
        lower.contains('cab') ||
        lower.contains('travel') ||
        lower.contains('auto') ||
        lower.contains('fuel')) {
      return MockData.catTransport;
    }
    if (lower.contains('health') ||
        lower.contains('medic') ||
        lower.contains('pharma') ||
        lower.contains('doctor') ||
        lower.contains('hospital')) {
      return MockData.catHealthcare;
    }
    if (lower.contains('utilit') ||
        lower.contains('bill') ||
        lower.contains('recharge') ||
        lower.contains('electri')) {
      return MockData.catUtilities;
    }
    if (lower.contains('shop') ||
        lower.contains('mall') ||
        lower.contains('fashion') ||
        lower.contains('cloth')) {
      return MockData.catShopping;
    }
    if (lower.contains('entertain') ||
        lower.contains('movie') ||
        lower.contains('cinema')) {
      return MockData.catEntertainment;
    }
    if (lower.contains('salary') || lower.contains('income')) {
      return MockData.catSalary;
    }
    if (lower.contains('rent')) {
      return MockData.catRent;
    }
    return null;
  }

  bool _isPresetSelected(int months) {
    if (recurringEndDate == null) return false;
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + months, recurringDay);
    return recurringEndDate!.year == target.year &&
        recurringEndDate!.month == target.month;
  }

  int _remainingInstallments(DateTime end) {
    final now = DateTime.now();
    final months = (end.year - now.year) * 12 + end.month - now.month;
    return months <= 0 ? 1 : months;
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    amountCtrl.removeListener(_rebuild);
    titleCtrl.removeListener(_rebuild);
    amountCtrl.dispose();
    titleCtrl.dispose();
    noteCtrl.dispose();
    personCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(ImageSource source) async {
    setState(() => isScanning = true);
    final file = await _scanner.pickReceiptImage(source: source);
    if (file != null) {
      final data = await _scanner.parseReceiptImage(file);
      setState(() {
        _applyScannedData(data);
        receiptPath = file.path;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('Receipt details extracted with AI!'),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => isScanning = false);
  }

  void _save() {
    final rawAmount = amountCtrl.text.replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmount);
    if (amount == null || amount <= 0) return;

    final title = titleCtrl.text.trim().isEmpty
        ? (_selectedType == TxType.lent
              ? 'Lent to ${personCtrl.text.trim()}'
              : (_selectedType == TxType.borrowed
                    ? 'Borrowed from ${personCtrl.text.trim()}'
                    : (selectedCategory?.name ?? 'General')))
        : titleCtrl.text.trim();

    final category =
        selectedCategory ??
        (_selectedType == TxType.lent
            ? MockData.catLent
            : (_selectedType == TxType.borrowed
                  ? MockData.catBorrowed
                  : (_selectedType == TxType.income
                        ? MockData.catSalary
                        : MockData.catGroceries)));

    final tx = TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      type: _selectedType,
      category: category,
      date: selectedDate,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      paymentMethod: paymentMethod,
      isRecurring: isRecurring,
      receiptPath: receiptPath,
      debtPerson: personCtrl.text.trim().isEmpty
          ? null
          : personCtrl.text.trim(),
      debtDueDate: debtDueDate,
      isDebtSettled: false,
      recurringDay: isRecurring ? recurringDay : null,
      recurringEndDate: isRecurring ? recurringEndDate : null,
      recurringTag: isRecurring ? recurringTag : null,
    );

    context.read<FinanceBloc>().add(AddTransactionEvent(transaction: tx));
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
  }

  Color get _accentColor {
    switch (_selectedType) {
      case TxType.expense:
        return AppColors.expense;
      case TxType.income:
        return AppColors.income;
      case TxType.lent:
        return const Color(0xFF0D9488);
      case TxType.borrowed:
        return const Color(0xFFE11D48);
    }
  }

  List<CategoryModel> get _currentCategories {
    switch (_selectedType) {
      case TxType.expense:
        return MockData.expenseCategories;
      case TxType.income:
        return MockData.incomeCategories;
      case TxType.lent:
      case TxType.borrowed:
        return MockData.debtCategories;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isValid =
        (double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0) > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: AppSizes.dragHandleWidth,
                  height: AppSizes.dragHandleHeight,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              // Top Bar with AI Scan Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.newEntry, style: AppTypography.h2(scheme.onSurface)),
                  TextButton.icon(
                    onPressed: isScanning
                        ? null
                        : () => _showScanOptions(context),
                    icon: isScanning
                        ? const SizedBox(
                            width: AppSizes.iconXs,
                            height: AppSizes.iconXs,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(AppIcons.aiScan, size: AppSizes.iconMd),
                    label: Text(isScanning ? AppStrings.scanning : AppStrings.aiScan),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      backgroundColor: const Color(
                        0xFF6366F1,
                      ).withValues(alpha: 0.1),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── 4-Way Type Segmented Selector ─────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TypeChip(
                      label: AppStrings.expense,
                      icon: AppIcons.expense,
                      selected: _selectedType == TxType.expense,
                      color: AppColors.expense,
                      onTap: () => setState(() {
                        _selectedType = TxType.expense;
                        selectedCategory = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: AppStrings.income,
                      icon: AppIcons.income,
                      selected: _selectedType == TxType.income,
                      color: AppColors.income,
                      onTap: () => setState(() {
                        _selectedType = TxType.income;
                        selectedCategory = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: AppStrings.moneyLent,
                      icon: AppIcons.lent,
                      selected: _selectedType == TxType.lent,
                      color: const Color(0xFF0D9488),
                      onTap: () => setState(() {
                        _selectedType = TxType.lent;
                        selectedCategory = MockData.catLent;
                      }),
                    ),
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: AppStrings.moneyBorrowed,
                      icon: AppIcons.borrowed,
                      selected: _selectedType == TxType.borrowed,
                      color: const Color(0xFFE11D48),
                      onTap: () => setState(() {
                        _selectedType = TxType.borrowed;
                        selectedCategory = MockData.catBorrowed;
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Amount Input Display ──────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₹',
                      style: AppTypography.h1(
                        _accentColor,
                      ).copyWith(fontSize: 28),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTypography.financialAmountLarge(_accentColor),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: AppTypography.financialAmountLarge(
                            _accentColor.withValues(alpha: 0.35),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Debt Specific Fields (Person & Due Date) ───────────────
              if (_selectedType == TxType.lent ||
                  _selectedType == TxType.borrowed) ...[
                TextField(
                  controller: personCtrl,
                  decoration: InputDecoration(
                    labelText: _selectedType == TxType.lent
                        ? AppStrings.lentTo
                        : AppStrings.borrowedFrom,
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: const Icon(AppIcons.person),
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          debtDueDate ??
                          DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (picked != null) setState(() => debtDueDate = picked);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.calendar, size: AppSizes.iconDefault),
                        const SizedBox(width: 12),
                        Text(
                          debtDueDate == null
                              ? 'Set Reminder / Due Date (Optional)'
                              : 'Return Due Date: ${Fmt.date(debtDueDate!)}',
                          style: AppTypography.bodyMedium(scheme.onSurface),
                        ),
                        const Spacer(),
                        if (debtDueDate != null)
                          IconButton(
                            icon: const Icon(AppIcons.close, size: AppSizes.iconMd),
                            onPressed: () => setState(() => debtDueDate = null),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Title Input ───────────────────────────────────────────
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText:
                      _selectedType == TxType.lent ||
                          _selectedType == TxType.borrowed
                      ? AppStrings.reasonOrNote
                      : AppStrings.descriptionOrTitle,
                  hintText: _selectedType == TxType.income
                      ? 'e.g. Freelance Client'
                      : 'e.g. Swiggy Lunch',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  filled: true,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Category Selector ─────────────────────────────────────
              Text(
                'Category',
                style: AppTypography.label(scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentCategories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final cat = _currentCategories[i];
                    final isSel = selectedCategory?.id == cat.id;
                    return FilterChip(
                      selected: isSel,
                      showCheckmark: false,
                      avatar: Icon(
                        cat.icon,
                        size: 16,
                        color: isSel ? Colors.white : cat.color,
                      ),
                      label: Text(cat.name),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : scheme.onSurface,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      ),
                      selectedColor: _accentColor,
                      backgroundColor: scheme.surfaceContainerHighest,
                      onSelected: (_) => setState(() => selectedCategory = cat),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Payment Method Selector ───────────────────────────────
              // ── Payment Method Selector ───────────────────────────────
              Text(
                AppStrings.paymentMethod,
                style: AppTypography.label(scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: AppSizes.buttonHeightSm,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: paymentMethods.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final m = paymentMethods[i];
                    final isSel = paymentMethod == m;
                    return ChoiceChip(
                      label: Text(m),
                      selected: isSel,
                      showCheckmark: false,
                      selectedColor: _accentColor,
                      backgroundColor: scheme.surfaceContainerHighest,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : scheme.onSurface,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSel
                            ? _accentColor
                            : scheme.outline.withValues(alpha: 0.25),
                      ),
                      onSelected: (_) => setState(() => paymentMethod = m),
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Receipt / Document Attachment Card ────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      receiptPath != null
                          ? AppIcons.checkCircle
                          : AppIcons.receipt,
                      color: receiptPath != null
                          ? AppColors.income
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receiptPath != null
                                ? AppStrings.receiptAttached
                                : AppStrings.attachBillOrInvoice,
                            style: AppTypography.bodyMedium(
                              scheme.onSurface,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            receiptPath != null
                                ? AppStrings.documentSavedLocally
                                : AppStrings.takePhotoOrPick,
                            style: AppTypography.caption(
                              scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (receiptPath != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(receiptPath!),
                          width: AppSizes.receiptThumb,
                          height: AppSizes.receiptThumb,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.close, size: AppSizes.iconMd),
                        onPressed: () => setState(() => receiptPath = null),
                      ),
                    ] else
                      IconButton(
                        icon: const Icon(AppIcons.photoAlternate),
                        onPressed: () => _showScanOptions(context),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Advanced Recurring & EMI Section ───────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        AppStrings.recurringMonthlyEmi,
                        style: AppTypography.bodyMedium(
                          scheme.onSurface,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        AppStrings.recurringSubtitle,
                        style: AppTypography.caption(scheme.onSurfaceVariant),
                      ),
                      value: isRecurring,
                      activeTrackColor: _accentColor,
                      onChanged: (v) => setState(() => isRecurring = v),
                    ),
                    if (isRecurring) ...[
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(AppIcons.eventRepeat, size: AppSizes.iconDefault),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.dayOfMonth,
                            style: AppTypography.bodyMedium(scheme.onSurface),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: recurringDay,
                            items: List.generate(31, (i) => i + 1)
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text('$d${_getOrdinal(d)}'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => recurringDay = v ?? 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Purpose Tag selector
                      Text(
                        'Purpose / Tag',
                        style: AppTypography.label(scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: recurringTags.map((tag) {
                          final isSel = recurringTag == tag;
                          return ChoiceChip(
                            label: Text(tag),
                            selected: isSel,
                            showCheckmark: false,
                            selectedColor: _accentColor,
                            backgroundColor: scheme.surface,
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : scheme.onSurface,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            side: BorderSide(
                              color: isSel
                                  ? _accentColor
                                  : scheme.outline.withValues(alpha: 0.25),
                            ),
                            onSelected: (_) =>
                                setState(() => recurringTag = tag),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // EMI End Date / Maturity Section
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: _accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            recurringTag == 'EMI' || recurringTag == 'Loan'
                                ? 'EMI Last Month / Maturity'
                                : 'Recurring End Date (Optional)',
                            style: AppTypography.label(
                              scheme.onSurfaceVariant,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tenure Quick Presets
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TenurePresetChip(
                            label: 'Ongoing (No End)',
                            isSelected: recurringEndDate == null,
                            accentColor: _accentColor,
                            scheme: scheme,
                            onTap: () =>
                                setState(() => recurringEndDate = null),
                          ),
                          _TenurePresetChip(
                            label: '6 Months',
                            isSelected: _isPresetSelected(6),
                            accentColor: _accentColor,
                            scheme: scheme,
                            onTap: () => setState(() {
                              recurringEndDate = DateTime(
                                DateTime.now().year,
                                DateTime.now().month + 6,
                                recurringDay,
                              );
                            }),
                          ),
                          _TenurePresetChip(
                            label: '12 Months (1 Yr)',
                            isSelected: _isPresetSelected(12),
                            accentColor: _accentColor,
                            scheme: scheme,
                            onTap: () => setState(() {
                              recurringEndDate = DateTime(
                                DateTime.now().year,
                                DateTime.now().month + 12,
                                recurringDay,
                              );
                            }),
                          ),
                          _TenurePresetChip(
                            label: '24 Months (2 Yrs)',
                            isSelected: _isPresetSelected(24),
                            accentColor: _accentColor,
                            scheme: scheme,
                            onTap: () => setState(() {
                              recurringEndDate = DateTime(
                                DateTime.now().year,
                                DateTime.now().month + 24,
                                recurringDay,
                              );
                            }),
                          ),
                          _TenurePresetChip(
                            label: '36 Months (3 Yrs)',
                            isSelected: _isPresetSelected(36),
                            accentColor: _accentColor,
                            scheme: scheme,
                            onTap: () => setState(() {
                              recurringEndDate = DateTime(
                                DateTime.now().year,
                                DateTime.now().month + 36,
                                recurringDay,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Custom Date Picker Card
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                recurringEndDate ??
                                now.add(const Duration(days: 365)),
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365 * 30)),
                            helpText: 'SELECT EMI LAST MONTH / MATURITY',
                          );
                          if (picked != null) {
                            setState(() => recurringEndDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: recurringEndDate != null
                                  ? _accentColor.withValues(alpha: 0.5)
                                  : scheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_calendar_rounded,
                                size: 18,
                                color: recurringEndDate != null
                                    ? _accentColor
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recurringEndDate != null
                                      ? 'Last Month: ${Fmt.date(recurringEndDate!)} (${_remainingInstallments(recurringEndDate!)} installments left)'
                                      : 'Pick Custom Month / End Date',
                                  style:
                                      AppTypography.bodySmall(
                                        recurringEndDate != null
                                            ? scheme.onSurface
                                            : scheme.onSurfaceVariant,
                                      ).copyWith(
                                        fontWeight: recurringEndDate != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                ),
                              ),
                              if (recurringEndDate != null)
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => recurringEndDate = null),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Save CTA ──────────────────────────────────────────────
              SizedBox(
                height: AppSizes.buttonHeight,
                child: FilledButton(
                  onPressed: isValid ? _save : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    AppStrings.saveTransaction,
                    style: AppTypography.button(Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan Receipt / Screenshot',
                style: AppTypography.h3(Theme.of(ctx).colorScheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const Icon(
                  AppIcons.camera,
                  color: Color(0xFF6366F1),
                ),
                title: const Text('Take Photo with Camera'),
                subtitle: const Text(
                  'Scan physical bill or restaurant receipt',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanReceipt(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  AppIcons.gallery,
                  color: Color(0xFF0EA5E9),
                ),
                title: const Text('Upload Payment Screenshot'),
                subtitle: const Text(
                  'Extract from GPay, PhonePe, Paytm, or Apple Pay',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _scanReceipt(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? color : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : scheme.onSurface,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenurePresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _TenurePresetChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? accentColor : scheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : scheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

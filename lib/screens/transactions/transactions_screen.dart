import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/blocs/finance/finance_state.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/format.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/screens/transactions/add_transaction_sheet.dart';
import 'package:maliyah/widgets/common_widgets.dart';
import 'package:maliyah/widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TextEditingController searchCtrl;
  String query = '';
  TxType? typeFilter;

  @override
  void initState() {
    super.initState();
    searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  void _openAddTransactionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(initialType: TxType.expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navTransactions, style: AppTypography.h2(scheme.onSurface)),
        actions: [
          IconButton(
            tooltip: AppStrings.aiScan,
            icon: const Icon(
              AppIcons.aiScan,
              color: Color(0xFF6366F1),
            ),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddTransactionSheet(),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: () => _openAddTransactionSheet(context),
              icon: const Icon(AppIcons.add, size: AppSizes.iconMd),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppSizes.buttonHeightSm),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          final all = state.transactions;
          final selectedType = typeFilter;
          final searchQuery = query.trim().toLowerCase();

          final filtered = all.where((t) {
            final matchesQuery =
                searchQuery.isEmpty ||
                t.title.toLowerCase().contains(searchQuery) ||
                t.category.name.toLowerCase().contains(searchQuery) ||
                (t.note != null && t.note!.toLowerCase().contains(searchQuery));
            final matchesType = selectedType == null || t.type == selectedType;
            return matchesQuery && matchesType;
          }).toList()..sort((a, b) => b.date.compareTo(a.date));

          final grouped = <String, List<TransactionModel>>{};
          for (final t in filtered) {
            grouped.putIfAbsent(Fmt.relativeDay(t.date), () => []).add(t);
          }

          // Period stats for filtered results
          final filteredIncome = filtered
              .where((t) => t.type == TxType.income)
              .fold(0.0, (s, t) => s + t.amount);
          final filteredExpense = filtered
              .where((t) => t.type == TxType.expense)
              .fold(0.0, (s, t) => s + t.amount);

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      onChanged: (v) => setState(() => query = v),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchHint,
                        prefixIcon: const Icon(AppIcons.search, size: AppSizes.iconDefault),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(AppIcons.close, size: AppSizes.iconMd),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setState(() => query = '');
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _PillChip(
                            label: AppStrings.all,
                            selected: selectedType == null,
                            onTap: () => setState(() => typeFilter = null),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _PillChip(
                            label: AppStrings.income,
                            selected: selectedType == TxType.income,
                            color: AppColors.income,
                            icon: AppIcons.income,
                            onTap: () =>
                                setState(() => typeFilter = TxType.income),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _PillChip(
                            label: AppStrings.expense,
                            selected: selectedType == TxType.expense,
                            color: AppColors.expense,
                            icon: AppIcons.expense,
                            onTap: () =>
                                setState(() => typeFilter = TxType.expense),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _PillChip(
                            label: AppStrings.lent,
                            selected: selectedType == TxType.lent,
                            color: const Color(0xFF0D9488),
                            icon: AppIcons.lent,
                            onTap: () =>
                                setState(() => typeFilter = TxType.lent),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _PillChip(
                            label: AppStrings.borrowed,
                            selected: selectedType == TxType.borrowed,
                            color: const Color(0xFFE11D48),
                            icon: AppIcons.borrowed,
                            onTap: () =>
                                setState(() => typeFilter = TxType.borrowed),
                          ),
                          if (searchQuery.isNotEmpty ||
                              selectedType != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _PillChip(
                              label: AppStrings.clear,
                              selected: false,
                              icon: AppIcons.close,
                              color: scheme.onSurfaceVariant,
                              onTap: () {
                                searchCtrl.clear();
                                setState(() {
                                  query = '';
                                  typeFilter = null;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    if (filtered.isNotEmpty)
                      _SummaryStrip(
                        income: filteredIncome,
                        expense: filteredExpense,
                        count: filtered.length,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: EmptyState(
                          icon: searchQuery.isNotEmpty
                              ? AppIcons.searchOff
                              : AppIcons.transactionsOutlined,
                          title: searchQuery.isNotEmpty
                              ? AppStrings.noResultsFound
                              : AppStrings.noTransactionsYet,
                          message: searchQuery.isNotEmpty
                              ? AppStrings.tryDifferentSearch
                              : AppStrings.noTransactionsSubtitle,
                          ctaLabel: searchQuery.isEmpty
                              ? AppStrings.addTransaction
                              : null,
                          onCta: searchQuery.isEmpty
                              ? () => _openAddTransactionSheet(context)
                              : null,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.colossal,
                        ),
                        children: grouped.entries.expand((entry) sync* {
                          yield _DateGroupHeader(label: entry.key);

                          yield Container(
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.5),
                              ),
                              boxShadow: isDark
                                  ? AppShadows.cardDark
                                  : AppShadows.card,
                            ),
                            child: Column(
                              children: entry.value.asMap().entries.map((e) {
                                final tx = e.value;
                                final isLast = e.key == entry.value.length - 1;
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      child: Dismissible(
                                        key: Key(tx.id),
                                        direction: DismissDirection.endToStart,
                                        background: _DeleteBackground(),
                                        confirmDismiss: (_) async {
                                          return await _showDeleteConfirm(
                                            context,
                                            tx,
                                          );
                                        },
                                        onDismissed: (_) {
                                          context.read<FinanceBloc>().add(
                                            DeleteTransactionEvent(
                                              transactionId: tx.id,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Deleted "${tx.title}"',
                                              ),
                                              action: SnackBarAction(
                                                label: 'Undo',
                                                onPressed: () {
                                                  context.read<FinanceBloc>().add(
                                                    const UndoDeleteTransactionEvent(),
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                        child: TransactionTile(
                                          tx: tx,
                                          onTap: () =>
                                              _showTxDetail(context, tx),
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Divider(
                                        height: 1,
                                        indent:
                                            AppSpacing.md + 46 + AppSpacing.md,
                                        color: scheme.outline.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirm(
    BuildContext context,
    TransactionModel t,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteTransactionPrompt),
        content: Text(
          'Are you sure you want to delete "${t.title}"?\nThis action can be undone via the undo notification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.delete, style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showTxDetail(BuildContext context, TransactionModel t) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = t.type == TxType.income;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(t.category.icon, color: t.category.color, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(t.title, style: AppTypography.h3(scheme.onSurface)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Amount',
              value: (isIncome ? '+' : '−') + Fmt.currency(t.amount),
              valueColor: amountColor,
            ),
            _DetailRow(label: 'Category', value: t.category.name),
            _DetailRow(label: 'Date', value: Fmt.dayMonthYear(t.date)),
            _DetailRow(label: 'Time', value: Fmt.time(t.date)),
            _DetailRow(label: 'Payment', value: t.paymentMethod),
            _DetailRow(label: 'Recurring', value: t.isRecurring ? 'Yes' : 'No'),
            if (t.note != null && t.note!.isNotEmpty)
              _DetailRow(label: 'Note', value: t.note!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FinanceBloc>().add(
                DeleteTransactionEvent(transactionId: t.id),
              );
            },
            child: Text(AppStrings.delete, style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final double income;
  final double expense;
  final int count;
  final bool isDark;

  const _SummaryStrip({
    required this.income,
    required this.expense,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StripStat(
              label: 'Results',
              value: '$count',
              color: scheme.onSurface,
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: scheme.outline.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _StripStat(
              label: 'Income',
              value: Fmt.currencyRounded(income),
              color: AppColors.income,
            ),
          ),
          Container(
            height: 24,
            width: 1,
            color: scheme.outline.withValues(alpha: 0.4),
          ),
          Expanded(
            child: _StripStat(
              label: 'Expenses',
              value: Fmt.currencyRounded(expense),
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _StripStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StripStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: AppTypography.financialAmountSmall(color)),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption(
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = color ?? scheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.4)
                : scheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? activeColor : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.label(
                selected ? activeColor : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  final String label;
  const _DateGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.xs),
      child: Row(
        children: [
          Text(label, style: AppTypography.labelLarge(scheme.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              color: scheme.outline.withValues(alpha: 0.4),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(AppStrings.delete, style: AppTypography.label(AppColors.expense)),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            AppIcons.deleteOutline,
            color: AppColors.expense,
            size: AppSizes.iconDefault,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall(scheme.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySmall(
                valueColor ?? scheme.onSurface,
              ).copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/blocs/finance/finance_state.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/format.dart';
import 'package:maliyah/data/mock/mock_data.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/widgets/budget_card.dart';
import 'package:maliyah/widgets/common_widgets.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysRemaining = _calculateDaysRemaining();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navBudgets, style: AppTypography.h2(scheme.onSurface)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: () => _openCreateBudgetSheet(context),
              icon: const Icon(AppIcons.add, size: AppSizes.iconMd),
              label: const Text(AppStrings.newBudget),
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
          final budgets = state.budgets;
          final totalLimit = budgets.fold(0.0, (s, b) => s + b.limit);
          final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
          final overallPct = totalLimit == 0
              ? 0.0
              : (totalSpent / totalLimit).clamp(0.0, 1.4);
          final isOverall = overallPct >= 1.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.colossal,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isOverall
                        ? AppColors.budgetExceeded.withValues(alpha: 0.3)
                        : scheme.outline.withValues(alpha: 0.5),
                  ),
                  boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.thisMonthsBudget,
                                style: AppTypography.bodyMedium(
                                  scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        Fmt.currencyRounded(totalSpent),
                                        style:
                                            AppTypography.financialAmountMedium(
                                              scheme.onSurface,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      '/ ${Fmt.currencyRounded(totalLimit)}',
                                      style: AppTypography.bodyMedium(
                                        scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: overallPct.clamp(0.0, 1.0),
                                strokeWidth: 5.5,
                                backgroundColor: scheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  isOverall
                                      ? AppColors.budgetExceeded
                                      : AppColors.budgetOk,
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                              Text(
                                '${(overallPct * 100).clamp(0, 999).toStringAsFixed(0)}%',
                                style: AppTypography.caption(scheme.onSurface)
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    _OverallProgressBar(
                      value: overallPct.clamp(0.0, 1.0),
                      isExceeded: isOverall,
                      scheme: scheme,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        _BudgetStatChip(
                          label: AppStrings.categories,
                          value: '${budgets.length}',
                          icon: AppIcons.categoryOutlined,
                          scheme: scheme,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _BudgetStatChip(
                          label: AppStrings.daysLeft,
                          value: '$daysRemaining',
                          icon: AppIcons.calendarOutlined,
                          scheme: scheme,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _BudgetStatChip(
                          label: AppStrings.remaining,
                          value: Fmt.currencyRounded(
                            (totalLimit - totalSpent).clamp(0, double.infinity),
                          ),
                          icon: AppIcons.savings,
                          scheme: scheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              SectionHeader(
                title: AppStrings.categoryBudgets,
                actionLabel: budgets.isNotEmpty
                    ? '${budgets.length} active'
                    : null,
              ),

              if (budgets.isEmpty)
                EmptyState(
                  icon: AppIcons.budgetsOutlined,
                  title: AppStrings.noBudgetsSet,
                  message: AppStrings.noBudgetsSubtitle,
                  ctaLabel: AppStrings.createBudget,
                  onCta: () => _openCreateBudgetSheet(context),
                )
              else
                ...budgets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: BudgetCard(
                      budget: b,
                      onTap: () => _showBudgetOptions(context, b),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  int _calculateDaysRemaining() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return (lastDay - now.day).clamp(0, 31);
  }

  void _openCreateBudgetSheet(BuildContext context, [BudgetModel? editBudget]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateBudgetModal(existing: editBudget),
    );
  }

  void _showBudgetOptions(BuildContext context, BudgetModel budget) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: budget.category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(
                budget.category.icon,
                color: budget.category.color,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                '${budget.category.name} Budget',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DetailRow(AppStrings.monthlyLimitPlain, Fmt.currency(budget.limit)),
            _DetailRow(AppStrings.spentSoFar, Fmt.currency(budget.spent)),
            _DetailRow(
              AppStrings.remaining,
              budget.isExceeded
                  ? '${Fmt.currency(budget.spent - budget.limit)} over'
                  : Fmt.currency(budget.remaining),
            ),
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
              _openCreateBudgetSheet(context, budget);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FinanceBloc>().add(
                DeleteBudgetEvent(budgetId: budget.id),
              );
            },
            child: Text(AppStrings.delete, style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _OverallProgressBar extends StatelessWidget {
  final double value;
  final bool isExceeded;
  final ColorScheme scheme;

  const _OverallProgressBar({
    required this.value,
    required this.isExceeded,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isExceeded
        ? AppColors.expenseGradient
        : AppColors.incomeGradient;
    return LayoutBuilder(
      builder: (_, c) => Container(
        height: 10,
        width: c.maxWidth,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme scheme;

  const _BudgetStatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTypography.label(scheme.onSurface),
                maxLines: 1,
              ),
            ),
            Text(
              label,
              style: AppTypography.caption(scheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall(scheme.onSurfaceVariant)),
          Text(
            value,
            style: AppTypography.bodySmall(
              scheme.onSurface,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CreateBudgetModal extends StatefulWidget {
  final BudgetModel? existing;
  const _CreateBudgetModal({this.existing});

  @override
  State<_CreateBudgetModal> createState() => _CreateBudgetModalState();
}

class _CreateBudgetModalState extends State<_CreateBudgetModal> {
  late final TextEditingController amountCtrl;
  CategoryModel? selectedCategory;

  @override
  void initState() {
    super.initState();
    amountCtrl = TextEditingController(
      text: widget.existing?.limit.toStringAsFixed(0) ?? '',
    );
    selectedCategory =
        widget.existing?.category ?? MockData.expenseCategories.first;
    amountCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isEdit = widget.existing != null;

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
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: AppSizes.dragHandleWidth,
                  height: AppSizes.dragHandleHeight,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Text(
                isEdit ? AppStrings.editBudget : AppStrings.createBudget,
                style: AppTypography.h2(scheme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(
                AppStrings.selectCategory,
                style: AppTypography.label(scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: MockData.expenseCategories.map((c) {
                  final sel = selectedCategory?.id == c.id;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? c.color : c.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: sel
                              ? c.color
                              : c.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.icon,
                            size: AppSizes.iconXs,
                            color: sel ? Colors.white : c.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.name,
                            style: AppTypography.label(
                              sel ? Colors.white : c.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.xl),

              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: AppStrings.monthlyLimit,
                  hintText: 'e.g. 5000',
                  prefixIcon: Icon(
                    AppIcons.walletOutlined,
                    size: AppSizes.iconDefault,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              ElevatedButton(
                onPressed: _canSave() ? _save : null,
                child: Text(isEdit ? AppStrings.saveChanges : AppStrings.createBudget),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSave() {
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', ''));
    return amount != null && amount > 0 && selectedCategory != null;
  }

  void _save() {
    final amount = double.parse(amountCtrl.text.replaceAll(',', ''));
    context.read<FinanceBloc>().add(
      AddBudgetEvent(
        budget: BudgetModel(
          id:
              widget.existing?.id ??
              'b_${DateTime.now().millisecondsSinceEpoch}',
          category: selectedCategory!,
          limit: amount,
          spent: widget.existing?.spent ?? 0.0,
        ),
      ),
    );
    Navigator.pop(context);
  }
}

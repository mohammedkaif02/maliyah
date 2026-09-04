import 'package:flutter/material.dart';
import 'package:maliyah/core/format.dart';
import 'package:maliyah/core/theme/app_colors.dart';
import 'package:maliyah/core/theme/app_spacing.dart';
import 'package:maliyah/core/theme/app_typography.dart';
import 'package:maliyah/data/models/budget_model.dart';

class BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback? onTap;

  const BudgetCard({super.key, required this.budget, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = budget.isExceeded
        ? AppColors.budgetExceeded
        : budget.isNearLimit
        ? AppColors.budgetWarning
        : AppColors.budgetOk;

    final statusBg = budget.isExceeded
        ? (isDark ? AppColors.expenseDark : AppColors.budgetExceededBg)
        : budget.isNearLimit
        ? (isDark ? const Color(0xFF3D2A0A) : AppColors.budgetWarningBg)
        : (isDark ? AppColors.incomeDark : AppColors.budgetOkBg);

    final progressGradient = budget.isExceeded
        ? AppColors.expenseGradient
        : budget.isNearLimit
        ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
        : AppColors.incomeGradient;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashColor: scheme.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: budget.isExceeded
                  ? AppColors.budgetExceeded.withValues(alpha: 0.3)
                  : scheme.outline.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: budget.category.color.withValues(
                        alpha: isDark ? 0.15 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: budget.category.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(
                      budget.category.icon,
                      size: 20,
                      color: budget.category.color,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category.name,
                          style: AppTypography.title(scheme.onSurface),
                        ),
                        Text(
                          budget.period,
                          style: AppTypography.caption(scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      budget.isExceeded
                          ? 'Over budget'
                          : '${(budget.percentUsed * 100).toStringAsFixed(0)}% used',
                      style: AppTypography.label(statusColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              _GradientProgressBar(
                value: budget.percentUsed.clamp(0.0, 1.0),
                gradient: progressGradient,
                backgroundColor: scheme.surfaceContainerHighest,
              ),

              const SizedBox(height: AppSpacing.sm),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: AppTypography.caption(scheme.onSurfaceVariant),
                      ),
                      Text(
                        Fmt.currencyRounded(budget.spent),
                        style: AppTypography.financialAmountSmall(
                          scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        budget.isExceeded ? 'Over by' : 'Remaining',
                        style: AppTypography.caption(scheme.onSurfaceVariant),
                      ),
                      Text(
                        budget.isExceeded
                            ? Fmt.currencyRounded(budget.spent - budget.limit)
                            : Fmt.currencyRounded(budget.remaining),
                        style: AppTypography.financialAmountSmall(statusColor),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Limit',
                        style: AppTypography.caption(scheme.onSurfaceVariant),
                      ),
                      Text(
                        Fmt.currencyRounded(budget.limit),
                        style: AppTypography.financialAmountSmall(
                          scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (budget.isExceeded) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.budgetExceeded.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.budgetExceeded.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 13,
                        color: AppColors.budgetExceeded,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'You have exceeded your ${budget.category.name} budget for this month.',
                          style: AppTypography.caption(
                            AppColors.budgetExceeded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientProgressBar extends StatelessWidget {
  final double value;
  final Gradient gradient;
  final Color backgroundColor;

  const _GradientProgressBar({
    required this.value,
    required this.gradient,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 9,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: backgroundColor,
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
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

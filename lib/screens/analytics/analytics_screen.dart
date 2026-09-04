import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/finance/finance_state.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/format.dart';
import 'package:maliyah/data/mock/mock_data.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/widgets/common_widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navAnalytics, style: AppTypography.h2(scheme.onSurface)),
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          final period = state.selectedPeriod;
          final filteredTx = state.filteredPeriodTransactions;

          final periodIncome = filteredTx
              .where((t) => t.type == TxType.income)
              .fold(0.0, (sum, t) => sum + t.amount);
          final periodExpense = filteredTx
              .where((t) => t.type == TxType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);
          final netSavings = periodIncome - periodExpense;

          final categoryMap = <String, double>{};
          for (final t in filteredTx.where((t) => t.type == TxType.expense)) {
            categoryMap[t.category.name] =
                (categoryMap[t.category.name] ?? 0) + t.amount;
          }

          final sortedCategories = categoryMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final trendValues = state.periodSpendTrend;
          final trendLabels = state.periodLabels;
          final maxTrend = trendValues.fold(0.0, (m, v) => v > m ? v : m);
          final chartYMax = maxTrend <= 0 ? 1000.0 : maxTrend * 1.2;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.colossal,
            ),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: AnalyticsPeriod.values.map((p) {
                    final selected = p == period;
                    final label = p.name[0].toUpperCase() + p.name.substring(1);
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _PeriodChip(
                        label: label,
                        selected: selected,
                        onTap: () {
                          context.read<FinanceBloc>().add(
                            ChangeAnalyticsPeriodEvent(period: p),
                          );
                        },
                        scheme: scheme,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: AppStrings.income,
                      value: Fmt.currencyRounded(periodIncome),
                      color: AppColors.income,
                      icon: AppIcons.income,
                      bgColor: isDark
                          ? AppColors.incomeDark
                          : AppColors.incomeLight,
                      scheme: scheme,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MetricCard(
                      label: AppStrings.expenses,
                      value: Fmt.currencyRounded(periodExpense),
                      color: AppColors.expense,
                      icon: AppIcons.expense,
                      bgColor: isDark
                          ? AppColors.expenseDark
                          : AppColors.expenseLight,
                      scheme: scheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _NetSavingsCard(
                netSavings: netSavings,
                savingsRate: periodIncome > 0
                    ? (netSavings / periodIncome).clamp(0.0, 1.0)
                    : 0.0,
                scheme: scheme,
                isDark: isDark,
              ),

              const SizedBox(height: AppSpacing.xxl),

              SectionHeader(title: '${AppStrings.spendingTrend} — ${_periodTitle(period)}'),
              Container(
                height: 230,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.5),
                  ),
                  boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
                ),
                child: BarChart(
                  BarChartData(
                    maxY: chartYMax,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: chartYMax / 4,
                      getDrawingHorizontalLine: (val) => FlLine(
                        color: scheme.outline.withValues(alpha: 0.2),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: chartYMax / 4,
                          getTitlesWidget: (val, _) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              _compactAmount(val),
                              style: AppTypography.caption(
                                scheme.onSurfaceVariant,
                              ).copyWith(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (val, _) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= trendLabels.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                trendLabels[idx],
                                style: AppTypography.caption(
                                  scheme.onSurfaceVariant,
                                ).copyWith(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    barGroups: trendValues.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: period == AnalyticsPeriod.yearly ? 14 : 20,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: chartYMax,
                              color: scheme.surfaceContainerHighest.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              SectionHeader(title: AppStrings.categoryBreakdown),
              if (sortedCategories.isEmpty)
                const EmptyState(
                  icon: AppIcons.budgetsOutlined,
                  title: AppStrings.noExpenseData,
                  message: AppStrings.noExpenseSubtitle,
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.5),
                    ),
                    boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            sections: sortedCategories.map((entry) {
                              final cat = MockData.expenseCategories.firstWhere(
                                (c) => c.name == entry.key,
                                orElse: () => MockData.expenseCategories.last,
                              );
                              return PieChartSectionData(
                                color: cat.color,
                                value: entry.value,
                                title: '',
                                radius: 24,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedCategories.take(4).map((entry) {
                            final cat = MockData.expenseCategories.firstWhere(
                              (c) => c.name == entry.key,
                              orElse: () => MockData.expenseCategories.last,
                            );
                            final pct = periodExpense > 0
                                ? (entry.value / periodExpense * 100)
                                      .toStringAsFixed(0)
                                : '0';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: cat.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: AppTypography.caption(
                                        scheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$pct%',
                                    style: AppTypography.caption(
                                      scheme.onSurfaceVariant,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                ...sortedCategories.map((entry) {
                  final cat = MockData.expenseCategories.firstWhere(
                    (c) => c.name == entry.key,
                    orElse: () => MockData.expenseCategories.last,
                  );
                  final pct = periodExpense > 0
                      ? (entry.value / periodExpense).clamp(0.0, 1.0)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _CategorySpendRow(
                      category: cat,
                      amount: entry.value,
                      fraction: pct,
                      scheme: scheme,
                      isDark: isDark,
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  String _periodTitle(AnalyticsPeriod p) => switch (p) {
    AnalyticsPeriod.daily => AppStrings.today,
    AnalyticsPeriod.weekly => AppStrings.thisWeek,
    AnalyticsPeriod.monthly => AppStrings.thisMonth,
    AnalyticsPeriod.yearly => AppStrings.thisYear,
  };

  String _compactAmount(double val) {
    if (val >= 100000) return '₹${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '₹${(val / 1000).toStringAsFixed(0)}k';
    return '₹${val.toStringAsFixed(0)}';
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label(
            selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final Color bgColor;
  final ColorScheme scheme;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.bgColor,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTypography.caption(color)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.financialAmountMedium(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetSavingsCard extends StatelessWidget {
  final double netSavings;
  final double savingsRate;
  final ColorScheme scheme;
  final bool isDark;

  const _NetSavingsCard({
    required this.netSavings,
    required this.savingsRate,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = netSavings >= 0;
    final color = isPositive ? AppColors.income : AppColors.expense;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.netSavings,
                style: AppTypography.bodySmall(scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                '${isPositive ? '+' : ''}${Fmt.currencyRounded(netSavings)}',
                style: AppTypography.financialAmount(color),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '${(savingsRate * 100).toStringAsFixed(0)}% saved',
              style: AppTypography.label(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySpendRow extends StatelessWidget {
  final CategoryModel category;
  final double amount;
  final double fraction;
  final ColorScheme scheme;
  final bool isDark;

  const _CategorySpendRow({
    required this.category,
    required this.amount,
    required this.fraction,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(category.icon, color: category.color, size: 17),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.name,
                  style: AppTypography.title(scheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.currencyRounded(amount),
                    style: AppTypography.financialAmountSmall(scheme.onSurface),
                  ),
                  Text(
                    '${(fraction * 100).toStringAsFixed(0)}%',
                    style: AppTypography.caption(scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(category.color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

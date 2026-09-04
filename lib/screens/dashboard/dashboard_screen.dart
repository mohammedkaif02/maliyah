import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/blocs/finance/finance_state.dart';
import 'package:maliyah/blocs/theme/theme_cubit.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/format.dart';
import 'package:maliyah/data/models/budget_model.dart';
import 'package:maliyah/data/models/transaction_model.dart';
import 'package:maliyah/widgets/common_widgets.dart';
import 'package:maliyah/widgets/transaction_tile.dart';
import 'package:maliyah/screens/transactions/add_transaction_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _balanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<FinanceBloc, FinanceState>(
          builder: (context, state) {
            if (state.status == FinanceStatus.initial ||
                state.status == FinanceStatus.loading) {
              return _DashboardSkeleton(isDark: isDark);
            }

            final s = state;

            return RefreshIndicator(
              onRefresh: () async {
                final authState = context.read<AuthCubit>().state;
                final userId = authState is Authenticated
                    ? authState.user.id
                    : 'guest';
                context.read<FinanceBloc>().add(
                  LoadFinanceDataEvent(userId: userId),
                );
                await Future.delayed(const Duration(milliseconds: 600));
              },
              color: scheme.primary,
              backgroundColor: scheme.surface,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.colossal,
                ),
                children: [
                  _buildHeader(context, scheme),
                  const SizedBox(height: AppSpacing.lg),

                  if (s.isOffline) ...[
                    const OfflineBanner(),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  _buildBalanceCard(context, s, isDark),
                  const SizedBox(height: AppSpacing.lg),

                  _buildQuickActions(context, scheme),
                  const SizedBox(height: AppSpacing.xxl),

                  if (s.totalUnsettledLent > 0 ||
                      s.totalUnsettledBorrowed > 0) ...[
                    _buildDebtsOverviewCard(context, s, scheme, isDark),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  _buildInsightCard(context, s, scheme),
                  const SizedBox(height: AppSpacing.xxl),

                  SectionHeader(
                    title: AppStrings.budgetOverview,
                    actionLabel: AppStrings.seeAll,
                    onAction: () => widget.onNavigateTab?.call(2),
                  ),
                  if (s.budgets.isEmpty)
                    const EmptyState(
                      icon: AppIcons.budgetsOutlined,
                      title: AppStrings.noBudgetsSet,
                      message: AppStrings.noBudgetsSubtitle,
                    )
                  else
                    ...s.budgets
                        .take(3)
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _CompactBudgetRow(budget: b),
                          ),
                        ),

                  const SizedBox(height: AppSpacing.xxl),

                  SectionHeader(
                    title: AppStrings.recentTransactions,
                    actionLabel: AppStrings.seeAll,
                    onAction: () => widget.onNavigateTab?.call(1),
                  ),
                  if (s.recentTransactions.isEmpty)
                    const EmptyState(
                      icon: AppIcons.transactionsOutlined,
                      title: AppStrings.noTransactionsYet,
                      message: AppStrings.noTransactionsSubtitle,
                    )
                  else
                    Container(
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
                        children: s.recentTransactions.asMap().entries.map((e) {
                          final isLast =
                              e.key == s.recentTransactions.length - 1;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                child: TransactionTile(tx: e.value),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: AppSpacing.lg + 46 + AppSpacing.md,
                                  color: scheme.outline.withValues(alpha: 0.4),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greetingMessage(),
              style: AppTypography.bodyMedium(scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Text('${AppStrings.appName} 👋', style: AppTypography.h2(scheme.onSurface)),
          ],
        ),
        Row(
          children: [
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (ctx, mode) {
                final dark = mode == ThemeMode.dark;
                return _HeaderIconButton(
                  icon: Icon(
                    dark ? AppIcons.lightMode : AppIcons.darkMode,
                    size: AppSizes.appBarIconSize,
                  ),
                  onTap: () => ctx.read<ThemeCubit>().toggle(),
                  scheme: scheme,
                );
              },
            ),
            const SizedBox(width: AppSpacing.xs),
            _HeaderIconButton(
              icon: const Icon(AppIcons.notifications, size: AppSizes.appBarIconSize),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.noAlerts),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              scheme: scheme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, FinanceState s, bool isDark) {
    final balance = s.balance;
    final income = s.totalIncome;
    final expense = s.totalExpense;
    final savingsRate = s.savingsRate;
    final gradient = isDark
        ? AppColors.balanceGradientDark
        : AppColors.balanceGradientLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withValues(
              alpha: isDark ? 0.12 : 0.3,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.totalBalance,
                style: AppTypography.bodyMedium(
                  Colors.white.withValues(alpha: 0.75),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _balanceVisible
                        ? AppIcons.visibilityOn
                        : AppIcons.visibilityOff,
                    key: ValueKey(_balanceVisible),
                    color: Colors.white.withValues(alpha: 0.75),
                    size: AppSizes.iconDefault,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _balanceVisible ? Fmt.currency(balance) : AppStrings.hiddenBalance,
              key: ValueKey(_balanceVisible),
              style: AppTypography.financialAmountLarge(Colors.white),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          Row(
            children: [
              _BalanceStat(
                icon: AppIcons.income,
                label: AppStrings.income,
                value: _balanceVisible ? Fmt.currencyRounded(income) : AppStrings.hiddenAmount,
                accent: const Color(0xFF6EE7C7),
              ),
              const SizedBox(width: AppSpacing.xl),
              _BalanceStat(
                icon: AppIcons.expense,
                label: AppStrings.expenses,
                value: _balanceVisible ? Fmt.currencyRounded(expense) : AppStrings.hiddenAmount,
                accent: const Color(0xFFFF8FA3),
              ),
              const Spacer(),
              _SavingsRingIndicator(
                savingsRate: savingsRate,
                visible: _balanceVisible,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme scheme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: AppIcons.expense,
            label: AppStrings.expense,
            gradient: AppColors.expenseGradient,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) =>
                  const AddTransactionSheet(initialType: TxType.expense),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _QuickActionButton(
            icon: AppIcons.income,
            label: AppStrings.income,
            gradient: AppColors.incomeGradient,
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) =>
                  const AddTransactionSheet(initialType: TxType.income),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _QuickActionButton(
            icon: AppIcons.aiScan,
            label: AppStrings.aiScan,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const AddTransactionSheet(),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.swap_horiz_rounded,
            label: AppStrings.debts,
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
            ),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) =>
                  const AddTransactionSheet(initialType: TxType.lent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtsOverviewCard(
    BuildContext context,
    FinanceState s,
    ColorScheme scheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    AppIcons.handshake,
                    size: 20,
                    color: Color(0xFF0D9488),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.debtsAndKhata,
                    style: AppTypography.title(scheme.onSurface),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => widget.onNavigateTab?.call(1),
                child: const Text(AppStrings.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You will get (Lent)',
                        style: AppTypography.caption(const Color(0xFF0D9488)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Fmt.currencyRounded(s.totalUnsettledLent),
                        style: AppTypography.title(
                          const Color(0xFF0D9488),
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You owe (Borrowed)',
                        style: AppTypography.caption(const Color(0xFFE11D48)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Fmt.currencyRounded(s.totalUnsettledBorrowed),
                        style: AppTypography.title(
                          const Color(0xFFE11D48),
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    FinanceState s,
    ColorScheme scheme,
  ) {
    final exceeded = s.budgets
        .where((b) => b.isExceeded || b.isNearLimit)
        .firstOrNull;
    final pct = (s.savingsRate * 100).toStringAsFixed(0);
    String message;
    Color accent;
    IconData iconData;

    if (exceeded != null) {
      if (exceeded.isExceeded) {
        message =
            '${exceeded.category.name} budget of ${Fmt.currencyRounded(exceeded.limit)} exceeded!';
        accent = AppColors.budgetExceeded;
        iconData = Icons.warning_amber_rounded;
      } else {
        message =
            '${exceeded.category.name} spending is close to this month\'s limit.';
        accent = AppColors.budgetWarning;
        iconData = Icons.trending_up_rounded;
      }
    } else {
      message =
          'Great job! Your savings rate is $pct% of your total income this period.';
      accent = AppColors.info;
      iconData = Icons.auto_graph_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 18, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Insight', style: AppTypography.label(accent)),
                const SizedBox(height: 3),
                Text(message, style: AppTypography.bodySmall(scheme.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.goodMorning;
    if (hour < 17) return AppStrings.goodAfternoon;
    return AppStrings.goodEvening;
  }
}

class _HeaderIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        child: IconTheme(
          data: IconThemeData(color: scheme.onSurface, size: 20),
          child: icon,
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _BalanceStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: accent),
        ),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.caption(Colors.white.withValues(alpha: 0.7)),
            ),
            Text(
              value,
              style: AppTypography.financialAmountSmall(Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}

class _SavingsRingIndicator extends StatelessWidget {
  final double savingsRate;
  final bool visible;

  const _SavingsRingIndicator({
    required this.savingsRate,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    final pct = visible ? (savingsRate * 100).toStringAsFixed(0) : '?';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: savingsRate.clamp(0.0, 1.0),
                strokeWidth: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF6EE7C7)),
                strokeCap: StrokeCap.round,
              ),
              Text(
                '$pct%',
                style: AppTypography.caption(
                  Colors.white,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Saved',
          style: AppTypography.caption(Colors.white.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
            boxShadow: Theme.of(context).brightness == Brightness.dark
                ? AppShadows.cardDark
                : AppShadows.card,
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.bodySmall(
                  scheme.onSurface,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactBudgetRow extends StatelessWidget {
  final BudgetModel budget;
  const _CompactBudgetRow({required this.budget});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = budget.isExceeded
        ? AppColors.budgetExceeded
        : budget.isNearLimit
        ? AppColors.budgetWarning
        : AppColors.budgetOk;

    final barGradient = budget.isExceeded
        ? AppColors.expenseGradient
        : budget.isNearLimit
        ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
        : AppColors.incomeGradient;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: budget.category.color.withValues(
                alpha: isDark ? 0.15 : 0.12,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              budget.category.icon,
              size: 18,
              color: budget.category.color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget.category.name,
                      style: AppTypography.title(scheme.onSurface),
                    ),
                    Text(
                      '${(budget.percentUsed * 100).toStringAsFixed(0)}%',
                      style: AppTypography.label(statusColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _MinimalProgressBar(
                  value: budget.percentUsed.clamp(0.0, 1.0),
                  gradient: barGradient,
                  bg: scheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 4),
                Text(
                  '${Fmt.currencyRounded(budget.spent)} of ${Fmt.currencyRounded(budget.limit)}',
                  style: AppTypography.caption(scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalProgressBar extends StatelessWidget {
  final double value;
  final Gradient gradient;
  final Color bg;

  const _MinimalProgressBar({
    required this.value,
    required this.gradient,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        return Container(
          height: 6,
          width: c.maxWidth,
          decoration: BoxDecoration(
            color: bg,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  final bool isDark;
  const _DashboardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        SkeletonBlock(height: 24, width: 140, radius: AppRadius.pill),
        SizedBox(height: AppSpacing.xs),
        SkeletonBlock(height: 32, width: 200, radius: AppRadius.sm),
        SizedBox(height: AppSpacing.xl),
        SkeletonBlock(height: 170, radius: AppRadius.xl),
        SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: SkeletonBlock(height: 72, radius: AppRadius.md)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: SkeletonBlock(height: 72, radius: AppRadius.md)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: SkeletonBlock(height: 72, radius: AppRadius.md)),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        SkeletonBlock(height: 60, radius: AppRadius.md),
        SizedBox(height: AppSpacing.xl),
        SkeletonBlock(height: 24, width: 160, radius: AppRadius.pill),
        SizedBox(height: AppSpacing.md),
        SkeletonBlock(height: 72, radius: AppRadius.md),
        SizedBox(height: AppSpacing.sm),
        SkeletonBlock(height: 72, radius: AppRadius.md),
      ],
    );
  }
}

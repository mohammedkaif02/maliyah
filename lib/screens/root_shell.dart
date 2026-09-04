import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/blocs/theme/theme_cubit.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/format.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/data/mock/mock_data.dart';
import 'package:maliyah/screens/analytics/analytics_screen.dart';
import 'package:maliyah/screens/budgets/budgets_screen.dart';
import 'package:maliyah/screens/dashboard/dashboard_screen.dart';
import 'package:maliyah/screens/transactions/transactions_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with TickerProviderStateMixin {
  int _index = 0;
  late final List<AnimationController> _iconControllers;

  static const _navItems = [
    _NavItem(
      icon: AppIcons.navHomeOutlined,
      activeIcon: AppIcons.navHomeFilled,
      label: AppStrings.navHome,
    ),
    _NavItem(
      icon: AppIcons.navTransactionsOutlined,
      activeIcon: AppIcons.navTransactionsFilled,
      label: AppStrings.navTransactions,
    ),
    _NavItem(
      icon: AppIcons.navBudgetsOutlined,
      activeIcon: AppIcons.navBudgetsFilled,
      label: AppStrings.navBudgets,
    ),
    _NavItem(
      icon: AppIcons.navAnalyticsOutlined,
      activeIcon: AppIcons.navAnalyticsFilled,
      label: AppStrings.navAnalytics,
    ),
    _NavItem(
      icon: AppIcons.navMoreOutlined,
      activeIcon: AppIcons.navMoreFilled,
      label: AppStrings.navMore,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setTab(int i) {
    if (i < 0 || i >= _navItems.length || i == _index) return;
    HapticFeedback.selectionClick();
    _iconControllers[_index].reverse();
    _iconControllers[i].forward();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashboardScreen(onNavigateTab: _setTab),
      const TransactionsScreen(),
      const BudgetsScreen(),
      const AnalyticsScreen(),
      _MoreScreen(onNavigateTab: _setTab),
    ];

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: _BottomNavBar(
          items: _navItems,
          currentIndex: _index,
          onTap: _setTab,
          iconControllers: _iconControllers,
          scheme: scheme,
          isDark: isDark,
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _BottomNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AnimationController> iconControllers;
  final ColorScheme scheme;
  final bool isDark;

  const _BottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.iconControllers,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outline.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.navBarHeight,
          child: Row(
            children: items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              final isSelected = idx == currentIndex;

              return Expanded(
                child: _NavBarItemWidget(
                  item: item,
                  isSelected: isSelected,
                  controller: iconControllers[idx],
                  onTap: () => onTap(idx),
                  scheme: scheme,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavBarItemWidget extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final AnimationController controller;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _NavBarItemWidget({
    required this.item,
    required this.isSelected,
    required this.controller,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: AppSizes.navBarIndicatorHeight,
              width: isSelected ? AppSizes.navBarIndicatorWidth : 0,
              margin: const EdgeInsets.only(bottom: 5),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                color: color,
                size: AppSizes.iconLg,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;
  const _MoreScreen({this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.navMore, style: AppTypography.h2(scheme.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.colossal,
        ),
        children: [
          _ProfileCard(scheme: scheme, isDark: isDark),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(label: AppStrings.preferences, scheme: scheme),
          const SizedBox(height: AppSpacing.xs),
          _GroupedTiles(
            scheme: scheme,
            isDark: isDark,
            children: [
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) {
                  final darkMode = themeMode == ThemeMode.dark;
                  return _ToggleTile(
                    icon: darkMode
                        ? AppIcons.lightMode
                        : AppIcons.darkMode,
                    iconColor: darkMode
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF6366F1),
                    label: AppStrings.darkMode,
                    subtitle: AppStrings.darkModeSubtitle,
                    value: darkMode,
                    onChanged: (_) => context.read<ThemeCubit>().toggle(),
                    scheme: scheme,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _SectionLabel(label: AppStrings.finance, scheme: scheme),
          const SizedBox(height: AppSpacing.xs),
          _GroupedTiles(
            scheme: scheme,
            isDark: isDark,
            children: [
              _MoreTile(
                icon: AppIcons.repeat,
                iconColor: scheme.primary,
                label: AppStrings.recurringTransactions,
                subtitle: AppStrings.recurringSubtitleNav,
                onTap: () => _showRecurringSheet(context),
                scheme: scheme,
              ),
              _Divider(scheme: scheme),
              _MoreTile(
                icon: AppIcons.category,
                iconColor: const Color(0xFF8B5CF6),
                label: AppStrings.categories,
                subtitle: AppStrings.categoriesSubtitleNav,
                onTap: () => _showCategoriesSheet(context),
                scheme: scheme,
              ),
              _Divider(scheme: scheme),
              _MoreTile(
                icon: AppIcons.backup,
                iconColor: const Color(0xFF0EA5E9),
                label: AppStrings.exportSummary,
                subtitle: AppStrings.exportSummarySubtitle,
                onTap: () {
                  final state = context.read<FinanceBloc>().state;
                  final totalTx = state.transactions.length;
                  final bal = Fmt.currency(state.balance);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Snapshot of $totalTx transactions — Balance: $bal',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                scheme: scheme,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _SectionLabel(label: AppStrings.appSection, scheme: scheme),
          const SizedBox(height: AppSpacing.xs),
          _GroupedTiles(
            scheme: scheme,
            isDark: isDark,
            children: [
              _MoreTile(
                icon: AppIcons.reset,
                iconColor: AppColors.warning,
                label: AppStrings.resetDataTitle,
                subtitle: AppStrings.resetDataSubtitle,
                onTap: () => _confirmResetData(context),
                scheme: scheme,
              ),
              _Divider(scheme: scheme),
              _MoreTile(
                icon: AppIcons.about,
                iconColor: scheme.onSurfaceVariant,
                label: AppStrings.aboutAppTitle,
                subtitle: AppStrings.aboutAppSubtitle,
                onTap: () => _showAboutDialog(context),
                scheme: scheme,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _SectionLabel(label: AppStrings.session, scheme: scheme),
          const SizedBox(height: AppSpacing.xs),
          _GroupedTiles(
            scheme: scheme,
            isDark: isDark,
            children: [
              _MoreTile(
                icon: AppIcons.signOut,
                iconColor: AppColors.warning,
                label: AppStrings.signOut,
                subtitle: AppStrings.signOutConfirmation,
                onTap: () => _confirmSignOut(context),
                scheme: scheme,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          Center(
            child: Text(
              '${AppStrings.appName} ${AppStrings.appTagline}',
              style: AppTypography.caption(scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecurringSheet(BuildContext context) {
    final state = context.read<FinanceBloc>().state;
    final recurring = state.transactions.where((t) => t.isRecurring).toList();
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              AppStrings.recurringTransactions,
              style: AppTypography.h2(scheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (recurring.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    AppStrings.noRecurring,
                    style: AppTypography.bodyMedium(scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...recurring.map(
                (t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: AppSizes.buttonHeightSm,
                    height: AppSizes.buttonHeightSm,
                    decoration: BoxDecoration(
                      color: t.category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      t.category.icon,
                      color: t.category.color,
                      size: AppSizes.iconDefault,
                    ),
                  ),
                  title: Text(
                    t.title,
                    style: AppTypography.title(scheme.onSurface),
                  ),
                  subtitle: Text(
                    '${t.recurringTag ?? t.category.name} · ${t.recurringDay != null ? 'Repeats on ${t.recurringDay}th' : 'Monthly'}${t.recurringEndDate != null ? ' · Ends ${Fmt.date(t.recurringEndDate!)}' : ''}',
                    style: AppTypography.caption(scheme.onSurfaceVariant),
                  ),
                  trailing: Text(
                    Fmt.currency(t.amount),
                    style: AppTypography.financialAmount(scheme.onSurface),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCategoriesSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(AppStrings.categories, style: AppTypography.h2(scheme.onSurface)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.expense,
                style: AppTypography.label(scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: MockData.expenseCategories
                    .map(
                      (c) => Chip(
                        avatar: Icon(c.icon, size: AppSizes.iconXs, color: c.color),
                        label: Text(c.name),
                        backgroundColor: c.color.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: c.color.withValues(alpha: 0.25),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.income,
                style: AppTypography.label(scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: MockData.incomeCategories
                    .map(
                      (c) => Chip(
                        avatar: Icon(c.icon, size: AppSizes.iconXs, color: c.color),
                        label: Text(c.name),
                        backgroundColor: c.color.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: c.color.withValues(alpha: 0.25),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.signOutPrompt),
        content: const Text(AppStrings.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: Text(AppStrings.signOut, style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.resetPrompt),
        content: const Text(AppStrings.resetConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<FinanceBloc>().add(const ResetAllDataEvent());
            },
            child: Text(AppStrings.reset, style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: AppSizes.receiptThumb,
              height: AppSizes.receiptThumb,
              decoration: BoxDecoration(
                gradient: AppColors.balanceGradientLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                AppIcons.wallet,
                color: Colors.white,
                size: AppSizes.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(AppStrings.appName),
          ],
        ),
        content: const Text(AppStrings.aboutAppDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;

  const _ProfileCard({required this.scheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.balanceGradientDark
                : AppColors.balanceGradientLight,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.lightPrimary.withValues(
                  alpha: isDark ? 0.1 : 0.25,
                ),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              final isLoggedIn = authState is Authenticated;
              final initials = isLoggedIn ? authState.initials : 'G';
              final displayName = isLoggedIn ? authState.displayName : AppStrings.guest;
              final subtitle = isLoggedIn
                  ? authState.email
                  : AppStrings.guestSubtitle;

              return Row(
                children: [
                  Container(
                    width: AppSizes.avatarLg,
                    height: AppSizes.avatarLg,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: AppTypography.h3(Colors.white),
                        ),
                        Text(
                          subtitle,
                          style: AppTypography.bodySmall(
                            Colors.white.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    AppIcons.chevronRight,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: AppSizes.iconXl,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme scheme;

  const _SectionLabel({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _GroupedTiles extends StatelessWidget {
  final List<Widget> children;
  final ColorScheme scheme;
  final bool isDark;

  const _GroupedTiles({
    required this.children,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.5)),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
      ),
      child: Column(children: children),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _MoreTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 4,
      ),
      leading: Container(
        width: AppSizes.avatarSm,
        height: AppSizes.avatarSm,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: iconColor, size: AppSizes.iconDefault),
      ),
      title: Text(label, style: AppTypography.title(scheme.onSurface)),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption(scheme.onSurfaceVariant),
      ),
      trailing: Icon(
        AppIcons.chevronRight,
        color: scheme.onSurfaceVariant,
        size: AppSizes.iconDefault,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme scheme;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 4,
      ),
      leading: Container(
        width: AppSizes.avatarSm,
        height: AppSizes.avatarSm,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: iconColor, size: AppSizes.iconDefault),
      ),
      title: Text(label, style: AppTypography.title(scheme.onSurface)),
      subtitle: Text(
        subtitle,
        style: AppTypography.caption(scheme.onSurfaceVariant),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: scheme.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => scheme.outline.withValues(alpha: 0.35),
        ),
        thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Icon(
              AppIcons.darkMode,
              color: Color(0xFF0D9488),
              size: AppSizes.iconXs,
            );
          }
          return const Icon(
            AppIcons.lightMode,
            color: Color(0xFFF59E0B),
            size: AppSizes.iconXs,
          );
        }),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme scheme;
  const _Divider({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.lg + AppSizes.avatarSm + AppSpacing.md,
      color: scheme.outline.withValues(alpha: 0.35),
    );
  }
}

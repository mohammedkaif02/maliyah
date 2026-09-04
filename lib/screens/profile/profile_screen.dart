import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/routing/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => curr is Unauthenticated || curr is AuthError,
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (r) => false,
          );
        } else if (state is AuthError && state.operation == 'deleteAccount') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      },
      builder: (context, state) {
        final isAuth = state is Authenticated;
        final displayName = isAuth ? state.displayName : AppStrings.guest;
        final email = isAuth ? state.email : '';
        final initials = isAuth ? state.initials : 'G';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _ProfileSliverAppBar(
                isDark: isDark,
                displayName: displayName,
                email: email,
                initials: initials,
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    _SectionHeader(label: 'Account', scheme: scheme),
                    _ProfileTileGroup(
                      scheme: scheme,
                      isDark: isDark,
                      tiles: [
                        _ProfileTile(
                          icon: AppIcons.personOutlined,
                          iconColor: scheme.primary,
                          title: 'Edit Profile',
                          subtitle: 'Change your display name',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.editProfile,
                          ),
                          scheme: scheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _SectionHeader(label: 'Security', scheme: scheme),
                    _ProfileTileGroup(
                      scheme: scheme,
                      isDark: isDark,
                      tiles: [
                        _ProfileTile(
                          icon: AppIcons.lock,
                          iconColor: const Color(0xFF6366F1),
                          title: 'Change Password',
                          subtitle: 'Update your login password',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.changePassword,
                          ),
                          scheme: scheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _SectionHeader(label: AppStrings.session, scheme: scheme),
                    _ProfileTileGroup(
                      scheme: scheme,
                      isDark: isDark,
                      tiles: [
                        _ProfileTile(
                          icon: AppIcons.signOut,
                          iconColor: AppColors.warning,
                          title: AppStrings.signOut,
                          subtitle: 'Return to the login screen',
                          onTap: () => _confirmSignOut(context),
                          scheme: scheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _SectionHeader(label: 'Danger Zone', scheme: scheme),
                    _ProfileTileGroup(
                      scheme: scheme,
                      isDark: isDark,
                      tiles: [
                        _ProfileTile(
                          icon: AppIcons.deleteForever,
                          iconColor: AppColors.expense,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove your account',
                          titleColor: AppColors.expense,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.deleteAccount,
                          ),
                          scheme: scheme,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.colossal),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.signOutPrompt),
        content: const Text(AppStrings.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().signOut();
            },
            child: Text(AppStrings.signOut, style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

class _ProfileSliverAppBar extends StatelessWidget {
  final bool isDark;
  final String displayName;
  final String email;
  final String initials;

  const _ProfileSliverAppBar({
    required this.isDark,
    required this.displayName,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: isDark
          ? const Color(0xFF064E3B)
          : AppColors.lightPrimary,
      leading: IconButton(
        icon: const Icon(AppIcons.back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.balanceGradientDark
                : AppColors.balanceGradientLight,
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  displayName,
                  style: TextStyle(
                    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ColorScheme scheme;

  const _SectionHeader({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.label(scheme.onSurfaceVariant),
      ),
    );
  }
}

class _ProfileTileGroup extends StatelessWidget {
  final List<Widget> tiles;
  final ColorScheme scheme;
  final bool isDark;

  const _ProfileTileGroup({
    required this.tiles,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
      ),
      child: Column(children: tiles),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final ColorScheme scheme;

  const _ProfileTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.scheme,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium(
                        titleColor ?? scheme.onSurface,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.caption(scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

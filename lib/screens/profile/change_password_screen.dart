import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/core/theme/app_colors.dart';
import 'package:maliyah/core/theme/app_spacing.dart';
import 'package:maliyah/core/theme/app_typography.dart';
import 'package:maliyah/screens/auth/auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  double _strength = 0;

  @override
  void initState() {
    super.initState();
    _newPassCtrl.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final p = _newPassCtrl.text;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.25;
    if (p.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?]'))) s += 0.25;
    setState(() => _strength = s);
  }

  Color get _strengthColor {
    if (_strength <= 0.25) return AppColors.expense;
    if (_strength <= 0.5) return AppColors.warning;
    if (_strength <= 0.75) return AppColors.info;
    return AppColors.income;
  }

  String get _strengthLabel {
    if (_strength <= 0) return '';
    if (_strength <= 0.25) return 'Weak';
    if (_strength <= 0.5) return 'Fair';
    if (_strength <= 0.75) return 'Good';
    return 'Strong';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthCubit>().updatePassword(
      currentPassword: _currentPassCtrl.text,
      newPassword: _newPassCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) =>
          curr is AuthActionSuccess || curr is AuthError,
      listener: (context, state) {
        if (state is AuthActionSuccess) {
          _currentPassCtrl.clear();
          _newPassCtrl.clear();
          _confirmPassCtrl.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.income,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppSpacing.lg),
            ),
          );
          Navigator.pop(context);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.expense,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(AppSpacing.lg),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Change Password',
              style: AppTypography.h3(scheme.onSurface),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: Color(0xFF6366F1),
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  Text(
                    'Update Password',
                    style: AppTypography.h2(scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enter your current password, then choose a strong new password.',
                    style: AppTypography.bodyMedium(
                      scheme.onSurfaceVariant,
                    ).copyWith(height: 1.5),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  AuthField(
                    fieldKey: 'current_password',
                    controller: _currentPassCtrl,
                    label: 'Current Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureCurrent,
                    textInputAction: TextInputAction.next,
                    suffixIcon: _VisibilityToggle(
                      obscure: _obscureCurrent,
                      onTap: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      scheme: scheme,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your current password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  AuthField(
                    fieldKey: 'new_password',
                    controller: _newPassCtrl,
                    label: 'New Password',
                    icon: Icons.lock_reset_rounded,
                    obscureText: _obscureNew,
                    textInputAction: TextInputAction.next,
                    suffixIcon: _VisibilityToggle(
                      obscure: _obscureNew,
                      onTap: () => setState(() => _obscureNew = !_obscureNew),
                      scheme: scheme,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a new password';
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (v == _currentPassCtrl.text) {
                        return 'New password must differ from current';
                      }
                      return null;
                    },
                  ),

                  if (_newPassCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _StrengthBar(
                      strength: _strength,
                      color: _strengthColor,
                      label: _strengthLabel,
                      scheme: scheme,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  AuthField(
                    fieldKey: 'confirm_new_password',
                    controller: _confirmPassCtrl,
                    label: 'Confirm New Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    suffixIcon: _VisibilityToggle(
                      obscure: _obscureConfirm,
                      onTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      scheme: scheme,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Confirm your new password';
                      }
                      if (v != _newPassCtrl.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  GradientButton(
                    buttonKey: 'change_password_btn',
                    label: 'Update Password',
                    isLoading: isLoading,
                    onPressed: _submit,
                    gradient: isDark
                        ? AppColors.balanceGradientDark
                        : AppColors.balanceGradientLight,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: scheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Use a mix of uppercase, lowercase, numbers, and symbols for the strongest password.',
                            style: AppTypography.caption(
                              scheme.primary,
                            ).copyWith(height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _VisibilityToggle({
    required this.obscure,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
      onPressed: onTap,
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final double strength;
  final Color color;
  final String label;
  final ColorScheme scheme;

  const _StrengthBar({
    required this.strength,
    required this.color,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = strength > i * 0.25;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: filled
                      ? color
                      : scheme.outline.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption(
            color,
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

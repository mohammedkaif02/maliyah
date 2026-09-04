import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/core/utils/validators.dart';
import 'package:maliyah/screens/auth/auth_widgets.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  String? _termsError;
  double _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_updateStrength);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _updateStrength() {
    final p = _passCtrl.text;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.contains(RegExp(r'[A-Z]'))) s += 0.25;
    if (p.contains(RegExp(r'[0-9]'))) s += 0.25;
    if (p.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?]'))) s += 0.25;
    setState(() => _passwordStrength = s);
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.25) return AppColors.expense;
    if (_passwordStrength <= 0.5) return AppColors.warning;
    if (_passwordStrength <= 0.75) return AppColors.info;
    return AppColors.income;
  }

  String get _strengthLabel {
    if (_passwordStrength <= 0) return '';
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong';
  }

  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(
        () => _termsError = 'Please agree to the Terms & Privacy Policy',
      );
      return;
    }
    setState(() => _termsError = null);
    await context.read<AuthCubit>().signUp(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => curr is Authenticated || curr is AuthError,
      listener: (context, state) {
        if (state is Authenticated) {
          context.read<FinanceBloc>().add(
            LoadFinanceDataEvent(userId: state.user.id),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.app,
            (r) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMsg = state is AuthError && state.operation == 'signUp'
            ? state.message
            : _termsError;

        return Scaffold(
          backgroundColor: scheme.surface,
          body: Column(
            children: [
              _SignupHeroHeader(isDark: isDark),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xxl),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.colossal,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.createAccount,
                            style: AppTypography.h2(scheme.onSurface),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppStrings.signUpToStart,
                            style: AppTypography.bodyMedium(
                              scheme.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxxl),

                          AuthField(
                            fieldKey: 'signup_name',
                            controller: _nameCtrl,
                            label: AppStrings.fullName,
                            icon: AppIcons.personOutlined,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            validator: Validators.nameValidator,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          AuthField(
                            fieldKey: 'signup_email',
                            controller: _emailCtrl,
                            label: AppStrings.emailAddress,
                            icon: AppIcons.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.emailValidator,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          AuthField(
                            fieldKey: 'signup_password',
                            controller: _passCtrl,
                            label: AppStrings.password,
                            icon: AppIcons.lock,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.next,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? AppIcons.visibilityOn
                                    : AppIcons.visibilityOff,
                                size: AppSizes.appBarIconSize,
                                color: scheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return AppStrings.passwordRequired;
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          if (_passCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _PasswordStrengthBar(
                              strength: _passwordStrength,
                              color: _strengthColor,
                              label: _strengthLabel,
                              scheme: scheme,
                            ),
                          ],

                          const SizedBox(height: AppSpacing.lg),

                          AuthField(
                            fieldKey: 'signup_confirm_password',
                            controller: _confirmCtrl,
                            label: AppStrings.confirmPassword,
                            icon: AppIcons.lock,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _createAccount(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? AppIcons.visibilityOn
                                    : AppIcons.visibilityOff,
                                size: AppSizes.appBarIconSize,
                                color: scheme.onSurfaceVariant,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _passCtrl.text) {
                                return AppStrings.passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          _TermsCheckbox(
                            value: _agreedToTerms,
                            onChanged: (v) =>
                                setState(() => _agreedToTerms = v ?? false),
                            scheme: scheme,
                          ),

                          if (errorMsg != null) ...[
                            const SizedBox(height: AppSpacing.lg),
                            AuthErrorBanner(message: errorMsg),
                          ],

                          const SizedBox(height: AppSpacing.xl),

                          GradientButton(
                            buttonKey: 'create_account_btn',
                            label: AppStrings.createAccount,
                            isLoading: isLoading,
                            onPressed: _createAccount,
                            gradient: isDark
                                ? AppColors.balanceGradientDark
                                : AppColors.balanceGradientLight,
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          Center(
                            child: TextButton(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  );
                                }
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: AppStrings.alreadyHaveAccount,
                                  style: AppTypography.bodySmall(
                                    scheme.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: AppStrings.signIn,
                                      style: AppTypography.bodySmall(
                                        scheme.primary,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SignupHeroHeader extends StatelessWidget {
  final bool isDark;
  const _SignupHeroHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.balanceGradientDark
            : AppColors.balanceGradientLight,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
              ),
            ),
            Center(
              child: Text(
                AppStrings.appName,
                style: TextStyle(
                  fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final double strength;
  final Color color;
  final String label;
  final ColorScheme scheme;

  const _PasswordStrengthBar({
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

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final ColorScheme scheme;

  const _TermsCheckbox({
    required this.value,
    required this.onChanged,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? scheme.primary : Colors.transparent,
              border: Border.all(
                color: value ? scheme.primary : scheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: AppTypography.bodySmall(scheme.onSurfaceVariant),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTypography.bodySmall(
                      scheme.primary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: AppTypography.bodySmall(scheme.onSurfaceVariant),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTypography.bodySmall(
                      scheme.primary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

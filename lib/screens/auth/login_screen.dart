import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/blocs/finance/finance_bloc.dart';
import 'package:maliyah/blocs/finance/finance_event.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/core/utils/validators.dart';
import 'package:maliyah/screens/auth/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthCubit>().signIn(
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
        final errorMsg = state is AuthError && state.operation == 'signIn'
            ? state.message
            : null;

        return Scaffold(
          backgroundColor: scheme.surface,
          body: Column(
            children: [
              _LoginHeroHeader(isDark: isDark),

              Expanded(
                child: Container(
                  width: double.infinity,
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
                            AppStrings.welcomeBack,
                            style: AppTypography.h2(scheme.onSurface),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            AppStrings.signInToContinue,
                            style: AppTypography.bodyMedium(
                              scheme.onSurfaceVariant,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxxl),

                          AuthField(
                            fieldKey: 'login_email',
                            controller: _emailCtrl,
                            label: AppStrings.emailAddress,
                            icon: AppIcons.email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.emailValidator,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          AuthField(
                            fieldKey: 'login_password',
                            controller: _passCtrl,
                            label: AppStrings.password,
                            icon: AppIcons.lock,
                            obscureText: _obscurePass,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
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
                              return null;
                            },
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.forgotPassword,
                              ),
                              child: Text(
                                AppStrings.forgotPassword,
                                style: AppTypography.bodySmall(
                                  scheme.primary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          if (errorMsg != null) ...[
                            AuthErrorBanner(message: errorMsg),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          GradientButton(
                            buttonKey: 'sign_in_btn',
                            label: AppStrings.signIn,
                            isLoading: isLoading,
                            onPressed: _signIn,
                            gradient: isDark
                                ? AppColors.balanceGradientDark
                                : AppColors.balanceGradientLight,
                          ),

                          const SizedBox(height: AppSpacing.xl),
                          const OrDivider(),
                          const SizedBox(height: AppSpacing.xl),

                          GoogleSignInButton(
                            buttonKey: 'google_signin_btn',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    AppStrings.googleSignInComingSoon,
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          Center(
                            child: TextButton(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                   Navigator.pop(context);
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.signup,
                                  );
                                }
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: AppStrings.dontHaveAccount,
                                  style: AppTypography.bodySmall(
                                    scheme.onSurfaceVariant,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: AppStrings.signUp,
                                      style: AppTypography.bodySmall(
                                        scheme.primary,
                                      ).copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Center(
                            child: TextButton(
                              onPressed: () {
                                context.read<FinanceBloc>().add(
                                  const LoadFinanceDataEvent(userId: 'guest'),
                                );
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.app,
                                  (r) => false,
                                );
                              },
                              child: Text(
                                AppStrings.continueAsGuest,
                                style: AppTypography.bodySmall(
                                  scheme.onSurfaceVariant,
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

class _LoginHeroHeader extends StatelessWidget {
  final bool isDark;
  const _LoginHeroHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppSizes.heroHeaderHeight,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.balanceGradientDark
            : AppColors.balanceGradientLight,
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppSizes.avatarXl,
                height: AppSizes.avatarXl,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: SvgPicture.asset(
                  AppIcons.logoSvg,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

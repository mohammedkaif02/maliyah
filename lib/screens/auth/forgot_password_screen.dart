import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/core/constants/constants.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/core/utils/validators.dart';
import 'package:maliyah/screens/auth/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthCubit>().sendPasswordResetEmail(
      _emailCtrl.text.trim(),
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
          setState(() => _sent = true);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMsg =
            state is AuthError && state.operation == 'resetPassword'
            ? state.message
            : null;

        return Scaffold(
          backgroundColor: scheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(AppIcons.back, color: scheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.colossal,
              ),
              child: _sent
                  ? _SuccessView(scheme: scheme)
                  : _FormView(
                      formKey: _formKey,
                      emailCtrl: _emailCtrl,
                      errorMessage: errorMsg,
                      isLoading: isLoading,
                      isDark: isDark,
                      scheme: scheme,
                      onSubmit: _submit,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final String? errorMessage;
  final bool isLoading;
  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.errorMessage,
    required this.isLoading,
    required this.isDark,
    required this.scheme,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.passwordReset,
              color: scheme.primary,
              size: AppSizes.iconHuge,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(AppStrings.forgotPassword, style: AppTypography.h1(scheme.onSurface)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.forgotPasswordSubtitle,
            style: AppTypography.bodyMedium(
              scheme.onSurfaceVariant,
            ).copyWith(height: 1.6),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          AuthField(
            fieldKey: 'forgot_email',
            controller: emailCtrl,
            label: AppStrings.emailAddress,
            icon: AppIcons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            validator: Validators.emailValidator,
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AuthErrorBanner(message: errorMessage!),
          ],

          const SizedBox(height: AppSpacing.xl),

          GradientButton(
            buttonKey: 'send_reset_btn',
            label: AppStrings.sendResetLink,
            isLoading: isLoading,
            onPressed: onSubmit,
            gradient: isDark
                ? AppColors.balanceGradientDark
                : AppColors.balanceGradientLight,
          ),

          const SizedBox(height: AppSpacing.xxl),

          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text.rich(
                TextSpan(
                  text: AppStrings.rememberPassword,
                  style: AppTypography.bodySmall(scheme.onSurfaceVariant),
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
    );
  }
}

class _SuccessView extends StatelessWidget {
  final ColorScheme scheme;
  const _SuccessView({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            color: AppColors.incomeLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            AppIcons.emailSent,
            color: AppColors.income,
            size: 50,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          AppStrings.checkYourEmail,
          style: AppTypography.h2(scheme.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppStrings.checkYourEmailDesc,
          style: AppTypography.bodyMedium(
            scheme.onSurfaceVariant,
          ).copyWith(height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),
        SizedBox(
          width: double.infinity,
          height: AppSizes.buttonHeight,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (r) => false,
            ),
            child: Text(
              AppStrings.backToSignIn,
              style: AppTypography.button(scheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/core/utils/validators.dart';
import 'package:maliyah/core/theme/app_colors.dart';
import 'package:maliyah/core/theme/app_spacing.dart';
import 'package:maliyah/core/theme/app_typography.dart';
import 'package:maliyah/screens/auth/auth_widgets.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _understood = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    if (state is Authenticated) {
      _emailCtrl.text = state.email;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_understood) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm you understand this action is permanent.',
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await context.read<AuthCubit>().deleteAccount(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => curr is Unauthenticated || curr is AuthError,
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (r) => false,
          );
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
              'Delete Account',
              style: AppTypography.h3(AppColors.expense),
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
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.expense,
                              size: 22,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'This cannot be undone',
                              style: AppTypography.bodyMedium(
                                AppColors.expense,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ..._consequences.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 14,
                                    color: AppColors.expense,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    c,
                                    style: AppTypography.caption(
                                      AppColors.expense,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  Text(
                    'Confirm Your Identity',
                    style: AppTypography.h3(scheme.onSurface),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'For security, re-enter your credentials to proceed.',
                    style: AppTypography.bodyMedium(scheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  AuthField(
                    fieldKey: 'delete_email',
                    controller: _emailCtrl,
                    label: 'Email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.emailValidator,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  AuthField(
                    fieldKey: 'delete_password',
                    controller: _passCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _deleteAccount(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: scheme.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  _AcknowledgeCheckbox(
                    value: _understood,
                    onChanged: (v) => setState(() => _understood = v ?? false),
                    scheme: scheme,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: isLoading
                            ? AppColors.expense.withValues(alpha: 0.5)
                            : AppColors.expense,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: AppColors.expense.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: isLoading ? null : _deleteAccount,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Delete My Account',
                                style: AppTypography.button(Colors.white),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel — Keep My Account',
                        style: AppTypography.bodySmall(
                          scheme.primary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
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

  static const _consequences = [
    'Your account and login credentials will be permanently deleted.',
    'All your transaction history and budget data will be lost.',
    'This action cannot be reversed or recovered.',
  ];
}

class _AcknowledgeCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final ColorScheme scheme;

  const _AcknowledgeCheckbox({
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
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: value ? AppColors.expense : Colors.transparent,
              border: Border.all(
                color: value ? AppColors.expense : scheme.outline,
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
            child: Text(
              'I understand that deleting my account is permanent and all my data will be lost forever.',
              style: AppTypography.bodySmall(
                scheme.onSurface,
              ).copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

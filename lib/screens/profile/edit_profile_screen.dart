import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/core/theme/app_colors.dart';
import 'package:maliyah/core/theme/app_spacing.dart';
import 'package:maliyah/core/theme/app_typography.dart';
import 'package:maliyah/screens/auth/auth_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthCubit>().state;
    final currentName = state is Authenticated ? state.user.name : '';
    _nameCtrl = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthCubit>().updateDisplayName(_nameCtrl.text.trim());
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
              'Edit Profile',
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
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final initials = state is Authenticated
                            ? state.initials
                            : 'G';
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? AppColors.balanceGradientDark
                                : AppColors.balanceGradientLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: AppTypography.h1(Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  Text(
                    'Full Name',
                    style: AppTypography.label(scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  AuthField(
                    fieldKey: 'edit_name',
                    controller: _nameCtrl,
                    label: 'Display name',
                    icon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This name appears on your profile and in the app.',
                    style: AppTypography.caption(scheme.onSurfaceVariant),
                  ),

                  const SizedBox(height: AppSpacing.xxxl),

                  GradientButton(
                    buttonKey: 'save_name_btn',
                    label: 'Save Changes',
                    isLoading: isLoading,
                    onPressed: _save,
                    gradient: isDark
                        ? AppColors.balanceGradientDark
                        : AppColors.balanceGradientLight,
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

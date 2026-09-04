import 'package:flutter/material.dart';
import 'package:maliyah/core/constants/constants.dart';

class AuthField extends StatelessWidget {
  final String fieldKey;
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const AuthField({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: BorderSide(
        color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.4),
      ),
    );

    return TextFormField(
      key: Key(fieldKey),
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTypography.bodyMedium(scheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMedium(scheme.onSurfaceVariant),
        prefixIcon: Icon(icon, size: AppSizes.iconDefault, color: scheme.onSurfaceVariant),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : scheme.surfaceContainerLowest,
        border: baseBorder,
        enabledBorder: baseBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.expense, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.expense, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String buttonKey;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  final LinearGradient gradient;

  const GradientButton({
    required this.buttonKey,
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.gradient,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isLoading
              ? LinearGradient(
                  colors: [
                    gradient.colors.first.withValues(alpha: 0.6),
                    gradient.colors.last.withValues(alpha: 0.6),
                  ],
                )
              : gradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isLoading
              ? []
              : const [
                  BoxShadow(
                    color: Color(0x440D9488),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          key: Key(buttonKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(label, style: AppTypography.button(Colors.white)),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.expenseLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.error,
            color: AppColors.expense,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall(AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.4))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            AppStrings.or,
            style: AppTypography.caption(scheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: scheme.outline.withValues(alpha: 0.4))),
      ],
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  final String buttonKey;
  final VoidCallback onPressed;
  const GoogleSignInButton({
    required this.buttonKey,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton(
        key: Key(buttonKey),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              AppStrings.continueWithGoogle,
              style: AppTypography.button(
                scheme.onSurface,
              ).copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

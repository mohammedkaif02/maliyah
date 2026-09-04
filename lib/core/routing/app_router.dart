import 'package:flutter/material.dart';
import 'package:maliyah/screens/auth/forgot_password_screen.dart';
import 'package:maliyah/screens/auth/login_screen.dart';
import 'package:maliyah/screens/auth/onboarding_screen.dart';
import 'package:maliyah/screens/auth/signup_screen.dart';
import 'package:maliyah/screens/auth/splash_screen.dart';
import 'package:maliyah/screens/profile/change_password_screen.dart';
import 'package:maliyah/screens/profile/delete_account_screen.dart';
import 'package:maliyah/screens/profile/edit_profile_screen.dart';
import 'package:maliyah/screens/profile/profile_screen.dart';
import 'package:maliyah/screens/root_shell.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String app = '/app';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String deleteAccount = '/profile/delete-account';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildFadeRoute(const SplashScreen(), settings);

      case AppRoutes.onboarding:
        return _buildFadeRoute(const OnboardingScreen(), settings);

      case AppRoutes.login:
        return _buildFadeRoute(const LoginScreen(), settings);

      case AppRoutes.signup:
        return _buildSlideRoute(const SignupScreen(), settings);

      case AppRoutes.forgotPassword:
        return _buildSlideRoute(const ForgotPasswordScreen(), settings);

      case AppRoutes.app:
        return _buildFadeRoute(const RootShell(), settings);

      case AppRoutes.profile:
        return _buildSlideRoute(const ProfileScreen(), settings);

      case AppRoutes.editProfile:
        return _buildSlideRoute(const EditProfileScreen(), settings);

      case AppRoutes.changePassword:
        return _buildSlideRoute(const ChangePasswordScreen(), settings);

      case AppRoutes.deleteAccount:
        return _buildSlideRoute(const DeleteAccountScreen(), settings);

      default:
        return _buildFadeRoute(const SplashScreen(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _buildFadeRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static PageRouteBuilder<dynamic> _buildSlideRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation =
            Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

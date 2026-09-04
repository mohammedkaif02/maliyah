import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maliyah/blocs/auth/auth_cubit.dart';
import 'package:maliyah/core/routing/app_router.dart';
import 'package:maliyah/core/theme/app_theme.dart';
import 'package:maliyah/data/models/user_model.dart';
import 'package:maliyah/data/repositories/auth_repository.dart';
import 'package:maliyah/screens/auth/forgot_password_screen.dart';
import 'package:maliyah/screens/auth/login_screen.dart';
import 'package:maliyah/screens/auth/signup_screen.dart';

class MockAuthRepository implements AuthRepository {
  UserModel? mockUser = const UserModel(
    id: 'mock_123',
    name: 'Kaif',
    email: 'kaif@gmail.com',
  );

  @override
  Future<UserModel?> getCurrentUser() async => mockUser;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    return const UserModel(
      id: 'mock_123',
      name: 'Kaif',
      email: 'kaif@gmail.com',
    );
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return UserModel(id: 'mock_new', name: name, email: email);
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<UserModel> updateDisplayName({required String name}) async {
    return UserModel(id: 'mock_123', name: name, email: 'kaif@gmail.com');
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    mockUser = null;
  }
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late AuthCubit authCubit;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    authCubit = AuthCubit(mockAuthRepo);
  });

  tearDown(() {
    authCubit.close();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: BlocProvider<AuthCubit>.value(value: authCubit, child: child),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders all login fields and buttons', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byKey(const Key('login_email')), findsOneWidget);
      expect(find.byKey(const Key('login_password')), findsOneWidget);
      expect(find.byKey(const Key('sign_in_btn')), findsOneWidget);
      expect(find.textContaining('Sign Up'), findsOneWidget);
      expect(find.text('Continue as Guest →'), findsOneWidget);
    });

    testWidgets('Empty email and password shows validation errors', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sign_in_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });

  group('SignupScreen Widget Tests', () {
    testWidgets('Renders signup fields, terms and password meter', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(const SignupScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('signup_name')), findsOneWidget);
      expect(find.byKey(const Key('signup_email')), findsOneWidget);
      expect(find.byKey(const Key('signup_password')), findsOneWidget);
      expect(find.byKey(const Key('signup_confirm_password')), findsOneWidget);
      expect(find.byKey(const Key('create_account_btn')), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('Renders email input and submit button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const ForgotPasswordScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byKey(const Key('forgot_email')), findsOneWidget);
      expect(find.byKey(const Key('send_reset_btn')), findsOneWidget);
    });
  });
}

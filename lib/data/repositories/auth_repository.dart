import 'package:maliyah/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  Future<UserModel?> getCurrentUser();

  Future<UserModel> updateDisplayName({required String name});

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount({required String email, required String password});
}

/// Maps 1:1 to Firebase Auth error codes for seamless migration.
///
/// FirebaseAuthException.code → AuthErrorCode mapping:
///   'invalid-email'          → invalidEmail
///   'wrong-password'         → wrongPassword
///   'user-not-found'         → userNotFound
///   'email-already-in-use'   → emailAlreadyInUse
///   'weak-password'          → weakPassword
///   'network-request-failed' → networkError
enum AuthErrorCode {
  invalidEmail,
  wrongPassword,
  userNotFound,
  emailAlreadyInUse,
  weakPassword,
  networkError,
  requiresRecentLogin,
  unknown,
}

class AuthException implements Exception {
  final AuthErrorCode code;
  final String message;

  const AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException(${code.name}): $message';
}

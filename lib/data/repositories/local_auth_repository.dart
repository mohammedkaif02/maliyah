import 'dart:convert';
import 'package:maliyah/data/models/user_model.dart';
import 'package:maliyah/data/repositories/auth_repository.dart';
import 'package:maliyah/data/services/storage_service.dart';

class LocalAuthRepository implements AuthRepository {
  final StorageService _storage;

  LocalAuthRepository(this._storage);

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final stored = _storage.loadAuthCredentials();
    if (stored == null) {
      throw const AuthException(
        code: AuthErrorCode.userNotFound,
        message: 'No account found. Please create an account first.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (stored['email'] != normalizedEmail) {
      throw const AuthException(
        code: AuthErrorCode.userNotFound,
        message: 'No account found with this email address.',
      );
    }

    final storedHash = stored['passwordHash'] as String;
    if (storedHash != _hashPassword(normalizedEmail, password)) {
      throw const AuthException(
        code: AuthErrorCode.wrongPassword,
        message: 'Incorrect password. Please try again.',
      );
    }

    final user = UserModel(
      id: stored['id'] as String,
      name: stored['name'] as String,
      email: stored['email'] as String,
    );

    await _storage.saveAuthUser(user);
    return user;
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    final normalizedEmail = email.trim().toLowerCase();
    final existing = _storage.loadAuthCredentials();

    if (existing != null && existing['email'] == normalizedEmail) {
      throw const AuthException(
        code: AuthErrorCode.emailAlreadyInUse,
        message: 'An account with this email already exists.',
      );
    }

    final user = UserModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
    );

    await _storage.saveAuthCredentials(
      id: user.id,
      name: user.name,
      email: user.email,
      passwordHash: _hashPassword(normalizedEmail, password),
    );
    await _storage.saveAuthUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _storage.clearAuthUser();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _storage.loadAuthUser();
  }

  @override
  Future<UserModel> updateDisplayName({required String name}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final current = _storage.loadAuthUser();
    if (current == null) {
      throw const AuthException(
        code: AuthErrorCode.unknown,
        message: 'No user is signed in.',
      );
    }
    final updated = current.copyWith(name: name.trim());
    await _storage.saveAuthUser(updated);
    return updated;
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final stored = _storage.loadAuthCredentials();
    if (stored == null) {
      throw const AuthException(
        code: AuthErrorCode.unknown,
        message: 'No credentials found.',
      );
    }
    final email = stored['email'] as String;
    if (stored['passwordHash'] != _hashPassword(email, currentPassword)) {
      throw const AuthException(
        code: AuthErrorCode.wrongPassword,
        message: 'Current password is incorrect.',
      );
    }
    await _storage.saveAuthCredentials(
      id: stored['id'] as String,
      name: stored['name'] as String,
      email: email,
      passwordHash: _hashPassword(email, newPassword),
    );
  }

  @override
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final stored = _storage.loadAuthCredentials();
    if (stored == null || stored['email'] != email.trim().toLowerCase()) {
      throw const AuthException(
        code: AuthErrorCode.userNotFound,
        message: 'Account not found.',
      );
    }
    if (stored['passwordHash'] !=
        _hashPassword(email.trim().toLowerCase(), password)) {
      throw const AuthException(
        code: AuthErrorCode.wrongPassword,
        message: 'Incorrect password.',
      );
    }
    await _storage.clearAuthUser();
  }

  String _hashPassword(String email, String password) {
    final raw = '$email\x00$password\x00fintrack_local_v1';
    return base64UrlEncode(utf8.encode(raw));
  }
}

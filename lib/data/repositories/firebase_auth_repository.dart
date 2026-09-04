import 'package:firebase_auth/firebase_auth.dart';
import 'package:maliyah/data/models/user_model.dart';
import 'package:maliyah/data/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: _mapCode(e.code), message: _mapMessage(e));
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user!.updateDisplayName(name.trim());
      await credential.user!.reload();
      return _fromFirebaseUser(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: _mapCode(e.code), message: _mapMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: _mapCode(e.code), message: _mapMessage(e));
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _fromFirebaseUser(_auth.currentUser!);
  }

  @override
  Future<UserModel> updateDisplayName({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        code: AuthErrorCode.unknown,
        message: 'No user is signed in.',
      );
    }
    try {
      await user.updateDisplayName(name.trim());
      await user.reload();
      return _fromFirebaseUser(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: _mapCode(e.code), message: _mapMessage(e));
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException(
        code: AuthErrorCode.unknown,
        message: 'No user is signed in.',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: _mapCode(e.code), message: _mapMessage(e));
    }
  }

  @override
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        code: AuthErrorCode.unknown,
        message: 'No user is signed in.',
      );
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthException(code: _mapCode(e.code), message: _mapMessage(e));
    }
  }

  UserModel _fromFirebaseUser(User user) {
    final email = user.email ?? '';
    final fallbackName = email.isNotEmpty
        ? email.split('@').first.replaceAll(RegExp(r'[._\-]'), ' ')
        : 'User';
    return UserModel(
      id: user.uid,
      name: (user.displayName?.trim().isNotEmpty == true)
          ? user.displayName!
          : fallbackName,
      email: email,
      photoUrl: user.photoURL,
    );
  }

  AuthErrorCode _mapCode(String code) => switch (code) {
    'invalid-email' => AuthErrorCode.invalidEmail,
    'wrong-password' || 'invalid-credential' => AuthErrorCode.wrongPassword,
    'user-not-found' => AuthErrorCode.userNotFound,
    'email-already-in-use' => AuthErrorCode.emailAlreadyInUse,
    'weak-password' => AuthErrorCode.weakPassword,
    'network-request-failed' => AuthErrorCode.networkError,
    'requires-recent-login' => AuthErrorCode.requiresRecentLogin,
    _ => AuthErrorCode.unknown,
  };

  String _mapMessage(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'The email address is not valid.',
      'wrong-password' ||
      'invalid-credential' => 'Incorrect email or password.',
      'user-not-found' => 'No account found with this email.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password must be at least 6 characters.',
      'network-request-failed' => 'No internet connection. Check your network.',
      'requires-recent-login' =>
        'Please sign out and sign in again before this operation.',
      _ => e.message ?? 'An unexpected error occurred.',
    };
  }
}

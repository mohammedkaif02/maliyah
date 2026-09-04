import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maliyah/blocs/auth/auth_state.dart';
import 'package:maliyah/data/repositories/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;

  AuthCubit(this._repo) : super(const AuthInitial());

  Future<void> checkSession() async {
    emit(const AuthInitial());
    try {
      final user = await _repo.getCurrentUser();
      if (user != null && user.id.isNotEmpty) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (_) {
      emit(const Unauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signIn(email: email, password: password);
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, operation: 'signIn'));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Something went wrong. Please try again.',
          operation: 'signIn',
        ),
      );
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.signUp(
        name: name,
        email: email,
        password: password,
      );
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, operation: 'signUp'));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Something went wrong. Please try again.',
          operation: 'signUp',
        ),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } finally {
      emit(const Unauthenticated());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(const AuthLoading());
    try {
      await _repo.sendPasswordResetEmail(email: email);
      emit(
        const AuthActionSuccess(
          message: 'Password reset email sent. Check your inbox.',
        ),
      );
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, operation: 'resetPassword'));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Failed to send reset email. Try again.',
          operation: 'resetPassword',
        ),
      );
    }
  }

  Future<void> updateDisplayName(String name) async {
    emit(const AuthLoading());
    try {
      final updatedUser = await _repo.updateDisplayName(name: name);
      emit(
        AuthActionSuccess(
          message: 'Display name updated successfully.',
          user: updatedUser,
        ),
      );
      emit(Authenticated(updatedUser));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, operation: 'updateDisplayName'));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Failed to update name. Try again.',
          operation: 'updateDisplayName',
        ),
      );
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(const AuthLoading());
    try {
      await _repo.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      final user = await _repo.getCurrentUser();
      emit(const AuthActionSuccess(message: 'Password changed successfully.'));
      if (user != null) emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, operation: 'updatePassword'));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Failed to update password. Try again.',
          operation: 'updatePassword',
        ),
      );
    }
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _repo.deleteAccount(email: email, password: password);
      emit(
        const AuthActionSuccess(
          message: 'Account deleted. Sorry to see you go.',
          user: null,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      emit(const Unauthenticated());
    } on AuthException catch (e) {
      emit(AuthError(message: e.message, operation: 'deleteAccount'));
    } catch (_) {
      emit(
        const AuthError(
          message: 'Failed to delete account. Try again.',
          operation: 'deleteAccount',
        ),
      );
    }
  }
}

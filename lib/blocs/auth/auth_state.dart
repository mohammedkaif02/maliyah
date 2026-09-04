import 'package:equatable/equatable.dart';
import 'package:maliyah/data/models/user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

final class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => [];
}

final class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  String get displayName => user.firstName;
  String get email => user.email;
  String get initials => user.initials;
  String? get photoUrl => user.photoUrl;

  @override
  List<Object?> get props => [user.id, user.name, user.email, user.photoUrl];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();

  @override
  List<Object?> get props => [];
}

final class AuthError extends AuthState {
  final String message;
  final String operation;

  const AuthError({required this.message, required this.operation});

  @override
  List<Object?> get props => [message, operation];
}

final class AuthActionSuccess extends AuthState {
  final UserModel? user;
  final String message;

  const AuthActionSuccess({required this.message, this.user});

  @override
  List<Object?> get props => [message, user?.id];
}

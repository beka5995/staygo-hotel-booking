import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../database/local_auth.dart';
import '../models/account.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSuccess extends AuthState {
  const AuthSuccess(this.account);

  final Account account;
  String get username => account.fullName;
  String get email => account.email;

  @override
  List<Object?> get props => [username, email, account.role];
}

final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  Future<void> login(String email, String password) => _authenticate(() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return LocalAuth.instance.login(email, password);
  });

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) => _authenticate(
    () => LocalAuth.instance.register(
      name: name,
      email: email,
      password: password,
      role: role,
    ),
  );

  Future<void> _authenticate(Future<Account> Function() request) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    try {
      final account = await request();
      if (!isClosed) emit(AuthSuccess(account));
    } on StateError catch (error) {
      if (!isClosed) emit(AuthError(error.message.toString()));
    } catch (_) {
      if (!isClosed) emit(const AuthError('Something went wrong. Try again.'));
    }
  }
}

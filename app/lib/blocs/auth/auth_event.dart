part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String telefono;
  final String rol;
  const RegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.telefono,
    required this.rol,
  });
  @override
  List<Object?> get props => [email, rol];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class UserUpdated extends AuthEvent {
  final Usuario usuario;
  const UserUpdated(this.usuario);
  @override
  List<Object?> get props => [usuario];
}

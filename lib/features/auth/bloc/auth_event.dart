part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthVerificarEstado extends AuthEvent {
  const AuthVerificarEstado();
}

class AuthIniciarEmail extends AuthEvent {
  final String email;
  final String password;
  const AuthIniciarEmail({required this.email, required this.password});
  @override
  List<Object?> get props => [email];
}

class AuthRegistrarEmail extends AuthEvent {
  final String email;
  final String password;
  const AuthRegistrarEmail({required this.email, required this.password});
  @override
  List<Object?> get props => [email];
}

class AuthIniciarGoogle extends AuthEvent {
  const AuthIniciarGoogle();
}

class AuthUsarSinCuenta extends AuthEvent {
  const AuthUsarSinCuenta();
}

class AuthCerrarSesion extends AuthEvent {
  const AuthCerrarSesion();
}

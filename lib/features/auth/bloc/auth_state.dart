part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Estado inicial — verificando sesión al arrancar la app
class AuthInicial extends AuthState {
  const AuthInicial();
}

/// Operación en curso (login, registro, Google)
class AuthCargando extends AuthState {
  const AuthCargando();
}

/// Usuario autenticado con Firebase
class AuthAutenticado extends AuthState {
  final String uid;
  const AuthAutenticado({required this.uid});
  @override
  List<Object?> get props => [uid];
}

/// Usuario eligió continuar sin cuenta (modo local)
class AuthModoLocal extends AuthState {
  const AuthModoLocal();
}

/// No autenticado — mostrar AuthScreen
class AuthNoAutenticado extends AuthState {
  const AuthNoAutenticado();
}

/// Error de autenticación
class AuthError extends AuthState {
  final String mensaje;
  const AuthError({required this.mensaje});
  @override
  List<Object?> get props => [mensaje];
}

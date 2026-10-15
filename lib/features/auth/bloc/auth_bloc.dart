import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/firebase_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

// ══════════════════════════════════════════════════════════════════
// AUTH BLOC — Fase 5
// Maneja el ciclo de vida de autenticación:
//   - Email/password
//   - Google Sign-In
//   - Modo local sin cuenta
//   - Cierre de sesión
// ══════════════════════════════════════════════════════════════════

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IFirebaseService _firebase;

  AuthBloc({required IFirebaseService firebaseService})
      : _firebase = firebaseService,
        super(const AuthInicial()) {
    on<AuthVerificarEstado>(_onVerificar);
    on<AuthIniciarEmail>(_onIniciarEmail);
    on<AuthRegistrarEmail>(_onRegistrarEmail);
    on<AuthIniciarGoogle>(_onIniciarGoogle);
    on<AuthUsarSinCuenta>(_onSinCuenta);
    on<AuthCerrarSesion>(_onCerrarSesion);
  }

  Future<void> _onVerificar(
      AuthVerificarEstado event, Emitter<AuthState> emit) async {
    final uid = _firebase.uidActual;
    if (uid != null) {
      emit(AuthAutenticado(uid: uid));
    } else {
      emit(const AuthNoAutenticado());
    }
  }

  Future<void> _onIniciarEmail(
      AuthIniciarEmail event, Emitter<AuthState> emit) async {
    emit(const AuthCargando());
    final r = await _firebase.iniciarSesionEmail(
        event.email, event.password);
    if (r.exito && r.uid != null) {
      emit(AuthAutenticado(uid: r.uid!));
    } else {
      emit(AuthError(mensaje: r.errorMensaje ?? 'Error desconocido'));
      emit(const AuthNoAutenticado());
    }
  }

  Future<void> _onRegistrarEmail(
      AuthRegistrarEmail event, Emitter<AuthState> emit) async {
    emit(const AuthCargando());
    // Registrar = iniciar sesión (Firebase crea la cuenta si no existe)
    final r = await _firebase.iniciarSesionEmail(
        event.email, event.password);
    if (r.exito && r.uid != null) {
      emit(AuthAutenticado(uid: r.uid!));
    } else {
      emit(AuthError(mensaje: r.errorMensaje ?? 'Error al registrar'));
      emit(const AuthNoAutenticado());
    }
  }

  Future<void> _onIniciarGoogle(
      AuthIniciarGoogle event, Emitter<AuthState> emit) async {
    emit(const AuthCargando());
    final r = await _firebase.iniciarSesionGoogle();
    if (r.exito && r.uid != null) {
      emit(AuthAutenticado(uid: r.uid!));
    } else {
      emit(AuthError(
          mensaje: r.errorMensaje ?? 'Error con Google Sign-In'));
      emit(const AuthNoAutenticado());
    }
  }

  void _onSinCuenta(
      AuthUsarSinCuenta event, Emitter<AuthState> emit) {
    emit(const AuthModoLocal());
  }

  Future<void> _onCerrarSesion(
      AuthCerrarSesion event, Emitter<AuthState> emit) async {
    await _firebase.cerrarSesion();
    emit(const AuthNoAutenticado());
  }
}

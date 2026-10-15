import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multas_ar/core/services/firebase_service.dart';
import 'package:multas_ar/features/auth/bloc/auth_bloc.dart';

// ══════════════════════════════════════════════════════════════════
// TESTS — AuthBloc
// Verifica el flujo de autenticación con mock de IFirebaseService.
// No requiere Firebase SDK instalado.
// ══════════════════════════════════════════════════════════════════

class MockFirebaseService extends Mock implements IFirebaseService {}

void main() {
  late MockFirebaseService mockFirebase;

  setUp(() {
    mockFirebase = MockFirebaseService();
    // Estado auth por defecto: no autenticado
    when(() => mockFirebase.estadoAuth)
        .thenAnswer((_) => Stream.value(AuthEstado.noAutenticado));
    when(() => mockFirebase.uidActual).thenReturn(null);
  });

  group('AuthBloc — verificación inicial', () {
    blocTest<AuthBloc, AuthState>(
      'emite AuthNoAutenticado si no hay sesión activa',
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthVerificarEstado()),
      expect: () => [const AuthNoAutenticado()],
    );

    blocTest<AuthBloc, AuthState>(
      'emite AuthAutenticado si hay uid en curso',
      setUp: () =>
          when(() => mockFirebase.uidActual).thenReturn('uid-abc-123'),
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthVerificarEstado()),
      expect: () => [const AuthAutenticado(uid: 'uid-abc-123')],
    );
  });

  group('AuthBloc — email/password', () {
    blocTest<AuthBloc, AuthState>(
      'login exitoso emite AuthAutenticado',
      setUp: () => when(() => mockFirebase.iniciarSesionEmail(
              any(), any()))
          .thenAnswer((_) async => const AuthResultado(
                exito: true,
                uid: 'uid-xyz',
                email: 'test@test.com',
              )),
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthIniciarEmail(
          email: 'test@test.com', password: '123456')),
      expect: () => [
        const AuthCargando(),
        const AuthAutenticado(uid: 'uid-xyz'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'login fallido emite AuthError luego AuthNoAutenticado',
      setUp: () => when(() => mockFirebase.iniciarSesionEmail(
              any(), any()))
          .thenAnswer((_) async => const AuthResultado(
                exito: false,
                errorMensaje: 'Contraseña incorrecta.',
              )),
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthIniciarEmail(
          email: 'x@x.com', password: 'wrong')),
      expect: () => [
        const AuthCargando(),
        const AuthError(mensaje: 'Contraseña incorrecta.'),
        const AuthNoAutenticado(),
      ],
    );
  });

  group('AuthBloc — Google Sign-In', () {
    blocTest<AuthBloc, AuthState>(
      'Google exitoso emite AuthAutenticado',
      setUp: () =>
          when(() => mockFirebase.iniciarSesionGoogle())
              .thenAnswer((_) async => const AuthResultado(
                    exito: true,
                    uid: 'google-uid',
                    email: 'user@gmail.com',
                  )),
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthIniciarGoogle()),
      expect: () => [
        const AuthCargando(),
        const AuthAutenticado(uid: 'google-uid'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'Google cancelado emite AuthError',
      setUp: () =>
          when(() => mockFirebase.iniciarSesionGoogle())
              .thenAnswer((_) async => const AuthResultado(
                    exito: false,
                    errorMensaje: 'Inicio de sesión cancelado.',
                  )),
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthIniciarGoogle()),
      expect: () => [
        const AuthCargando(),
        const AuthError(mensaje: 'Inicio de sesión cancelado.'),
        const AuthNoAutenticado(),
      ],
    );
  });

  group('AuthBloc — modo local', () {
    blocTest<AuthBloc, AuthState>(
      'usar sin cuenta emite AuthModoLocal',
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthUsarSinCuenta()),
      expect: () => [const AuthModoLocal()],
    );
  });

  group('AuthBloc — cierre de sesión', () {
    blocTest<AuthBloc, AuthState>(
      'cerrar sesión llama cerrarSesion() y emite AuthNoAutenticado',
      setUp: () =>
          when(() => mockFirebase.cerrarSesion())
              .thenAnswer((_) async {}),
      build: () => AuthBloc(firebaseService: mockFirebase),
      act: (b) => b.add(const AuthCerrarSesion()),
      expect: () => [const AuthNoAutenticado()],
      verify: (_) =>
          verify(() => mockFirebase.cerrarSesion()).called(1),
    );
  });
}

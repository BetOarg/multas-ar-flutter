// ══════════════════════════════════════════════════════════════════
// FIREBASE SERVICE — Fase 3
// Auth (email/Google) + sincronización Firestore de casos.
//
// ESTADO: stub listo para activar en Fase 3.
// Para activar:
//   1. flutter pub add firebase_core firebase_auth cloud_firestore
//   2. flutterfire configure
//   3. Reemplazar los métodos stub por la implementación real.
//   4. Actualizar ICasosRepository para usar FirestoreCasosRepository.
//
// Esta clase NO se importa en main.dart hasta Fase 3.
// ══════════════════════════════════════════════════════════════════

/// Estado de autenticación del usuario
enum AuthEstado { noAutenticado, autenticando, autenticado, error }

/// Resultado de operación de auth
class AuthResultado {
  final bool exito;
  final String? uid;
  final String? email;
  final String? errorMensaje;

  const AuthResultado({
    required this.exito,
    this.uid,
    this.email,
    this.errorMensaje,
  });
}

/// Interfaz de Firebase — permite mock en tests
abstract class IFirebaseService {
  Future<AuthResultado> iniciarSesionEmail(String email, String password);
  Future<AuthResultado> iniciarSesionGoogle();
  Future<void> cerrarSesion();
  Future<bool> sincronizarCasos(String uid);
  Stream<AuthEstado> get estadoAuth;
  String? get uidActual;
}

/// Stub — sin dependencias Firebase hasta Fase 3
class FirebaseServiceStub implements IFirebaseService {
  @override
  Future<AuthResultado> iniciarSesionEmail(
      String email, String password) async {
    // TODO Fase 3: FirebaseAuth.instance.signInWithEmailAndPassword(...)
    return const AuthResultado(
        exito: false,
        errorMensaje: 'Firebase no habilitado en esta versión (Fase 1-2).');
  }

  @override
  Future<AuthResultado> iniciarSesionGoogle() async {
    // TODO Fase 3: GoogleSignIn + FirebaseAuth
    return const AuthResultado(
        exito: false,
        errorMensaje: 'Firebase no habilitado en esta versión (Fase 1-2).');
  }

  @override
  Future<void> cerrarSesion() async {
    // TODO Fase 3: FirebaseAuth.instance.signOut()
  }

  @override
  Future<bool> sincronizarCasos(String uid) async {
    // TODO Fase 3: leer casos locales desde Drift y escribir a Firestore
    // Estrategia: last-write-wins por updatedAt timestamp
    return false;
  }

  @override
  Stream<AuthEstado> get estadoAuth =>
      Stream.value(AuthEstado.noAutenticado);

  @override
  String? get uidActual => null;
}

// ══════════════════════════════════════════════════════════════════
// FIRESTORE CASOS REPOSITORY — Fase 3
// Implementa ICasosRepository sobre Firestore.
// Estructura de colección:
//   /users/{uid}/casos/{casoId}  →  documento caso
//   /users/{uid}/plazos/{plazoId} → documento plazo
// ══════════════════════════════════════════════════════════════════

/// Colecciones Firestore — constantes para evitar typos
abstract class FirestoreColecciones {
  static const users   = 'users';
  static const casos   = 'casos';
  static const plazos  = 'plazos';
  static const escritos = 'escritos';

  static String casosDeUsuario(String uid) => 'users/$uid/casos';
  static String plazosDeCaso(String uid, String casoId) =>
      'users/$uid/casos/$casoId/plazos';
}

// TODO Fase 3: FirestoreCasosRepository implements ICasosRepository
// Ver /lib/core/repository/casos_repository.dart para la interfaz.
// El BLoC y la UI NO necesitan cambios: el Repository Pattern los aísla.

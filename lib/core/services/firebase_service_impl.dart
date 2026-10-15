import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';

// ══════════════════════════════════════════════════════════════════
// FIREBASE SERVICE IMPL — Fase 5
// Implementación real de IFirebaseService.
// Activar en main.dart reemplazando FirebaseServiceStub por
// FirebaseServiceImpl (ver instrucciones al pie).
//
// Prerequisitos:
//   flutter pub add firebase_core firebase_auth cloud_firestore
//                    google_sign_in
//   flutterfire configure   ← genera google-services.json + GoogleService-Info.plist
// ══════════════════════════════════════════════════════════════════

class FirebaseServiceImpl implements IFirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Auth estado ───────────────────────────────────────────────
  @override
  Stream<AuthEstado> get estadoAuth => _auth.authStateChanges().map((user) {
        if (user == null) return AuthEstado.noAutenticado;
        return AuthEstado.autenticado;
      });

  @override
  String? get uidActual => _auth.currentUser?.uid;

  // ── Email / Password ──────────────────────────────────────────
  @override
  Future<AuthResultado> iniciarSesionEmail(
      String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return AuthResultado(
        exito: true,
        uid: cred.user?.uid,
        email: cred.user?.email,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResultado(
        exito: false,
        errorMensaje: _mensajeError(e.code),
      );
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────
  @override
  Future<AuthResultado> iniciarSesionGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResultado(
            exito: false, errorMensaje: 'Inicio de sesión cancelado.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken:     googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return AuthResultado(
        exito: true,
        uid:   cred.user?.uid,
        email: cred.user?.email,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResultado(
          exito: false, errorMensaje: _mensajeError(e.code));
    } catch (e) {
      return AuthResultado(exito: false, errorMensaje: e.toString());
    }
  }

  // ── Cerrar sesión ─────────────────────────────────────────────
  @override
  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Sync Firestore ────────────────────────────────────────────
  @override
  Future<bool> sincronizarCasos(String uid) async {
    // Implementado en FirestoreCasosRepository
    return true;
  }

  // ── Mensajes de error legibles ────────────────────────────────
  String _mensajeError(String code) => switch (code) {
        'user-not-found'        => 'No existe una cuenta con ese email.',
        'wrong-password'        => 'Contraseña incorrecta.',
        'invalid-email'         => 'Email inválido.',
        'user-disabled'         => 'Cuenta deshabilitada.',
        'too-many-requests'     => 'Demasiados intentos. Intentá más tarde.',
        'network-request-failed'=> 'Sin conexión a internet.',
        'email-already-in-use'  => 'Ya existe una cuenta con ese email.',
        'weak-password'         => 'La contraseña debe tener al menos 6 caracteres.',
        _                       => 'Error de autenticación ($code).',
      };
}

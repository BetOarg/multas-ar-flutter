import 'package:cloud_firestore/cloud_firestore.dart';
import 'casos_repository.dart';
import '../services/firebase_service.dart';
import '../database/daos/casos_dao.dart';
import '../database/daos/plazos_dao.dart';
import '../services/plazos_service.dart';

// ══════════════════════════════════════════════════════════════════
// FIRESTORE CASOS REPOSITORY — Fase 5
// Implementa ICasosRepository sobre Firestore con estrategia
// offline-first: escribe local (Drift) y sincroniza Firestore
// en background. Last-write-wins por updatedAt.
//
// Estructura Firestore:
//   /users/{uid}/casos/{casoId}         → documento caso
//   /users/{uid}/casos/{casoId}/plazos/{plazoId} → subcolección
//
// Para activar: reemplazar LocalCasosRepository en main.dart.
// El BLoC y la UI no necesitan ningún cambio.
// ══════════════════════════════════════════════════════════════════

class FirestoreCasosRepository implements ICasosRepository {
  final FirebaseFirestore _db;
  final LocalCasosRepository _local;
  final String _uid;

  FirestoreCasosRepository({
    required String uid,
    required CasosDao casosDao,
    required PlazosDao plazosDao,
    required PlazosService plazosService,
    FirebaseFirestore? firestore,
  })  : _uid = uid,
        _db = firestore ?? FirebaseFirestore.instance,
        _local = LocalCasosRepository(
          casosDao:      casosDao,
          plazosDao:     plazosDao,
          plazosService: plazosService,
        );

  // ── Colección raíz del usuario ────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _colCasos =>
      _db.collection(FirestoreColecciones.casosDeUsuario(_uid));

  // ── Leer — offline first ──────────────────────────────────────
  @override
  Future<dynamic> getCasoPorId(String casoId) async {
    // Primero busca local (más rápido, disponible offline)
    final local = await _local.getCasoPorId(casoId);
    if (local != null) return local;

    // Fallback: buscar en Firestore
    try {
      final doc = await _colCasos.doc(casoId).get();
      if (!doc.exists) return null;
      // TODO: convertir Map a entidad local y cachear en Drift
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<dynamic>> watchCasos() {
    // Usa stream local de Drift (reactivo, offline)
    return _local.watchCasos();
  }

  // ── Escribir — local + sync en background ─────────────────────
  @override
  Future<String> crearCaso(dynamic datos) async {
    final casoId = await _local.crearCaso(datos);
    _syncCasoToFirestore(casoId).ignore();
    return casoId;
  }

  @override
  Future<void> actualizarCaso(dynamic datos) async {
    await _local.actualizarCaso(datos);
    _syncCasoToFirestore(datos.id).ignore();
  }

  @override
  Future<void> eliminarCaso(String casoId) async {
    await _local.eliminarCaso(casoId);
    try {
      await _colCasos.doc(casoId).delete();
    } catch (_) {
      // Marcar como pendiente de eliminación en Firestore
    }
  }

  // ── Sync background ───────────────────────────────────────────
  Future<void> _syncCasoToFirestore(String casoId) async {
    try {
      final caso = await _local.getCasoPorId(casoId);
      if (caso == null) return;

      await _colCasos.doc(casoId).set(
        _casoToMap(caso),
        SetOptions(merge: true),
      );
    } catch (_) {
      // Sin conexión — Firestore SDK reintentará automáticamente
      // cuando haya conectividad (offline persistence habilitada)
    }
  }

  /// Sincronización completa: sube todos los casos locales a Firestore.
  /// Llamar una vez al iniciar sesión por primera vez.
  Future<void> sincronizarTodo() async {
    final casos = await _local.getCasosTodos();
    final batch = _db.batch();

    for (final caso in casos) {
      final ref = _colCasos.doc(caso.id);
      batch.set(ref, _casoToMap(caso), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Descarga casos de Firestore y los guarda en Drift local.
  /// Usar en login desde nuevo dispositivo.
  Future<void> descargarDesdeFirestore() async {
    try {
      final snap = await _colCasos
          .orderBy('updatedAt', descending: true)
          .limit(200)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        // TODO: convertir Map a CasosCompanion y upsert en Drift
        // await _local.upsertCaso(mapToCaso(data));
      }
    } catch (_) {
      // Sin conexión — continuar con datos locales
    }
  }

  // ── Serialización ─────────────────────────────────────────────
  Map<String, dynamic> _casoToMap(dynamic caso) => {
        'id':               caso.id,
        'jurisdiccion':     caso.jurisdiccion,
        'numeroActa':       caso.numeroActa,
        'patente':          caso.patente,
        'fechaInfraccion':  caso.fechaInfraccion?.toIso8601String(),
        'fechaNotificacion':caso.fechaNotificacion?.toIso8601String(),
        'normaInfringida':  caso.normaInfringida,
        'agente':           caso.agente,
        'legajoAgente':     caso.legajoAgente,
        'lugarInfraccion':  caso.lugarInfraccion,
        'descripcionHecho': caso.descripcionHecho,
        'estado':           caso.estado,
        'esFotomulta':      caso.esFotomulta,
        'tieneFiremaAgente':caso.tieneFiremaAgente,
        'textoOcrCompleto': caso.textoOcrCompleto,
        'updatedAt':        FieldValue.serverTimestamp(),
        'uid':              _uid,
      };
}

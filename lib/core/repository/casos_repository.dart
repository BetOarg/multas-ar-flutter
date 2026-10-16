import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/casos_dao.dart';
import '../database/daos/plazos_dao.dart';
import '../database/tables/tables.dart';
import '../services/plazos_service.dart';

// ══════════════════════════════════════════════════════════════════
// CASOS REPOSITORY
// ICasosRepository: interfaz que aísla BLoC y UI del motor de DB.
// LocalCasosRepository: implementación sobre Drift.
// FirestoreCasosRepository: en firestore_casos_repository.dart.
// ══════════════════════════════════════════════════════════════════

// ── Interfaz ──────────────────────────────────────────────────────
abstract class ICasosRepository {
  Stream<List<Caso>> watchCasos();
  Future<Caso?> getCasoPorId(String id);
  Future<List<Caso>> getCasosTodos();
  Future<String> crearCaso(CasosCompanion datos);
  Future<void> actualizarCaso(CasosCompanion datos);
  Future<void> eliminarCaso(String id);
}

// ── Implementación local ──────────────────────────────────────────
class LocalCasosRepository implements ICasosRepository {
  final CasosDao     _casosDao;
  final PlazosDao    _plazosDao;
  final PlazosService _plazosService;
  final _uuid = const Uuid();

  LocalCasosRepository({
    required CasosDao     casosDao,
    required PlazosDao    plazosDao,
    required PlazosService plazosService,
  })  : _casosDao     = casosDao,
        _plazosDao    = plazosDao,
        _plazosService = plazosService;

  @override
  Stream<List<Caso>> watchCasos() => _casosDao.watchTodos();

  @override
  Future<Caso?> getCasoPorId(String id) => _casosDao.getCasoPorId(id);

  @override
  Future<List<Caso>> getCasosTodos() => _casosDao.getTodos();

  // ── Crear ─────────────────────────────────────────────────────
  @override
  Future<String> crearCaso(CasosCompanion datos) async {
    final id  = _uuid.v4();
    final now = DateTime.now();

    final companion = datos.copyWith(
      id:           Value(id),
      creadoEn:     Value(now),
      actualizadoEn: Value(now),
    );

    await _casosDao.upsertCaso(companion);

    // Calcular y guardar plazos si hay fecha de notificación
    final jur   = datos.jurisdiccion.value;
    final notif = datos.fechaNotificacion.value;
    if (jur != null && notif != null) {
      await _guardarPlazos(id, jur, notif,
          esFoto: datos.esFotomulta.value ?? false);
    }

    return id;
  }

  // ── Actualizar ────────────────────────────────────────────────
  @override
  Future<void> actualizarCaso(CasosCompanion datos) async {
    final id = datos.id.value;
    if (id == null) return;

    final companion = datos.copyWith(
      actualizadoEn: Value(DateTime.now()),
    );
    await _casosDao.actualizarCaso(companion);

    // Recalcular plazos
    final jur   = datos.jurisdiccion.value;
    final notif = datos.fechaNotificacion.value;
    if (jur != null && notif != null) {
      await _plazosDao.eliminarPlazosDeCaso(id);
      await _guardarPlazos(id, jur, notif,
          esFoto: datos.esFotomulta.value ?? false);
    }
  }

  // ── Eliminar ──────────────────────────────────────────────────
  @override
  Future<void> eliminarCaso(String id) async {
    await _plazosDao.eliminarPlazosDeCaso(id);
    await _casosDao.eliminarCaso(id);
  }

  // ── Guardar plazos calculados ─────────────────────────────────
  Future<void> _guardarPlazos(
    String casoId,
    String jurisdiccion,
    DateTime fechaNotif, {
    bool esFoto = false,
  }) async {
    final calculados = _plazosService.calcularPlazos(
      jurisdiccion:      jurisdiccion,
      fechaNotificacion: fechaNotif,
      esFotomulta:       esFoto,
    );

    final companions = calculados.map((p) {
      return PlazosCompanion(
        casoId:           Value(casoId),
        nombre:           Value(p.nombre),
        norma:            Value(p.norma),
        fechaInicio:      Value(p.fechaInicio),
        fechaVencimiento: Value(p.fechaVencimiento),
        tipoPlazo:        const Value('habiles_adm'),
        notificado:       const Value(false),
        vencido:          Value(p.estado == EstadoPlazo.vencido),
      );
    }).toList();

    await _plazosDao.insertarPlazos(companions);
  }
}

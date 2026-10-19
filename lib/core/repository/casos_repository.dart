import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/daos/casos_dao.dart';
import '../database/daos/plazos_dao.dart';
import '../database/daos/escritos_dao.dart';
import '../services/plazos_service.dart';

abstract class ICasosRepository {
  Stream<List<Caso>> watchCasos();
  Stream<List<Caso>> watchCasosActivos();
  Future<void> archivarCaso(String id);
  Future<void> actualizarEstado(String id, String estado);
  Future<Caso?> getCasoPorId(String id);
  Future<List<Caso>> getCasosTodos();
  Future<String> crearCaso(CasosCompanion datos);
  Future<void> actualizarCaso(CasosCompanion datos);
  Future<void> eliminarCaso(String id);
}

class LocalCasosRepository implements ICasosRepository {
  final AppDatabase _database;
  final CasosDao _casosDao;
  final PlazosDao _plazosDao;
  final EscritosDao _escritosDao;
  final PlazosService _plazosService;
  final _uuid = const Uuid();

  LocalCasosRepository({
    required AppDatabase database,
    required CasosDao casosDao,
    required PlazosDao plazosDao,
    required EscritosDao escritosDao,
    required PlazosService plazosService,
  })  : _database = database,
        _casosDao = casosDao,
        _plazosDao = plazosDao,
        _escritosDao = escritosDao,
        _plazosService = plazosService;

  @override
  Stream<List<Caso>> watchCasos() => _casosDao.watchTodos();

  @override
  Stream<List<Caso>> watchCasosActivos() => _casosDao.watchActivos();

  @override
  Future<void> archivarCaso(String id) async {
    await _casosDao.actualizarEstadoCaso(id, 'archivado');
  }

  @override
  Future<void> actualizarEstado(String id, String estado) async {
    await _casosDao.actualizarEstadoCaso(id, estado);
  }

  @override
  Future<Caso?> getCasoPorId(String id) => _casosDao.getCasoPorId(id);

  @override
  Future<List<Caso>> getCasosTodos() => _casosDao.getTodos();

  @override
  Future<String> crearCaso(CasosCompanion datos) async {
    final id = datos.id.present ? datos.id.value : _uuid.v4();
    final now = DateTime.now();
    final companion = datos.copyWith(
      id: Value(id),
      creadoEn: Value(now),
      actualizadoEn: Value(now),
    );

    await _database.transaction(() async {
      await _casosDao.upsertCaso(companion);

      final jur = datos.jurisdiccion.present ? datos.jurisdiccion.value : null;
      final notif = datos.fechaNotificacion.present
          ? datos.fechaNotificacion.value
          : null;
      if (jur != null && notif != null) {
        await _guardarPlazos(
          id,
          jur,
          notif,
          esFoto: datos.esFotomulta.present && datos.esFotomulta.value,
        );
      }
    });
    return id;
  }

  @override
  Future<void> actualizarCaso(CasosCompanion datos) async {
    if (!datos.id.present) return;
    final id = datos.id.value;

    final recalcularPlazos = datos.jurisdiccion.present ||
        datos.fechaNotificacion.present ||
        datos.esFotomulta.present;

    await _database.transaction(() async {
      final companion = datos.copyWith(
        actualizadoEn: Value(DateTime.now()),
      );
      final actualizadoCount = await _casosDao.actualizarCaso(companion);
      if (!actualizadoCount) {
        throw StateError('No existe el caso $id para actualizar.');
      }

      if (!recalcularPlazos) return;

      // Leer dentro de la misma transacción evita perder campos existentes
      // y mantiene caso/plazos consistentes si falla el recálculo.
      final actualizado = await _casosDao.getCasoPorId(id);
      await _plazosDao.eliminarPlazosDeCaso(id);

      if (actualizado != null &&
          actualizado.jurisdiccion != null &&
          actualizado.fechaNotificacion != null) {
        await _guardarPlazos(
          id,
          actualizado.jurisdiccion!,
          actualizado.fechaNotificacion!,
          esFoto: actualizado.esFotomulta,
        );
      }
    });
  }

  @override
  Future<void> eliminarCaso(String id) async {
    await _database.transaction(() async {
      // La transacción evita dejar el caso sin plazos/escritos si falla
      // cualquiera de los borrados dependientes.
      await _plazosDao.eliminarPlazosDeCaso(id);
      await _escritosDao.eliminarEscritosDeCaso(id);
      await _casosDao.eliminarCaso(id);
    });
  }

  Future<void> _guardarPlazos(
    String casoId,
    String jurisdiccion,
    DateTime fechaNotif, {
    bool esFoto = false,
  }) async {
    final calculados = _plazosService.calcularPlazos(
      jurisdiccion: jurisdiccion,
      fechaNotificacion: fechaNotif,
      esFotomulta: esFoto,
    );

    final companions = calculados.map((p) {
      return PlazosCompanion(
        casoId: Value(casoId),
        nombre: Value(p.nombre),
        norma: Value(p.norma),
        fechaInicio: Value(p.fechaInicio),
        fechaVencimiento: Value(p.fechaVencimiento),
        tipoPlazo: Value(p.tipoPlazo),
        notificado: const Value(false),
        vencido: Value(p.estado == EstadoPlazo.vencido),
      );
    }).toList();

    await _plazosDao.insertarPlazos(companions);
  }
}

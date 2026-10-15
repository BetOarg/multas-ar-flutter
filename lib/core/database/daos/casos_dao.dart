import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'casos_dao.g.dart';

@DriftAccessor(tables: [Casos])
class CasosDao extends DatabaseAccessor<AppDatabase> with _$CasosDaoMixin {
  CasosDao(super.db);

  /// Stream reactivo de todos los casos, más reciente primero
  Stream<List<Caso>> watchTodos() {
    return (select(casos)
          ..orderBy([(c) => OrderingTerm.desc(c.actualizadoEn)]))
        .watch();
  }

  /// Obtener caso por ID
  Future<Caso?> getCasoPorId(String id) {
    return (select(casos)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// Todos los casos (para sync)
  Future<List<Caso>> getTodos() => select(casos).get();

  /// Insertar o reemplazar caso
  Future<void> upsertCaso(CasosCompanion caso) async {
    await into(casos).insertOnConflictUpdate(caso);
  }

  /// Actualizar campos específicos de un caso
  Future<bool> actualizarCaso(CasosCompanion caso) {
    return update(casos).replace(caso);
  }

  /// Eliminar caso
  Future<void> eliminarCaso(String id) async {
    await (delete(casos)..where((c) => c.id.equals(id))).go();
  }

  /// Buscar casos por patente
  Future<List<Caso>> buscarPorPatente(String patente) {
    return (select(casos)
          ..where((c) => c.patente.like('%${patente.toUpperCase()}%')))
        .get();
  }

  /// Casos por jurisdicción
  Stream<List<Caso>> watchPorJurisdiccion(String jur) {
    return (select(casos)
          ..where((c) => c.jurisdiccion.equals(jur))
          ..orderBy([(c) => OrderingTerm.desc(c.actualizadoEn)]))
        .watch();
  }

  /// Conteo total de casos
  Future<int> contarCasos() async {
    final count = casos.id.count();
    final query = selectOnly(casos)..addColumns([count]);
    final row   = await query.getSingle();
    return row.read(count) ?? 0;
  }
}

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'plazos_dao.g.dart';

@DriftAccessor(tables: [Plazos])
class PlazosDao extends DatabaseAccessor<AppDatabase> with _$PlazosDaoMixin {
  PlazosDao(super.db);

  /// Plazos activos de un caso ordenados por fecha de vencimiento
  Stream<List<Plazo>> watchPlazosDeCaso(String casoId) {
    return (select(plazos)
          ..where((p) => p.casoId.equals(casoId))
          ..orderBy([(p) => OrderingTerm.asc(p.fechaVencimiento)]))
        .watch();
  }

  /// Plazos próximos a vencer en los próximos N días (todos los casos)
  Future<List<Plazo>> getPlazosProximos({int dias = 7}) {
    final limite = DateTime.now().add(Duration(days: dias));
    return (select(plazos)
          ..where((p) =>
              p.fechaVencimiento.isSmallerThanValue(limite) &
              p.vencido.equals(false) &
              p.notificado.equals(false))
          ..orderBy([(p) => OrderingTerm.asc(p.fechaVencimiento)]))
        .get();
  }

  /// Insertar lista de plazos calculados para un caso
  Future<void> insertarPlazos(List<PlazosCompanion> lista) async {
    await batch((b) => b.insertAllOnConflictUpdate(plazos, lista));
  }

  /// Marcar plazo como notificado
  Future<void> marcarNotificado(int plazoId) async {
    await (update(plazos)..where((p) => p.id.equals(plazoId)))
        .write(const PlazosCompanion(notificado: Value(true)));
  }

  /// Marcar plazo como vencido
  Future<void> marcarVencido(int plazoId) async {
    await (update(plazos)..where((p) => p.id.equals(plazoId)))
        .write(const PlazosCompanion(vencido: Value(true)));
  }

  /// Eliminar todos los plazos de un caso (al actualizar)
  Future<void> eliminarPlazosDeCaso(String casoId) async {
    await (delete(plazos)..where((p) => p.casoId.equals(casoId))).go();
  }
}

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'escritos_dao.g.dart';

@DriftAccessor(tables: [Escritos])
class EscritosDao extends DatabaseAccessor<AppDatabase>
    with _$EscritosDaoMixin {
  EscritosDao(super.db);

  /// Escritos generados para un caso
  Stream<List<Escrito>> watchEscritosDeCaso(String casoId) {
    return (select(escritos)
          ..where((e) => e.casoId.equals(casoId))
          ..orderBy([(e) => OrderingTerm.desc(e.creadoEn)]))
        .watch();
  }

  /// Obtener un escrito por ID
  Future<Escrito?> getEscritoPorId(int id) {
    return (select(escritos)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insertar nuevo escrito generado
  Future<int> insertarEscrito(EscritosCompanion escrito) {
    return into(escritos).insert(escrito);
  }

  /// Actualizar contenido de un escrito (campos completados)
  Future<bool> actualizarEscrito(EscritosCompanion escrito) {
    return update(escritos).replace(escrito);
  }

  /// Marcar escrito como completo (todos los campos llenados)
  Future<void> marcarCompleto(int id) async {
    await (update(escritos)..where((e) => e.id.equals(id))).write(
      EscritosCompanion(
        completo: const Value(true),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  /// Eliminar escrito
  Future<void> eliminarEscrito(int id) async {
    await (delete(escritos)..where((e) => e.id.equals(id))).go();
  }

  /// Escritos incompletos (campos faltantes aún)
  Future<List<Escrito>> getEscritosIncompletos() {
    return (select(escritos)
          ..where((e) => e.completo.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.creadoEn)]))
        .get();
  }
}

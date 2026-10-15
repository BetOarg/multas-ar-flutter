import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'normativa_dao.g.dart';

@DriftAccessor(tables: [NormativaEntradas, Feriados])
class NormativaDao extends DatabaseAccessor<AppDatabase>
    with _$NormativaDaoMixin {
  NormativaDao(super.db);

  // ── Normativa ────────────────────────────────────────────────

  /// Todas las entradas de una jurisdicción ordenadas por categoría
  Future<List<NormativaEntrada>> getEntradasPorJurisdiccion(
      String jurisdiccion) {
    return (select(normativaEntradas)
          ..where((n) => n.jurisdiccion.equals(jurisdiccion))
          ..orderBy([
            (n) => OrderingTerm.asc(n.orden),
            (n) => OrderingTerm.asc(n.categoria),
          ]))
        .get();
  }

  /// Entradas de alta importancia (para resumen rápido)
  Future<List<NormativaEntrada>> getEntradasCriticas(
      String jurisdiccion) {
    return (select(normativaEntradas)
          ..where((n) =>
              n.jurisdiccion.equals(jurisdiccion) &
              n.esAltaImportancia.equals(true)))
        .get();
  }

  /// Entradas con alerta dual (conflicto normativo)
  Future<List<NormativaEntrada>> getAlertasDuales(
      String jurisdiccion) {
    return (select(normativaEntradas)
          ..where((n) =>
              n.jurisdiccion.equals(jurisdiccion) &
              n.tieneAlertaDual.equals(true)))
        .get();
  }

  /// Actualizar normativa desde JSON (actualizaciones OTA)
  Future<void> actualizarDesdeJson(
      List<NormativaEntradasCompanion> entradas) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(normativaEntradas, entradas);
    });
  }

  /// Versión más reciente cargada
  Future<int> getVersionActual() async {
    final query = selectOnly(normativaEntradas)
      ..addColumns([normativaEntradas.version])
      ..orderBy([
        OrderingTerm.desc(normativaEntradas.version)
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.read(normativaEntradas.version) ?? 0;
  }

  // ── Feriados ─────────────────────────────────────────────────

  /// Feriados de un año específico (todos los tipos)
  Future<List<Feriado>> getFeriadosPorAnio(int anio) {
    return (select(feriados)
          ..where((f) => f.anio.equals(anio))
          ..orderBy([(f) => OrderingTerm.asc(f.fecha)]))
        .get();
  }

  /// Feriados nacionales de un año
  Future<List<Feriado>> getFeriadosNacionales(int anio) {
    return (select(feriados)
          ..where((f) =>
              f.anio.equals(anio) &
              f.tipo.equals('nacional')))
        .get();
  }

  /// Feriados de una jurisdicción específica + nacionales
  Future<List<Feriado>> getFeriadosPorJurisdiccion(
      int anio, String jurisdiccion) {
    return (select(feriados)
          ..where((f) =>
              f.anio.equals(anio) &
              (f.jurisdiccion.isNull() |
                  f.jurisdiccion.equals(jurisdiccion))))
        .get();
  }

  /// Insertar feriados en bulk (seed anual)
  Future<void> insertarFeriados(List<FeriadosCompanion> lista) async {
    await batch((b) => b.insertAllOnConflictUpdate(feriados, lista));
  }
}

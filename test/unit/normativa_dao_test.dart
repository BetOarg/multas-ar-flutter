import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/database/app_database.dart';
import 'package:multas_ar/core/database/daos/normativa_dao.dart';

void main() {
  late AppDatabase database;
  late NormativaDao dao;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
    dao = NormativaDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  NormativaEntradasCompanion entrada({
    required String jurisdiccion,
    required String titulo,
    required String contenido,
    int version = 2,
  }) {
    return NormativaEntradasCompanion(
      jurisdiccion: Value(jurisdiccion),
      categoria: const Value('advertencia'),
      titulo: Value(titulo),
      contenido: Value(contenido),
      normaBase: const Value('Fuente oficial de prueba'),
      esAltaImportancia: const Value(true),
      tieneAlertaDual: const Value(false),
      alertaDualDetalle: const Value(null),
      orden: const Value(1),
      version: Value(version),
    );
  }

  test('la actualización OTA reemplaza entradas sin duplicarlas ni conservar obsoletas',
      () async {
    await dao.actualizarDesdeJson([
      entrada(
        jurisdiccion: 'PBA',
        titulo: 'Plazo antiguo',
        contenido: 'Contenido antiguo',
        version: 1,
      ),
    ]);

    await dao.actualizarDesdeJson([
      entrada(
        jurisdiccion: 'PBA',
        titulo: 'Plazo actualizado',
        contenido: 'Contenido actualizado',
      ),
      entrada(
        jurisdiccion: 'CABA',
        titulo: 'Advertencia nueva',
        contenido: 'Verificar el caso',
      ),
    ]);

    final pba = await dao.getEntradasPorJurisdiccion('PBA');
    final caba = await dao.getEntradasPorJurisdiccion('CABA');

    expect(pba, hasLength(1));
    expect(pba.single.titulo, 'Plazo actualizado');
    expect(caba, hasLength(1));
    expect(await dao.getVersionActual(), 2);
  });

  test('reemplazar feriados evita conservar filas de una lista OTA anterior',
      () async {
    await dao.reemplazarFeriados([
      FeriadosCompanion(
        fecha: Value(DateTime(2026, 1, 1)),
        anio: const Value(2026),
        descripcion: const Value('Año Nuevo'),
        tipo: const Value('nacional'),
        jurisdiccion: const Value(null),
      ),
    ]);

    await dao.reemplazarFeriados([
      FeriadosCompanion(
        fecha: Value(DateTime(2027, 1, 1)),
        anio: const Value(2027),
        descripcion: const Value('Año Nuevo'),
        tipo: const Value('nacional'),
        jurisdiccion: const Value(null),
      ),
    ]);

    expect(await dao.getFeriadosPorAnio(2026), isEmpty);
    expect(await dao.getFeriadosPorAnio(2027), hasLength(1));
  });
}

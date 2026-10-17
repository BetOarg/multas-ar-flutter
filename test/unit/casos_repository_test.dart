import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/database/app_database.dart';
import 'package:multas_ar/core/database/daos/casos_dao.dart';
import 'package:multas_ar/core/database/daos/escritos_dao.dart';
import 'package:multas_ar/core/database/daos/plazos_dao.dart';
import 'package:multas_ar/core/database/tables/tables.dart';
import 'package:multas_ar/core/repository/casos_repository.dart';
import 'package:multas_ar/core/services/plazos_service.dart';

void main() {
  late AppDatabase database;
  late CasosDao casosDao;
  late PlazosDao plazosDao;
  late EscritosDao escritosDao;
  late LocalCasosRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    // Abrir la conexión antes de ejecutar operaciones de los DAOs.
    await database.customSelect('SELECT 1').get();
    casosDao = CasosDao(database);
    plazosDao = PlazosDao(database);
    escritosDao = EscritosDao(database);
    repository = LocalCasosRepository(
      database: database,
      casosDao: casosDao,
      plazosDao: plazosDao,
      escritosDao: escritosDao,
      plazosService: PlazosService(feriados: const []),
    );
  });

  tearDown(() async {
    await database.close();
  });

  CasosCompanion caso({
    String id = 'caso-test',
    String jurisdiccion = 'CABA',
    DateTime? fechaNotificacion,
  }) {
    final ahora = DateTime(2026, 4, 6);
    return CasosCompanion(
      id: Value(id),
      jurisdiccion: Value(jurisdiccion),
      fechaNotificacion: Value(fechaNotificacion ?? ahora),
      creadoEn: Value(ahora),
      actualizadoEn: Value(ahora),
    );
  }

  test('crear caso y plazos ocurre con los tipos de cómputo correctos', () async {
    final id = await repository.crearCaso(caso());

    expect(await casosDao.getCasoPorId(id), isNotNull);
    final plazos = await plazosDao.getPlazosDeCaso(id);
    expect(plazos, hasLength(1));
    expect(plazos.single.tipoPlazo, 'habiles_adm');
  });

  test('editar fecha de notificación recalcula plazos sin perder jurisdicción',
      () async {
    final id = await repository.crearCaso(caso());
    final nuevaFecha = DateTime(2026, 5, 4);

    await repository.actualizarCaso(CasosCompanion(
      id: Value(id),
      fechaNotificacion: Value(nuevaFecha),
    ));

    final guardado = await casosDao.getCasoPorId(id);
    final plazos = await plazosDao.getPlazosDeCaso(id);
    expect(guardado?.jurisdiccion, 'CABA');
    expect(guardado?.fechaNotificacion, nuevaFecha);
    expect(plazos, hasLength(1));
    expect(plazos.single.fechaInicio, nuevaFecha);
    expect(plazos.single.tipoPlazo, 'habiles_adm');
  });

  test('eliminar caso elimina plazos y escritos en la misma operación', () async {
    final id = await repository.crearCaso(caso());
    await escritosDao.insertarEscrito(EscritosCompanion(
      casoId: Value(id),
      tipo: const Value('descargo_pba'),
      titulo: const Value('Descargo de prueba'),
      contenido: const Value('Contenido de prueba'),
      creadoEn: Value(DateTime(2026, 4, 6)),
      actualizadoEn: Value(DateTime(2026, 4, 6)),
    ));

    await repository.eliminarCaso(id);

    expect(await casosDao.getCasoPorId(id), isNull);
    expect(await plazosDao.getPlazosDeCaso(id), isEmpty);
    final escritos = await (database.select(database.escritos)
          ..where((e) => e.casoId.equals(id)))
        .get();
    expect(escritos, isEmpty);
  });
}

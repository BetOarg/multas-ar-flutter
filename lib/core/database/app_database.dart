import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/tables.dart';
import 'daos/casos_dao.dart';
import 'daos/plazos_dao.dart';
import 'daos/escritos_dao.dart';
import 'daos/normativa_dao.dart';

part 'app_database.g.dart';

// ══════════════════════════════════════════════════════════════════
// APP DATABASE — Drift + SQLite
// Versión actual: 3
//
// Historial de migraciones:
//   v1 → v2: Agrega columna legajo_agente en Casos
//   v2 → v3: Agrega columna tipo_falta en Casos
//             Agrega tabla Feriados
// ══════════════════════════════════════════════════════════════════

@DriftDatabase(
  tables: [
    Casos,
    Plazos,
    Escritos,
    NormativaEntradas,
    Configuracion,
    Feriados,
  ],
  daos: [
    CasosDao,
    PlazosDao,
    EscritosDao,
    NormativaDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor para tests en memoria
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed de configuración inicial
          await batch((batch) {
            batch.insertAll(configuracion, const [
              ConfiguracionCompanion(
                clave: Value('app_version'),
                valor: Value('1.0.0'),
              ),
              ConfiguracionCompanion(
                clave: Value('normativa_version'),
                valor: Value('0'),
              ),
            ]);
          });
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: legajo_agente en Casos
          if (from < 2) {
            await m.addColumn(
              casos,
              casos.legajoAgente,
            );
          }
          // v2 → v3: tipo_falta en Casos + tabla Feriados
          if (from < 3) {
            await m.addColumn(casos, casos.tipoFalta);
            await m.createTable(feriados);
          }
        },
        beforeOpen: (details) async {
          // WAL mode para mejor rendimiento concurrente
          await customStatement('PRAGMA journal_mode=WAL');
          // Foreign keys habilitadas
          await customStatement('PRAGMA foreign_keys=ON');
        },
      );
}

// ── Conexión a la base de datos ────────────────────────────────────
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'multas_ar.db'));
    return NativeDatabase.createInBackground(file);
  });
}

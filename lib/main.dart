import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/database/app_database.dart';
import 'core/database/daos/casos_dao.dart';
import 'core/database/daos/escritos_dao.dart';
import 'core/database/daos/normativa_dao.dart';
import 'core/database/daos/plazos_dao.dart';
import 'core/repository/casos_repository.dart';
import 'core/repository/normativa_repository.dart';
import 'core/services/analisis_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/nulidades_service.dart';
import 'core/services/ocr_service.dart';
import 'core/services/plazos_service.dart';
import 'core/services/sinai_service.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
// MAIN — Multas Argentina Pro v1.1 (Fase 5)
//
// Orden de inicialización:
//   1. Flutter bindings + orientación
//   2. Timezone
//   3. Base de datos Drift
//   4. Seed / OTA normativa
//   5. Notificaciones locales
//   6. DI: MultiRepositoryProvider + AuthBloc wrapper
//   7. GoRouter con guard de autenticación
// ══════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  tz.initializeTimeZones();

  // ── Base de datos ─────────────────────────────────────────────
  final db          = AppDatabase();
  final casosDao    = CasosDao(db);
  final plazosDao   = PlazosDao(db);
  final escritosDao = EscritosDao(db);
  final normativaDao = NormativaDao(db);

  // ── Normativa ─────────────────────────────────────────────────
  final normativaRepo = NormativaRepository(normativaDao);
  await normativaRepo.inicializar();
  normativaRepo.actualizarOta().ignore();

  // ── Feriados ──────────────────────────────────────────────────
  final anio      = DateTime.now().year;
  final feriadosDB = await normativaDao.getFeriadosNacionales(anio);
  final feriados  = feriadosDB.map((f) => f.fecha).toList();

  // ── Notificaciones ────────────────────────────────────────────
  final notifPlugin = FlutterLocalNotificationsPlugin();
  await NotificationService.inicializar(notifPlugin);

  // ── Servicios ─────────────────────────────────────────────────
  final plazosService    = PlazosService(feriados: feriados);
  final analisisService  = AnalisisService(plazosService: plazosService);
  final nulidadesService = NulidadesService();
  final ocrService       = OcrServiceFactory.crear();
  final sinaiService     = SinaiService();

  // ── Firebase: Stub (Fase 1-4) o Impl (Fase 5 activada) ───────
  // Para activar Firebase:
  //   1. Descomentar deps en pubspec.yaml
  //   2. Ejecutar: flutterfire configure
  //   3. Reemplazar FirebaseServiceStub → FirebaseServiceImpl
  //   4. Agregar await Firebase.initializeApp() antes de runApp
  final IFirebaseService firebaseService = FirebaseServiceStub();

  // ── Repository ────────────────────────────────────────────────
  // Con Firebase activo → FirestoreCasosRepository
  final ICasosRepository casosRepo = LocalCasosRepository(
    database:     db,
    casosDao:      casosDao,
    plazosDao:     plazosDao,
    escritosDao:   escritosDao,
    plazosService: plazosService,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: db),
        RepositoryProvider<CasosDao>.value(value: casosDao),
        RepositoryProvider<PlazosDao>.value(value: plazosDao),
        RepositoryProvider<EscritosDao>.value(value: escritosDao),
        RepositoryProvider<NormativaDao>.value(value: normativaDao),
        RepositoryProvider<ICasosRepository>.value(value: casosRepo),
        RepositoryProvider<NormativaRepository>.value(value: normativaRepo),
        RepositoryProvider<PlazosService>.value(value: plazosService),
        RepositoryProvider<AnalisisService>.value(value: analisisService),
        RepositoryProvider<NulidadesService>.value(value: nulidadesService),
        RepositoryProvider<IOcrService>.value(value: ocrService),
        RepositoryProvider<SinaiService>.value(value: sinaiService),
        RepositoryProvider<IFirebaseService>.value(value: firebaseService),
        RepositoryProvider<FlutterLocalNotificationsPlugin>.value(
            value: notifPlugin),
        RepositoryProvider<List<DateTime>>.value(value: feriados),
      ],
      child: BlocProvider(
        create: (ctx) => AuthBloc(
          firebaseService: ctx.read<IFirebaseService>(),
        )..add(const AuthVerificarEstado()),
        child: const MultasArgentinaApp(),
      ),
    ),
  );
}

class MultasArgentinaApp extends StatelessWidget {
  const MultasArgentinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Router adapta su ruta inicial según el estado de auth
        final router = buildAppRouter(authState);
        return MaterialApp.router(
          title: 'Multas Argentina Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: router,
        );
      },
    );
  }
}

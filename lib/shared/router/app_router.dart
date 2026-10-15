import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/nulidades_service.dart';
import '../../core/services/plazos_service.dart';
import '../../features/analisis/bloc/analisis_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/ui/auth_screen.dart';
import '../../features/casos/bloc/casos_bloc.dart';
import '../../features/casos/ui/casos_screen.dart';
import '../../features/casos/ui/caso_detalle_screen.dart';
import '../../features/escritos/bloc/escritos_bloc.dart';
import '../../features/escritos/ui/escritos_screen.dart';
import '../../features/nulidades/bloc/nulidades_bloc.dart';
import '../../features/nulidades/ui/nulidades_screen.dart';
import '../../features/normativa/ui/normativa_screen.dart';
import '../../features/configuracion/ui/configuracion_screen.dart';
import '../../features/analisis/ui/analisis_screen.dart';
import '../widgets/scaffold_with_nav.dart';

// ══════════════════════════════════════════════════════════════════
// APP ROUTER v3 — con guard de autenticación
//
// Si el usuario no está autenticado Y no eligió modo local:
//   → redirige a /auth
// En todos los demás casos (autenticado o modo local):
//   → accede normalmente a las 5 tabs
// ══════════════════════════════════════════════════════════════════

GoRouter buildAppRouter(AuthState authState) {
  final bool accesoBloqueado =
      authState is AuthInicial || authState is AuthNoAutenticado;

  return GoRouter(
    initialLocation: accesoBloqueado ? '/auth' : '/analisis',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final enAuth = state.matchedLocation == '/auth';
      if (accesoBloqueado && !enAuth) return '/auth';
      if (!accesoBloqueado && enAuth) return '/analisis';
      return null;
    },
    routes: [
      // ── Pantalla de auth ───────────────────────────────────────
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => NoTransitionPage(
          child: BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const AuthScreen(),
          ),
        ),
      ),

      // ── Tabs principales (autenticado o modo local) ────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ScaffoldWithNav(shell: shell),
        branches: [
          // Tab 0 — Análisis
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/analisis',
              pageBuilder: (context, state) => NoTransitionPage(
                child: BlocProvider(
                  create: (ctx) => AnalisisBloc(
                    ocrService:      ctx.read(),
                    analisisService: ctx.read(),
                    repository:      ctx.read(),
                  ),
                  child: const AnalisisScreen(),
                ),
              ),
            ),
          ]),

          // Tab 1 — Casos + detalle + nulidades
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/casos',
              pageBuilder: (context, state) => NoTransitionPage(
                child: BlocProvider(
                  create: (ctx) => CasosBloc(repository: ctx.read()),
                  child: const CasosScreen(),
                ),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return MaterialPage(
                      child: BlocProvider(
                        create: (ctx) =>
                            CasosBloc(repository: ctx.read()),
                        child: CasoDetalleScreen(casoId: id),
                      ),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: 'nulidades',
                      pageBuilder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return MaterialPage(
                          child: BlocProvider(
                            create: (ctx) => NulidadesBloc(
                              nulidadesService: NulidadesService(),
                              repository:      ctx.read(),
                              escritosDao:     ctx.read(),
                            ),
                            child: NulidadesScreen(casoId: id),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ]),

          // Tab 2 — Escritos
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/escritos',
              pageBuilder: (context, state) => NoTransitionPage(
                child: BlocProvider(
                  create: (ctx) => EscritosBloc(
                    escritosDao:   ctx.read(),
                    plazosService: PlazosService(feriados: ctx.read()),
                  ),
                  child: const EscritosScreen(),
                ),
              ),
            ),
          ]),

          // Tab 3 — Normativa
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/normativa',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: NormativaScreen()),
            ),
          ]),

          // Tab 4 — Configuración
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/configuracion',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: ConfiguracionScreen()),
            ),
          ]),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.uri}',
            style: const TextStyle(color: Colors.white70)),
      ),
    ),
  );
}

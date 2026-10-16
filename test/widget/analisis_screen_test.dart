import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:multas_ar/core/repository/casos_repository.dart';
import 'package:multas_ar/core/services/ocr_service.dart';
import 'package:multas_ar/core/services/analisis_service.dart';
import 'package:multas_ar/core/services/analisis_service.dart';
import 'package:multas_ar/core/services/plazos_service.dart';
import 'package:multas_ar/features/analisis/bloc/analisis_bloc.dart';
import 'package:multas_ar/features/analisis/ui/analisis_screen.dart';
import 'package:multas_ar/shared/theme/app_theme.dart';

// ── Mocks ────────────────────────────────────────────────────────
class MockCasosRepository extends Mock implements ICasosRepository {}
class MockOcrService extends Mock implements IOcrService {}

// ══════════════════════════════════════════════════════════════════
// TESTS WIDGET — AnalisisScreen
// Smoke tests: renderizado, interacciones básicas, estados BLoC.
// ══════════════════════════════════════════════════════════════════

void main() {
  late MockCasosRepository mockRepo;
  late MockOcrService mockOcr;
  late PlazosService plazos;
  late AnalisisService analisis;

  setUp(() {
    mockRepo = MockCasosRepository();
    mockOcr  = MockOcrService();
    plazos   = PlazosService(feriados: []);
    analisis = AnalisisService(plazosService: plazos);

    // OCR disponible por defecto
    when(() => mockOcr.isDisponible()).thenAnswer((_) async => true);
  });

  Widget _buildApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
      home: BlocProvider(
        create: (_) => AnalisisBloc(
          ocrService:     mockOcr,
          analisisService: analisis,
          casosRepository: mockRepo,
          plazosService:   plazos,
        ),
        child: child,
      ),
    );
  }

  // ── Smoke test ───────────────────────────────────────────────
  group('AnalisisScreen — renderizado', () {
    testWidgets('muestra título de la app', (tester) async {
      await tester.pumpWidget(_buildApp(const AnalisisScreen()));
      await tester.pump();
      expect(find.textContaining('Analizar multa'), findsOneWidget);
    });

    testWidgets('muestra botón de cámara', (tester) async {
      await tester.pumpWidget(_buildApp(const AnalisisScreen()));
      await tester.pump();
      expect(
        find.byIcon(Icons.camera_alt_outlined).evaluate().isNotEmpty ||
        find.textContaining('Fotografiar').evaluate().isNotEmpty,
        true,
      );
    });

    testWidgets('muestra botón de galería', (tester) async {
      await tester.pumpWidget(_buildApp(const AnalisisScreen()));
      await tester.pump();
      expect(
        find.byIcon(Icons.photo_library_outlined).evaluate().isNotEmpty ||
        find.textContaining('Galería').evaluate().isNotEmpty,
        true,
      );
    });
  });

  // ── Estado inicial ───────────────────────────────────────────
  group('AnalisisScreen — estado inicial', () {
    testWidgets('no muestra resultados en estado inicial', (tester) async {
      await tester.pumpWidget(_buildApp(const AnalisisScreen()));
      await tester.pump();
      expect(find.textContaining('Patente'), findsNothing);
      expect(find.textContaining('Prescripción'), findsNothing);
    });
  });

  // ── Estado de carga ──────────────────────────────────────────
  group('AnalisisScreen — estado de carga', () {
    testWidgets('muestra indicador mientras procesa', (tester) async {
      when(() => mockOcr.reconocer(any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return OcrResult(textoCompleto: '', motor: 'mlkit');
      });

      await tester.pumpWidget(_buildApp(const AnalisisScreen()));
      await tester.pump();

      // Disparar evento de análisis
      final bloc = tester
          .element(find.byType(AnalisisScreen))
          .read<AnalisisBloc>();
      bloc.add(AnalizarImagenEvent(imagen: File('/tmp/test.jpg')));

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // ── Estado de error ──────────────────────────────────────────
  group('AnalisisScreen — estado de error', () {
    testWidgets('muestra mensaje si OCR falla', (tester) async {
      when(() => mockOcr.reconocer(any()))
          .thenThrow(Exception('Error de red'));

      await tester.pumpWidget(_buildApp(const AnalisisScreen()));
      await tester.pump();

      final bloc = tester
          .element(find.byType(AnalisisScreen))
          .read<AnalisisBloc>();
      bloc.add(const AnalisisImagenSeleccionada('/tmp/test.jpg'));

      await tester.pumpAndSettle();
      expect(
        find.textContaining('Error').evaluate().isNotEmpty ||
        find.textContaining('error').evaluate().isNotEmpty,
        true,
      );
    });
  });
}

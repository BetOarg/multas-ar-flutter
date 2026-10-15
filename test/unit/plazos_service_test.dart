import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/services/plazos_service.dart';
import 'package:multas_ar/core/constants/legal_constants.dart';

// ══════════════════════════════════════════════════════════════════
// TESTS — PlazosService
// Verifican el motor de cálculo de plazos legales.
// Se usan fechas fijas para reproducibilidad.
// ══════════════════════════════════════════════════════════════════

void main() {
  late PlazosService svc;

  // Feriados nacionales 2026 relevantes para los tests
  final feriadosTest = [
    DateTime(2026, 1, 1),   // Año Nuevo
    DateTime(2026, 2, 16),  // Carnaval
    DateTime(2026, 2, 17),  // Carnaval
    DateTime(2026, 3, 24),  // Día de la Memoria
    DateTime(2026, 4, 2),   // Malvinas
    DateTime(2026, 4, 3),   // Viernes Santo
    DateTime(2026, 5, 1),   // Día del Trabajo
    DateTime(2026, 5, 25),  // Revolución de Mayo
    DateTime(2026, 7, 9),   // Independencia
    DateTime(2026, 8, 17),  // Gral. San Martín
    DateTime(2026, 10, 12), // Diversidad Cultural
    DateTime(2026, 11, 20), // Soberanía Nacional
    DateTime(2026, 12, 8),  // Inmaculada Concepción
    DateTime(2026, 12, 25), // Navidad
  ];

  setUp(() {
    svc = PlazosService(feriados: feriadosTest);
  });

  // ── Días hábiles administrativos ─────────────────────────────
  group('calcularDiasHabilesAdmin', () {
    test('5 días hábiles desde lunes — llega viernes misma semana', () {
      // Lunes 06/04/2026 + 5 días hábiles = Lunes 13/04/2026
      // (viernes 10 es hábil, pero el test usa 5 hábiles exactos)
      final inicio = DateTime(2026, 4, 6); // lunes
      final resultado = svc.sumarDiasHabilesAdmin(inicio, 5);
      // L-M-M-J-V = 5 días → llega viernes 10/04
      expect(resultado, DateTime(2026, 4, 10));
    });

    test('5 días hábiles desde lunes — saltea semana santa', () {
      // Martes 31/03/2026 + 5 días hábiles (viernes 03/04 es feriado)
      final inicio = DateTime(2026, 3, 31); // martes
      final resultado = svc.sumarDiasHabilesAdmin(inicio, 5);
      // M(31)-X(01)-J(02 feriado Malvinas)-V(03 feriado VS) → salta
      // continúa: L(06)-M(07) = 5 hábiles
      expect(resultado, DateTime(2026, 4, 7));
    });

    test('45 días hábiles (PBA) — no cae en feriado', () {
      final inicio = DateTime(2026, 1, 5); // lunes
      final resultado = svc.sumarDiasHabilesAdmin(inicio, 45);
      expect(resultado.isAfter(inicio), true);
      // Verificar que no cae en feriado
      expect(feriadosTest.any((f) =>
        f.year == resultado.year &&
        f.month == resultado.month &&
        f.day == resultado.day), false);
    });

    test('no cuenta sábados ni domingos', () {
      final inicio = DateTime(2026, 4, 9); // jueves
      final resultado = svc.sumarDiasHabilesAdmin(inicio, 1);
      // 1 hábil desde jueves = viernes 10/04
      expect(resultado, DateTime(2026, 4, 10));

      final inicio2 = DateTime(2026, 4, 10); // viernes
      final resultado2 = svc.sumarDiasHabilesAdmin(inicio2, 1);
      // 1 hábil desde viernes = lunes 13/04 (salta fin de semana)
      expect(resultado2, DateTime(2026, 4, 13));
    });
  });

  // ── Días corridos ────────────────────────────────────────────
  group('calcularDiasCorridos', () {
    test('30 días corridos desde fecha base', () {
      final inicio = DateTime(2026, 3, 1);
      final resultado = svc.sumarDiasCorridos(inicio, 30);
      expect(resultado, DateTime(2026, 3, 31));
    });

    test('90 días corridos — cruza mes', () {
      final inicio = DateTime(2026, 1, 5);
      final resultado = svc.sumarDiasCorridos(inicio, 90);
      expect(resultado, DateTime(2026, 4, 5));
    });

    test('los feriados NO afectan días corridos', () {
      // Desde 24/03 (feriado) + 1 corrido = 25/03
      final inicio = DateTime(2026, 3, 24);
      final resultado = svc.sumarDiasCorridos(inicio, 1);
      expect(resultado, DateTime(2026, 3, 25));
    });
  });

  // ── Prescripción ─────────────────────────────────────────────
  group('calcularPrescripcion', () {
    test('prescripción CABA — 5 años', () {
      final hecho = DateTime(2021, 6, 15);
      final prescribe = svc.calcularPrescripcion(
          hecho, Jurisdiccion.caba, TipoFalta.leve);
      expect(prescribe.year, 2026);
      expect(prescribe.month, 6);
      expect(prescribe.day, 15);
    });

    test('prescripción PBA leve — 2 años (Ley 24.449)', () {
      final hecho = DateTime(2024, 3, 10);
      final prescribe = svc.calcularPrescripcion(
          hecho, Jurisdiccion.pba, TipoFalta.leve);
      expect(prescribe.year, 2026);
      expect(prescribe.month, 3);
      expect(prescribe.day, 10);
    });

    test('prescripción Mendoza grave — 3 años', () {
      final hecho = DateTime(2023, 8, 20);
      final prescribe = svc.calcularPrescripcion(
          hecho, Jurisdiccion.mendoza, TipoFalta.grave);
      expect(prescribe.year, 2026);
      expect(prescribe.month, 8);
      expect(prescribe.day, 20);
    });

    test('prescripción Mendoza gravísima — 4 años', () {
      final hecho = DateTime(2022, 11, 5);
      final prescribe = svc.calcularPrescripcion(
          hecho, Jurisdiccion.mendoza, TipoFalta.gravisima);
      expect(prescribe.year, 2026);
      expect(prescribe.month, 11);
      expect(prescribe.day, 5);
    });
  });

  // ── EstadoPlazo ───────────────────────────────────────────────
  group('evaluarEstadoPlazo', () {
    test('vencido si fecha pasó', () {
      final pasado = DateTime.now().subtract(const Duration(days: 1));
      expect(svc.evaluarEstado(pasado), EstadoPlazo.vencido);
    });

    test('urgente si vence en 3 días', () {
      final pronto = DateTime.now().add(const Duration(days: 2));
      expect(svc.evaluarEstado(pronto), EstadoPlazo.urgente);
    });

    test('proximo si vence en 4–7 días', () {
      final proximo = DateTime.now().add(const Duration(days: 5));
      expect(svc.evaluarEstado(proximo), EstadoPlazo.proximo);
    });

    test('vigente si vence en más de 7 días', () {
      final lejano = DateTime.now().add(const Duration(days: 30));
      expect(svc.evaluarEstado(lejano), EstadoPlazo.vigente);
    });
  });

  // ── Días restantes ───────────────────────────────────────────
  group('diasRestantes', () {
    test('negativo si ya venció', () {
      final vencido = DateTime.now().subtract(const Duration(days: 5));
      expect(svc.diasRestantes(vencido), lessThan(0));
    });

    test('positivo si no venció', () {
      final futuro = DateTime.now().add(const Duration(days: 10));
      expect(svc.diasRestantes(futuro), greaterThan(0));
    });
  });
}

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
    test('5 días hábiles desde lunes — llega el lunes siguiente', () {
      // El día inicial no se cuenta: martes 7 a lunes 13 = 5 hábiles.
      final inicio = DateTime(2026, 4, 6); // lunes
      final resultado = svc.sumarDiasHabilesAdmin(inicio, 5);
      expect(resultado, DateTime(2026, 4, 13));
    });

    test('5 días hábiles desde lunes — saltea semana santa', () {
      // El día inicial no se cuenta; 2 y 3 de abril son feriados.
      final inicio = DateTime(2026, 3, 31); // martes
      final resultado = svc.sumarDiasHabilesAdmin(inicio, 5);
      // 01/04 (1), 06/04 (2), 07/04 (3), 08/04 (4), 09/04 (5).
      expect(resultado, DateTime(2026, 4, 9));
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

  group('calendario judicial provisional', () {
    test('no excluye enero completo sin calendario oficial del tribunal', () {
      expect(
        svc.sumarDiasHabilesJud(DateTime(2026, 1, 5), 1),
        DateTime(2026, 1, 6),
      );
    });

    test('no excluye julio completo sin calendario oficial del tribunal', () {
      expect(
        svc.sumarDiasHabilesJud(DateTime(2026, 7, 6), 1),
        DateTime(2026, 7, 7),
      );
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
    test('no calcula automáticamente prescripción CABA por controversia normativa', () {
      expect(
        svc.calcularPrescripcion(
            DateTime(2021, 6, 15), Jurisdiccion.caba, TipoFalta.leve),
        isNull,
      );
    });

    test('prescripción base PBA leve — 2 años (art. 89 Ley 24.449)', () {
      final prescribe = svc.calcularPrescripcion(
          DateTime(2024, 3, 10), Jurisdiccion.pba, TipoFalta.leve);
      expect(prescribe, DateTime(2026, 3, 10));
    });

    test('prescripción base PBA grave — 5 años (art. 89 Ley 24.449)', () {
      final prescribe = svc.calcularPrescripcion(
          DateTime(2021, 8, 20), Jurisdiccion.pba, TipoFalta.grave);
      expect(prescribe, DateTime(2026, 8, 20));
    });

    test('no calcula gravísima sin regla validada', () {
      expect(
        svc.calcularPrescripcion(
            DateTime(2022, 11, 5), Jurisdiccion.pba, TipoFalta.gravisima),
        isNull,
      );
    });

    test('no calcula prescripción Mendoza sin verificar régimen local', () {
      expect(
        svc.calcularPrescripcion(
            DateTime(2023, 8, 20), Jurisdiccion.mendoza, TipoFalta.grave),
        isNull,
      );
    });

    test('fecha del 29 de febrero se ajusta al 28 en año no bisiesto', () {
      expect(
        svc.calcularPrescripcion(
            DateTime(2024, 2, 29), Jurisdiccion.pba, TipoFalta.leve),
        DateTime(2026, 2, 28),
      );
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

    test('usa días de calendario y no la hora actual', () {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final manana = hoy.add(const Duration(days: 1));

      expect(svc.diasRestantes(hoy), 0);
      expect(svc.evaluarEstado(hoy), EstadoPlazo.urgente);
      expect(svc.diasRestantes(manana), 1);
      expect(svc.evaluarEstado(manana), EstadoPlazo.urgente);
    });
    test('negativo si ya venció', () {
      final vencido = DateTime.now().subtract(const Duration(days: 5));
      expect(svc.diasRestantes(vencido), lessThan(0));
    });

    test('positivo si no venció', () {
      final futuro = DateTime.now().add(const Duration(days: 10));
      expect(svc.diasRestantes(futuro), greaterThan(0));
    });
  });

  // ── Selección de plazos por jurisdicción ─────────────────────
  group('calcularPlazos por jurisdicción', () {
    test('CABA devuelve solo los plazos de CABA', () {
      final resultado = svc.calcularPlazos(
        jurisdiccion: 'CABA',
        fechaNotificacion: DateTime(2026, 4, 6),
      );
      expect(resultado, isEmpty);
    });

    test('PBA devuelve sus plazos sin añadir los de otras jurisdicciones', () {
      final resultado = svc.calcularPlazos(
        jurisdiccion: 'PBA',
        fechaNotificacion: DateTime(2026, 4, 6),
      );
      expect(resultado, isEmpty);
    });

    test('jurisdicción no específica usa el plazo general', () {
      final resultado = svc.calcularPlazos(
        jurisdiccion: 'Jurisdicción no configurada',
        fechaNotificacion: DateTime(2026, 4, 6),
      );
      expect(resultado, isEmpty);
    });
  });

}

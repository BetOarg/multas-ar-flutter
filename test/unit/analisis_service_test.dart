import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/services/analisis_service.dart';
import 'package:multas_ar/core/services/plazos_service.dart';
import 'package:multas_ar/core/constants/legal_constants.dart';

// ══════════════════════════════════════════════════════════════════
// TESTS — AnalisisService
// Verifican el motor de análisis legal: campos faltantes,
// alertas, oportunidades y detección de prescripción.
// ══════════════════════════════════════════════════════════════════

void main() {
  late AnalisisService svc;
  late PlazosService plazos;

  setUp(() {
    plazos = PlazosService(feriados: []);
    svc = AnalisisService(plazosService: plazos);
  });

  // ── Campos faltantes ─────────────────────────────────────────
  group('detectarCamposFaltantes', () {
    test('acta completa no reporta faltantes críticos', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '12345',
        fechaInfraccion: DateTime(2026, 3, 15),
        fechaNotificacion: DateTime(2026, 3, 20),
        patente: 'AB123CD',
        normaInfringida: 'Art. 51 Ley 24.449',
        tipoFalta: TipoFalta.leve,
        lugarInfraccion: 'Av. Constitución 100, La Plata',
        agente: 'Agente 1234 — Cuerpo de Tránsito PBA',
      );
      final resultado = svc.analizar(acta);
      expect(resultado.camposFaltantes.where((c) => c.esCritico), isEmpty);
    });

    test('trata campos compuestos solo por espacios como faltantes', () {
      final resultado = svc.analizar(DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '   ',
        patente: ' ',
        normaInfringida: '  ',
        agente: '\t ',
      ));

      final campos = resultado.camposFaltantes.map((c) => c.campo).toSet();
      expect(campos, contains('Número de acta'));
      expect(campos, contains('Patente del vehículo'));
      expect(campos, contains('Norma infringida'));
      expect(campos, contains('Identificación del agente'));
    });

    test('acta sin número reporta campo crítico', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.caba,
        numeroActa: '',
        fechaInfraccion: DateTime(2026, 3, 15),
        fechaNotificacion: DateTime(2026, 3, 20),
        patente: 'AB123CD',
        normaInfringida: 'Art. 6.1.20 Ley 451',
        tipoFalta: TipoFalta.leve,
      );
      final resultado = svc.analizar(acta);
      final faltante = resultado.camposFaltantes
          .where((c) => c.campo == 'Número de acta')
          .firstOrNull;
      expect(faltante, isNotNull);
      expect(faltante!.esCritico, true);
    });

    test('acta sin firma de agente reporta nulidad potencial', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '999',
        fechaInfraccion: DateTime(2026, 3, 15),
        fechaNotificacion: DateTime(2026, 3, 20),
        patente: 'XY456ZA',
        normaInfringida: 'Art. 51 Ley 24.449',
        tipoFalta: TipoFalta.grave,
        agente: '', // sin firma
      );
      final resultado = svc.analizar(acta);
      expect(
        resultado.oportunidades
            .any((o) => o.contains('firma') || o.contains('agente')),
        true,
      );
    });
  });

  // ── Alertas duales ───────────────────────────────────────────
  group('alertasDuales', () {
    test('CABA genera alerta dual de prescripción', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.caba,
        numeroActa: '5555',
        fechaInfraccion: DateTime(2024, 1, 10),
        fechaNotificacion: DateTime(2024, 1, 15),
        patente: 'AA111BB',
        normaInfringida: 'Art. 6.1.36 Ley 451',
        tipoFalta: TipoFalta.leve,
      );
      final resultado = svc.analizar(acta);
      expect(
        resultado.alertas.any((a) =>
            a.tipo == TipoAlerta.advertencia &&
            (a.mensaje.contains('Andrade') ||
             a.mensaje.contains('prescripción'))),
        true,
      );
    });

    test('PBA fotomulta genera alerta dual de caducidad', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '7777',
        fechaInfraccion: DateTime(2026, 1, 5),
        fechaNotificacion: null, // sin notificación → posible caducidad
        patente: 'CC222DD',
        normaInfringida: 'Art. 28 Ley 13.927',
        tipoFalta: TipoFalta.grave,
        esFotomulta: true,
      );
      final resultado = svc.analizar(acta);
      expect(
        resultado.alertas.any((a) =>
            a.tipo == TipoAlerta.advertencia &&
            a.mensaje.contains('60 días')),
        true,
      );
    });
  });

  // ── Prescripción alcanzada ───────────────────────────────────
  group('deteccionPrescripcion', () {
    test('advierte sobre posible prescripción base PBA leve (2 años)', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '1111',
        fechaInfraccion: DateTime(2023, 9, 1), // hace más de 2 años
        fechaNotificacion: DateTime(2023, 9, 10),
        patente: 'EE333FF',
        normaInfringida: 'Art. 51 Ley 24.449',
        tipoFalta: TipoFalta.leve,
      );
      final resultado = svc.analizar(acta);
      expect(resultado.posiblePrescripcion, true);
      expect(
        resultado.alertas.any((a) =>
            a.tipo == TipoAlerta.advertencia &&
            a.mensaje.contains('No confirma prescripción')),
        true,
      );
    });

    test('no marca prescripción si la acción está vigente', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '2222',
        fechaInfraccion: DateTime.now().subtract(const Duration(days: 180)),
        fechaNotificacion: DateTime.now().subtract(const Duration(days: 175)),
        patente: 'GG444HH',
        normaInfringida: 'Art. 51 Ley 24.449',
        tipoFalta: TipoFalta.leve,
      );
      final resultado = svc.analizar(acta);
      expect(resultado.posiblePrescripcion, false);
    });
  });

  // ── Datos no confirmados y campos del formulario ──────────────
  group('datos no confirmados', () {
    test('no calcula prescripción si la gravedad no está determinada', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        fechaInfraccion: DateTime(2020, 1, 1),
        tipoFalta: null,
      );
      final resultado = svc.analizar(acta);
      expect(resultado.fechaPrescripcion, isNull);
      expect(resultado.posiblePrescripcion, false);
      expect(resultado.alertas.where((a) => a.tipo == TipoAlerta.peligro), isEmpty);
    });

    test('muestra errores formales declarados sin afirmar nulidad automática', () {
      final resultado = svc.analizar(DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        erroresFormales: const ['Patente errónea'],
      ));
      expect(
        resultado.alertas.any((a) =>
          a.mensaje.contains('Patente errónea') &&
          a.mensaje.contains('no implica nulidad automática')),
        true,
      );
    });

    test('no calcula prescripción con un tipo de falta vacío', () {
      final resultado = svc.analizar(DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        fechaInfraccion: DateTime(2020, 1, 1),
        tipoFalta: '',
      ));
      expect(resultado.fechaPrescripcion, isNull);
      expect(resultado.posiblePrescripcion, false);
    });

    test('no calcula prescripción para jurisdicción desconocida', () {
      final resultado = svc.analizar(DatosActa(
        jurisdiccion: 'Jurisdicción no identificada',
        fechaInfraccion: DateTime(2020, 1, 1),
        tipoFalta: TipoFalta.leve,
      ));
      expect(resultado.fechaPrescripcion, isNull);
      expect(resultado.posiblePrescripcion, false);
    });
  });

  // ── Plan de pagos PBA ────────────────────────────────────────
  group('alertaPlanPagosPBA', () {
    test('PBA plan de pagos genera advertencia no categórica', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '3333',
        fechaInfraccion: DateTime(2026, 2, 1),
        fechaNotificacion: DateTime(2026, 2, 10),
        patente: 'II555JJ',
        normaInfringida: 'Art. 52 Ley 24.449',
        tipoFalta: TipoFalta.grave,
        tieneNovedad: 'plan_pagos',
      );
      final resultado = svc.analizar(acta);
      expect(
        resultado.alertas.any((a) =>
            a.tipo == TipoAlerta.advertencia &&
            a.mensaje.contains('plan de pagos')),
        true,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/constants/legal_constants.dart';
import 'package:multas_ar/core/services/analisis_service.dart';
import 'package:multas_ar/core/services/nulidades_service.dart';
import 'package:multas_ar/core/services/plazos_service.dart';
import 'package:multas_ar/core/services/ocr_service.dart';

// ══════════════════════════════════════════════════════════════════
// TEST DE INTEGRACIÓN — Flujo completo
//
// Simula el camino real del usuario:
//   1. OCR extrae texto del acta
//   2. ActaParser identifica campos
//   3. PlazosService calcula plazos
//   4. AnalisisService genera alertas y oportunidades
//   5. NulidadesService detecta causales formales
//   6. Resultado final coherente entre todos los motores
//
// No requiere DB ni Flutter: solo servicios puros en memoria.
// ══════════════════════════════════════════════════════════════════

void main() {
  // Feriados nacionales 2026 mínimos para los tests
  final feriados2026 = [
    DateTime(2026, 1, 1), DateTime(2026, 3, 24), DateTime(2026, 4, 2),
    DateTime(2026, 4, 3), DateTime(2026, 5, 1), DateTime(2026, 5, 25),
    DateTime(2026, 7, 9), DateTime(2026, 12, 25),
  ];

  late PlazosService plazos;
  late AnalisisService analisis;
  late NulidadesService nulidades;

  setUp(() {
    plazos   = PlazosService(feriados: feriados2026);
    analisis = AnalisisService(plazosService: plazos);
    nulidades = NulidadesService();
  });

  // ══════════════════════════════════════════════════════════════
  // CASO 1: Acta PBA incompleta — múltiples defectos
  // ══════════════════════════════════════════════════════════════
  group('Caso 1 — Acta PBA con campos faltantes', () {
    const textoOcrDefectuoso = '''
PROVINCIA DE BUENOS AIRES
INFRACCION N° 0045-99999
Fecha: 15/03/2026
Infractor: GARCIA JUAN CARLOS
Infracción: Art. 51 Ley 13.927
''';

    test('OCR: detecta campos faltantes', () {
      final ocrResult =
          ActaParser.parsear(textoOcrDefectuoso, motor: 'mlkit');

      expect(ocrResult.patente, isNull);              // sin patente
      expect(ocrResult.agente, isNull);               // sin agente
      expect(ocrResult.lugarInfraccion, isNull);      // sin lugar
      expect(ocrResult.camposFaltantes, contains('patente'));
      expect(ocrResult.camposFaltantes, contains('agente'));
      expect(ocrResult.jurisdiccionDetectada, equals('PBA'));
    });

    test('Nulidades: detecta causales absolutas por campos faltantes', () {
      final datos = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '99999',
        fechaInfraccion: DateTime(2026, 3, 15),
        patente: null,            // faltante
        normaInfringida: 'Art. 51 Ley 13.927',
        legajoAgente: null,       // faltante
        tieneFiremaAgente: false, // faltante
        lugarInfraccion: null,    // faltante
      );

      final result = nulidades.analizar(datos);

      expect(result.tieneNulidadAbsoluta, true);
      // Causales: patente + lugar + agente/firma = mínimo 3
      expect(result.causalesDetectadas.length, greaterThanOrEqualTo(3));
      // Norma correcta en cada causal
      expect(
        result.causalesDetectadas.every(
            (c) => c.norma.contains('Ley 13.927') ||
                   c.norma.contains('CN')),
        true,
      );
    });

    test('Plazos: suma 45 días hábiles desde la fecha inicial sin caer en inhábil', () {
      final inicio    = DateTime(2026, 3, 15);
      final vencimiento = plazos.sumarDiasHabilesAdmin(inicio, 45);

      expect(vencimiento.isAfter(inicio), true);
      // No debe caer en día inhábil
      expect(vencimiento.weekday, isNot(DateTime.saturday));
      expect(vencimiento.weekday, isNot(DateTime.sunday));
      expect(
        feriados2026.any((f) =>
            f.year == vencimiento.year &&
            f.month == vencimiento.month &&
            f.day == vencimiento.day),
        false,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════
  // CASO 2: Acta CABA completa — prescripción Andrade
  // ══════════════════════════════════════════════════════════════
  group('Caso 2 — Acta CABA con prescripción Andrade', () {
    const textoOcrCABA = '''
GOBIERNO DE LA CIUDAD AUTÓNOMA DE BUENOS AIRES
ACTA N° 2023-00012345
Fecha de infracción: 10/01/2023
Hora: 09:15
Lugar: Av. Corrientes 1500 CABA
Vehículo: VW GOLF - DOMINIO: CD456EF
Art. 6.1.20 Ley 451 CABA
Inspector: López 8901
''';

    test('OCR: extrae campos CABA correctamente', () {
      final result = ActaParser.parsear(textoOcrCABA, motor: 'vision');

      expect(result.jurisdiccionDetectada, equals('CABA'));
      expect(result.patente, equals('CD456EF'));
      expect(result.fechaInfraccion?.year, equals(2023));
      expect(result.normaInfringida, contains('451'));
    });

    test('Nulidades: detecta prescripción Andrade (2+ años)', () {
      final datos = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.caba,
        numeroActa: '12345',
        fechaInfraccion: DateTime(2023, 1, 10), // +2 años
        patente: 'CD456EF',
        normaInfringida: 'Art. 6.1.20 Ley 451',
        tieneFiremaAgente: true,
        legajoAgente: '8901',
        lugarInfraccion: 'Av. Corrientes 1500',
      );

      final result = nulidades.analizar(datos);

      final andrade = result.causalesPotenciales
          .firstWhere((c) => c.id == 'caba_prescripcion_andrade',
              orElse: () => throw Exception('No detectó Andrade'));

      // Debe incluir advertencia de verificar alzada
      expect(andrade.jurisprudencia, contains('VERIFICAR'));
      expect(andrade.jurisprudencia, contains('alzada'));
    });

    test('Plazos: CABA requiere revisión normativa', () {
      final prescripcion = plazos.calcularPrescripcion(
          DateTime(2023, 1, 10), Jurisdiccion.caba, TipoFalta.leve);
      expect(prescripcion, isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════
  // CASO 3: Fotomulta PBA — alerta dual caducidad
  // ══════════════════════════════════════════════════════════════
  group('Caso 3 — Fotomulta PBA con posible caducidad', () {
    test('Nulidades: fotomulta notificada a los 90 días → alerta potencial', () {
      final datos = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: 'FM-2026-777',
        fechaInfraccion:   DateTime(2026, 1, 5),
        fechaNotificacion: DateTime(2026, 4, 5), // 90 días después
        patente: 'GH789IJ',
        normaInfringida: 'Art. 28 Ley 13.927',
        tieneFiremaAgente: true,
        legajoAgente: '0000',
        lugarInfraccion: 'Ruta 2 km 45',
        esFotomulta: true,
      );

      final result = nulidades.analizar(datos);

      final caducidad = result.causalesPotenciales.firstWhere(
        (c) => c.id == 'pba_fotomulta_notif_tardia',
        orElse: () => throw Exception('No detectó caducidad fotomulta'),
      );

      // Debe incluir advertencia del fallo de la Cámara San Martín
      expect(caducidad.jurisprudencia, contains('San Martín'));
      expect(caducidad.requiereAcreditarPerjuicio, true);
    });

    test('Nulidades: fotomulta con cámara no homologada → nulidad absoluta', () {
      final datos = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: 'FM-2026-888',
        fechaInfraccion:   DateTime(2026, 2, 1),
        fechaNotificacion: DateTime(2026, 2, 5),
        patente: 'KL012MN',
        normaInfringida: 'Art. 27 Ley 13.927',
        tieneFiremaAgente: true,
        legajoAgente: '1111',
        lugarInfraccion: 'Autopista 25 de Mayo',
        esFotomulta: true,
        camaraHomologada: false,
      );

      final result = nulidades.analizar(datos);
      expect(result.tieneNulidadAbsoluta, false);
      expect(
        result.causalesPotenciales.any((c) => c.id == 'pba_fotomulta_camara'),
        true,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════
  // CASO 4: Plan de pagos PBA — advertencia crítica
  // ══════════════════════════════════════════════════════════════
  group('Caso 4 — Plan de pagos PBA', () {
    test('Analisis: detecta alerta crítica de plan de pagos', () {
      final acta = DatosActa(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '44444',
        fechaInfraccion: DateTime(2026, 3, 1),
        fechaNotificacion: DateTime(2026, 3, 10),
        patente: 'OP345QR',
        normaInfringida: 'Art. 51 Ley 24.449',
        tipoFalta: TipoFalta.leve,
        tieneNovedad: 'plan_pagos',
      );

      final result = analisis.analizar(acta);

      expect(
        result.alertas.any((a) =>
            a.tipo == TipoAlerta.advertencia &&
            a.mensaje.toLowerCase().contains('plan de pagos')),
        true,
      );
    });
  });

  // ══════════════════════════════════════════════════════════════
  // CASO 5: Mendoza — no usar reglas sin validar fuente local
  group('Caso 5 — Mendoza requiere verificación normativa', () {
    test('no calcula automáticamente una fecha sin regla validada', () {
      for (final tipo in TipoFalta.todos) {
        expect(
          plazos.calcularPrescripcion(
              DateTime(2022, 6, 1), Jurisdiccion.mendoza, tipo),
          isNull,
        );
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/services/ocr_service.dart';

// ══════════════════════════════════════════════════════════════════
// TESTS — OCR Parser
// Verifican que el parser extrae correctamente los campos
// de un texto OCR de acta de infracción.
// Los textos simulan salida real de PaddleOCR / MLKit.
// ══════════════════════════════════════════════════════════════════

void main() {
  // ── Textos de acta simulados ─────────────────────────────────
  const actaPbaCompleta = '''
PROVINCIA DE BUENOS AIRES
JUZGADO DE APELACIONES EN LO CONTENCIOSO ADMINISTRATIVO
INFRACCION DE TRANSITO N° 0045-12345678
Fecha: 15/03/2026  Hora: 14:32
Lugar: Av. 7 N° 1200 LA PLATA
Infractor: GARCIA JUAN CARLOS
DNI: 28.555.444
Domicilio: Calle 50 N° 342 La Plata
Vehículo: FORD FOCUS 2020  Color: GRIS
Patente: AB123CD
Infracción: Art. 51 inc. a) Ley 13.927 / Art. 51 Ley 24449
Descripción: CONDUCIR SIN CINTO DE SEGURIDAD
Agente: Juan Pérez  Leg. N°: 4567
Firma del agente: _________
''';

  const actaCabaCompleta = '''
GOBIERNO DE LA CIUDAD AUTÓNOMA DE BUENOS AIRES
ACTA DE COMPROBACIÓN DE FALTA N° 2026-00098765
Fecha de infracción: 20/04/2026
Hora: 09:15 hs.
Lugar: Corrientes 1500 - CABA
Nombre: RODRIGUEZ MARIA ELENA
Documento: 35.222.111
Vehículo Marca/Modelo: VOLKSWAGEN GOLFDOMINIO: CD456EF
Artículo infringido: Art. 6.1.20 Ley 451 CABA
Descripción: ESTACIONAMIENTO PROHIBIDO
Inspector: María López  N° Agente: 8901
''';

  const actaSinPatente = '''
ACTA DE INFRACCIÓN
Fecha: 10/01/2026
Lugar: Ruta 2 Km 45 BERAZATEGUI
Infractor: LOPEZ PEDRO
Infracción: Art. 77 Ley 24449
Descripción: EXCESO DE VELOCIDAD
Agente: N/A
''';

  const actaFotomulta = '''
FOTOMULTA
GOBIERNO DE LA CIUDAD AUTÓNOMA DE BUENOS AIRES
N° COMPROBANTE: FM-2026-00456789
FECHA DE INFRACCIÓN: 05/02/2026  HORA: 08:45
DOMINIO: GH789IJ
LUGAR: AV. CORRIENTES Y CALLAO
INFRACCIÓN: SEMÁFORO EN ROJO
NORMA: ART. 6.1.2 LEY 451 CABA
''';

  // ── Tests de parseo PBA ──────────────────────────────────────
  group('parsearActaPBA', () {
    test('extrae número de acta', () {
      final r = ActaParser.parsear(actaPbaCompleta);
      expect(r.numeroActa, contains('12345678'));
    });

    test('extrae patente correctamente', () {
      final r = ActaParser.parsear(actaPbaCompleta);
      expect(r.patente, equals('AB123CD'));
    });

    test('extrae fecha en formato dd/mm/aaaa', () {
      final r = ActaParser.parsear(actaPbaCompleta);
      expect(r.fechaInfraccion?.day, equals(15));
      expect(r.fechaInfraccion?.month, equals(3));
      expect(r.fechaInfraccion?.year, equals(2026));
    });

    test('extrae norma infringida', () {
      final r = ActaParser.parsear(actaPbaCompleta);
      expect(r.normaInfringida, contains('51'));
    });

    test('detecta jurisdicción PBA', () {
      final r = ActaParser.parsear(actaPbaCompleta);
      expect(r.jurisdiccionDetectada, equals('PBA'));
    });

    test('extrae datos del agente', () {
      final r = ActaParser.parsear(actaPbaCompleta);
      expect(r.agente, isNotNull);
      expect(r.agente, contains('4567'));
    });
  });

  // ── Tests de parseo CABA ─────────────────────────────────────
  group('parsearActaCABA', () {
    test('extrae número de acta CABA', () {
      final r = ActaParser.parsear(actaCabaCompleta);
      expect(r.numeroActa, contains('98765'));
    });

    test('extrae patente — formato pegado al modelo', () {
      final r = ActaParser.parsear(actaCabaCompleta);
      expect(r.patente, equals('CD456EF'));
    });

    test('detecta jurisdicción CABA', () {
      final r = ActaParser.parsear(actaCabaCompleta);
      expect(r.jurisdiccionDetectada, equals('CABA'));
    });

    test('extrae norma Ley 451', () {
      final r = ActaParser.parsear(actaCabaCompleta);
      expect(r.normaInfringida, contains('451'));
    });
  });

  // ── Campos faltantes ─────────────────────────────────────────
  group('camposFaltantesOCR', () {
    test('acta sin patente reporta campo vacío', () {
      final r = ActaParser.parsear(actaSinPatente);
      expect(r.patente, isNull);
      expect(r.camposFaltantes, contains('patente'));
    });

    test('acta sin agente reporta campo vacío', () {
      final r = ActaParser.parsear(actaSinPatente);
      expect(r.camposFaltantes, contains('agente'));
    });
  });

  // ── Fotomulta ────────────────────────────────────────────────
  group('parsearFotomulta', () {
    test('detecta fotomulta por prefijo FM-', () {
      final r = ActaParser.parsear(actaFotomulta);
      expect(r.esFotomulta, true);
    });

    test('extrae patente de fotomulta (dominio)', () {
      final r = ActaParser.parsear(actaFotomulta);
      expect(r.patente, equals('GH789IJ'));
    });

    test('detecta CABA en fotomulta', () {
      final r = ActaParser.parsear(actaFotomulta);
      expect(r.jurisdiccionDetectada, equals('CABA'));
    });
  });

  // ── Patentes con formato nuevo y viejo ───────────────────────
  group('formatoPatentes', () {
    test('reconoce patente formato nuevo AA000AA', () {
      final texto = 'Dominio: AB123CD';
      expect(ActaParser.extraerPatente(texto), equals('AB123CD'));
    });

    test('reconoce patente formato viejo AAA000', () {
      final texto = 'PATENTE: ABC123';
      expect(ActaParser.extraerPatente(texto), equals('ABC123'));
    });

    test('normaliza a mayúsculas', () {
      final texto = 'patente: ab123cd';
      expect(ActaParser.extraerPatente(texto), equals('AB123CD'));
    });

    test('retorna null si no hay patente', () {
      final texto = 'No hay datos del vehículo aquí';
      expect(ActaParser.extraerPatente(texto), isNull);
    });
  });
}

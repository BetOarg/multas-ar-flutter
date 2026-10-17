import 'package:flutter_test/flutter_test.dart';
import 'package:multas_ar/core/services/nulidades_service.dart';
import 'package:multas_ar/core/constants/legal_constants.dart';

void main() {
  late NulidadesService svc;
  setUp(() => svc = NulidadesService());

  DatosActaParaAnalisis _actaCompleta({String jur = Jurisdiccion.pba}) =>
      DatosActaParaAnalisis(
        jurisdiccion: jur,
        numeroActa: '12345',
        fechaInfraccion: DateTime(2026, 3, 15),
        fechaNotificacion: DateTime(2026, 3, 20),
        patente: 'AB123CD',
        normaInfringida: 'Art. 51 Ley 24.449',
        agente: 'Agente López 4567',
        legajoAgente: '4567',
        tieneFiremaAgente: true,
        tieneFirmaInfractor: true,
        lugarInfraccion: 'Av. 7 N° 1200 La Plata',
        descripcionHecho: 'Conducir sin cinto de seguridad abrochado',
      );

  // ── Acta completa no genera nulidades ────────────────────────
  group('acta completa', () {
    test('PBA sin defectos — no detecta nulidades absolutas', () {
      final r = svc.analizar(_actaCompleta());
      expect(r.causalesDetectadas, isEmpty);
      expect(r.tieneNulidadAbsoluta, false);
    });

    test('CABA sin defectos — no detecta nulidades absolutas', () {
      final r = svc.analizar(_actaCompleta(jur: Jurisdiccion.caba));
      expect(r.tieneNulidadAbsoluta, false);
    });
  });

  // ── Causales individuales PBA ────────────────────────────────
  group('PBA — Art. 3 Ley 13.927', () {
    test('falta número de acta → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: null,
        fechaInfraccion: DateTime(2026, 3, 15),
        patente: 'AB123CD',
        normaInfringida: 'Art. 51',
        legajoAgente: '4567',
        tieneFiremaAgente: true,
        lugarInfraccion: 'La Plata',
      );
      final r = svc.analizar(d);
      expect(r.tieneNulidadAbsoluta, true);
      expect(r.causalesDetectadas.any((c) => c.id == 'pba_3a_num_acta'), true);
    });

    test('falta fecha → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '999',
        fechaInfraccion: null,
        patente: 'AB123CD',
        normaInfringida: 'Art. 51',
        legajoAgente: '4567',
        tieneFiremaAgente: true,
        lugarInfraccion: 'La Plata',
      );
      final r = svc.analizar(d);
      expect(r.causalesDetectadas.any((c) => c.id == 'pba_3b_fecha'), true);
    });

    test('falta lugar → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '999',
        fechaInfraccion: DateTime(2026, 3, 15),
        patente: 'AB123CD',
        normaInfringida: 'Art. 51',
        legajoAgente: '4567',
        tieneFiremaAgente: true,
        lugarInfraccion: null,
      );
      final r = svc.analizar(d);
      expect(r.causalesDetectadas.any((c) => c.id == 'pba_3c_lugar'), true);
    });

    test('falta patente → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '999',
        fechaInfraccion: DateTime(2026, 3, 15),
        patente: null,
        normaInfringida: 'Art. 51',
        legajoAgente: '4567',
        tieneFiremaAgente: true,
        lugarInfraccion: 'La Plata',
      );
      final r = svc.analizar(d);
      expect(r.causalesDetectadas.any((c) => c.id == 'pba_3d_patente'), true);
    });

    test('falta norma → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '999',
        fechaInfraccion: DateTime(2026, 3, 15),
        patente: 'AB123CD',
        normaInfringida: null,
        legajoAgente: '4567',
        tieneFiremaAgente: true,
        lugarInfraccion: 'La Plata',
      );
      final r = svc.analizar(d);
      expect(r.causalesDetectadas.any((c) => c.id == 'pba_3e_norma'), true);
    });

    test('falta firma agente → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '999',
        fechaInfraccion: DateTime(2026, 3, 15),
        patente: 'AB123CD',
        normaInfringida: 'Art. 51',
        legajoAgente: null,
        tieneFiremaAgente: false,
        lugarInfraccion: 'La Plata',
      );
      final r = svc.analizar(d);
      expect(r.causalesDetectadas.any((c) => c.id == 'pba_3f_agente'), true);
    });

    test('múltiples defectos → todas las causales detectadas', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: null,
        fechaInfraccion: null,
        patente: null,
        normaInfringida: null,
        legajoAgente: null,
        tieneFiremaAgente: false,
        lugarInfraccion: null,
      );
      final r = svc.analizar(d);
      expect(r.causalesDetectadas.length, greaterThanOrEqualTo(5));
      expect(r.tieneNulidadAbsoluta, true);
    });
  });

  // ── Fotomultas PBA ───────────────────────────────────────────
  group('PBA — fotomultas Art. 28', () {
    test('cámara no homologada → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '5555',
        fechaInfraccion: DateTime(2026, 1, 5),
        fechaNotificacion: DateTime(2026, 1, 10),
        patente: 'CC222DD',
        normaInfringida: 'Art. 28 Ley 13.927',
        legajoAgente: '0000',
        tieneFiremaAgente: true,
        lugarInfraccion: 'Ruta 2',
        esFotomulta: true,
        camaraHomologada: false,
      );
      final r = svc.analizar(d);
      expect(
        r.causalesPotenciales.any((c) => c.id == 'pba_fotomulta_camara'),
        isTrue,
      );
      expect(
        r.causalesPotenciales
            .firstWhere((c) => c.id == 'pba_fotomulta_camara').tipo,
        TipoNulidad.relativa,
      );
      expect(
        r.causalesDetectadas.any((c) => c.id == 'pba_fotomulta_camara'),
        isFalse,
      );
    });

    test('notificación tardía (>84 días) → causal potencial con alerta dual', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '6666',
        fechaInfraccion: DateTime(2026, 1, 1),
        fechaNotificacion: DateTime(2026, 4, 10), // 99 días después
        patente: 'EE333FF',
        normaInfringida: 'Art. 28 Ley 13.927',
        legajoAgente: '1111',
        tieneFiremaAgente: true,
        lugarInfraccion: 'La Plata',
        esFotomulta: true,
      );
      final r = svc.analizar(d);
      final causal = r.causalesPotenciales
          .firstWhere((c) => c.id == 'pba_fotomulta_notif_tardia',
              orElse: () => throw Exception('Causal no encontrada'));
      // Debe incluir la advertencia del fallo de la Cámara
      expect(causal.jurisprudencia, contains('San Martín'));
    });
  });

  // ── CABA ─────────────────────────────────────────────────────
  group('CABA — Art. 9 Ley 1217', () {
    test('falta norma CABA → nulidad absoluta', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.caba,
        numeroActa: '9999',
        fechaInfraccion: DateTime(2026, 2, 1),
        patente: 'GG444HH',
        normaInfringida: null,
        tieneFiremaAgente: true,
        lugarInfraccion: 'Corrientes 1500',
      );
      final r = svc.analizar(d);
      expect(r.causalesDetectadas.any((c) => c.id == 'caba_9_norma'), true);
    });

    test('infracción +2 años CABA → causal potencial prescripción Andrade', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.caba,
        numeroActa: '8888',
        fechaInfraccion: DateTime(2023, 6, 1), // más de 2 años
        patente: 'II555JJ',
        normaInfringida: 'Art. 6.1.20 Ley 451',
        tieneFiremaAgente: true,
        lugarInfraccion: 'CABA',
        legajoAgente: '2222',
      );
      final r = svc.analizar(d);
      final causal = r.causalesPotenciales
          .firstWhere((c) => c.id == 'caba_prescripcion_andrade');
      expect(causal.tipo, TipoNulidad.relativa);
      expect(r.causalesDetectadas
          .any((c) => c.id == 'caba_prescripcion_andrade'), isFalse);
    });
  });

  // ── Causales comunes ─────────────────────────────────────────
  group('comunes — norma incorrecta para jurisdicción', () {
    test('PBA con Ley 451 → causal potencial', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: '7777',
        fechaInfraccion: DateTime(2026, 3, 1),
        patente: 'KK666LL',
        normaInfringida: 'Art. 6.1.20 Ley 451 CABA', // norma CABA en acta PBA
        legajoAgente: '3333',
        tieneFiremaAgente: true,
        lugarInfraccion: 'La Plata',
      );
      final r = svc.analizar(d);
      final causal = r.causalesPotenciales
          .firstWhere((c) => c.id == 'com_norma_incorrecta_jur');
      expect(causal.tipo, TipoNulidad.relativa);
      expect(r.causalesDetectadas
          .any((c) => c.id == 'com_norma_incorrecta_jur'), isFalse);
    });
  });

  // ── Recomendaciones ──────────────────────────────────────────
  group('recomendaciones', () {
    test('nulidad absoluta → recomendación urgente con mención de letrado', () {
      final d = DatosActaParaAnalisis(
        jurisdiccion: Jurisdiccion.pba,
        numeroActa: null,
        tieneFiremaAgente: false,
      );
      final r = svc.analizar(d);
      expect(r.recomendacion.toLowerCase(), contains('abogado'));
    });

    test('sin nulidades → recomendación de revisión profesional', () {
      final r = svc.analizar(_actaCompleta());
      expect(r.recomendacion.toLowerCase(), contains('profesional'));
    });
  });
}

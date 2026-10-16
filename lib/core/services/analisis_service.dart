import 'plazos_service.dart';
import '../constants/legal_constants.dart';

// ══════════════════════════════════════════════════════════════════
// ANALISIS SERVICE — implementación completa
// Motor de análisis legal del acta: detecta campos faltantes,
// genera alertas duales, identifica oportunidades defensivas
// y calcula prescripción.
// ══════════════════════════════════════════════════════════════════

// ── Tipos de alerta ───────────────────────────────────────────────
enum TipoAlerta { peligro, advertencia, info }

class AlertaLegal {
  final TipoAlerta tipo;
  final String mensaje;
  final String? norma;
  const AlertaLegal({required this.tipo, required this.mensaje, this.norma});
}

class CampoFaltante {
  final String campo;
  final String norma;
  final bool esCritico;
  const CampoFaltante({
    required this.campo,
    required this.norma,
    this.esCritico = false,
  });
}

class ResultadoAnalisis {
  final List<CampoFaltante> camposFaltantes;
  final List<AlertaLegal> alertas;
  final List<String> oportunidades;
  final bool posiblePrescripcion;
  final DateTime? fechaPrescripcion;
  final List<PlazoCalculado> plazos;

  const ResultadoAnalisis({
    this.camposFaltantes = const [],
    this.alertas         = const [],
    this.oportunidades   = const [],
    this.posiblePrescripcion = false,
    this.fechaPrescripcion,
    this.plazos = const [],
  });
}

// ── Datos de entrada ──────────────────────────────────────────────
class DatosActa {
  final String jurisdiccion;
  final String? numeroActa;
  final DateTime? fechaInfraccion;
  final DateTime? fechaNotificacion;
  final String? patente;
  final String? normaInfringida;
  final String? tipoFalta;
  final String? lugarInfraccion;
  final String? agente;
  final bool esFotomulta;
  final String? tieneNovedad; // 'plan_pagos', etc.
  final List<String> erroresFormales;
  final bool? titularEsConductor;
  final String? estadoProcesal;
  final bool vaJudicial;
  final bool agotamientoVia;

  const DatosActa({
    required this.jurisdiccion,
    this.numeroActa,
    this.fechaInfraccion,
    this.fechaNotificacion,
    this.patente,
    this.normaInfringida,
    this.tipoFalta,
    this.lugarInfraccion,
    this.agente,
    this.esFotomulta = false,
    this.tieneNovedad,
    this.erroresFormales = const [],
    this.titularEsConductor,
    this.estadoProcesal,
    this.vaJudicial = false,
    this.agotamientoVia = false,
  });
}

// ══════════════════════════════════════════════════════════════════
class AnalisisService {
  final PlazosService plazosService;

  AnalisisService({required this.plazosService});

  ResultadoAnalisis analizar(DatosActa acta) {
    final faltantes    = <CampoFaltante>[];
    final alertas      = <AlertaLegal>[];
    final oportunidades = <String>[];

    // ── Campos faltantes ────────────────────────────────────────
    if (acta.numeroActa == null || acta.numeroActa!.isEmpty) {
      faltantes.add(const CampoFaltante(
        campo:      'Número de acta',
        norma:      'Art. 3 Ley 13.927 / Art. 9 Ley 1217',
        esCritico:  true,
      ));
      oportunidades.add('Falta número de acta — posible nulidad formal');
    }
    if (acta.patente == null || acta.patente!.isEmpty) {
      faltantes.add(const CampoFaltante(
        campo:     'Patente del vehículo',
        norma:     'Art. 3 inc. d) Ley 13.927',
        esCritico: true,
      ));
      oportunidades.add('Falta patente — posible nulidad formal');
    }
    if (acta.fechaInfraccion == null) {
      faltantes.add(const CampoFaltante(
        campo:     'Fecha de la infracción',
        norma:     'Art. 3 inc. b) Ley 13.927',
        esCritico: true,
      ));
    }
    if (acta.normaInfringida == null || acta.normaInfringida!.isEmpty) {
      faltantes.add(const CampoFaltante(
        campo:     'Norma infringida',
        norma:     'Art. 3 inc. e) Ley 13.927 — Art. 18 CN',
        esCritico: true,
      ));
      oportunidades.add('Falta norma — vulnera principio de tipicidad');
    }
    if (acta.agente == null || acta.agente!.isEmpty) {
      faltantes.add(const CampoFaltante(
        campo:     'Identificación del agente',
        norma:     'Art. 3 inc. f) Ley 13.927',
        esCritico: true,
      ));
      oportunidades.add('Falta firma o legajo del agente — posible nulidad absoluta');
    }

    // Los errores formales son datos declarados por el usuario, no
    // conclusiones automáticas de nulidad.
    for (final error in acta.erroresFormales) {
      alertas.add(AlertaLegal(
        tipo: TipoAlerta.advertencia,
        mensaje: 'Error formal informado: $error. Verificar contra el acta original y la normativa aplicable; no implica nulidad automática.',
      ));
    }
    if (acta.titularEsConductor == false) {
      alertas.add(const AlertaLegal(
        tipo: TipoAlerta.info,
        mensaje: 'El usuario indicó que el titular no era quien conducía. Verificar identificación del conductor y régimen aplicable.',
      ));
    }
    if (acta.vaJudicial || acta.agotamientoVia) {
      alertas.add(const AlertaLegal(
        tipo: TipoAlerta.info,
        mensaje: 'Se informó una instancia judicial o agotamiento de la vía administrativa. Revisar expediente y plazos específicos antes de actuar.',
      ));
    }

    // ── Prescripción ────────────────────────────────────────────
    bool prescripto = false;
    DateTime? fechaPresc;
    if (acta.fechaInfraccion != null && acta.tipoFalta != null) {
      fechaPresc = plazosService.calcularPrescripcion(
          acta.fechaInfraccion!, acta.jurisdiccion, acta.tipoFalta!);
      prescripto = DateTime.now().isAfter(fechaPresc);

      if (prescripto) {
        alertas.add(AlertaLegal(
          tipo:    TipoAlerta.peligro,
          mensaje: '🚨 POSIBLE PRESCRIPCIÓN: la acción podría estar '
                   'extinguida desde ${_fmt(fechaPresc)}. '
                   'Verificar con letrado.',
          norma:   NormasBase.art89Prescrip,
        ));
        oportunidades.add('Interponer prescripción como defensa principal');
      }
    }

    // ── Alertas duales ──────────────────────────────────────────
    if (acta.jurisdiccion == Jurisdiccion.caba &&
        acta.fechaInfraccion != null) {
      final anios = DateTime.now()
          .difference(acta.fechaInfraccion!)
          .inDays / 365.25;
      if (anios >= 2) {
        alertas.add(const AlertaLegal(
          tipo: TipoAlerta.advertencia,
          mensaje: '⚠️ ALERTA DUAL — PRESCRIPCIÓN CABA: '
                   'Ley 451 establece 5 años, pero el Fallo Andrade '
                   '(PCyF N°15, 30/05/2023) aplica 2 años vía '
                   'Art. 89 Ley 24.449. Verificar estado en alzada '
                   'antes de invocar.',
          norma:  'Fallo Andrade — Juzgado PCyF N°15 CABA (30/05/2023)',
        ));
      }
    }

    if (acta.jurisdiccion == Jurisdiccion.pba && acta.esFotomulta) {
      alertas.add(const AlertaLegal(
        tipo: TipoAlerta.advertencia,
        mensaje: '⚠️ ALERTA DUAL — FOTOMULTAS PBA: '
                 'Art. 28 Ley 13.927 establece 60 días hábiles para notificar. '
                 'La Cámara de San Martín Sala I (2018, Exp. 37.639) '
                 'lo considera plazo ordenatorio. '
                 'Oponer acreditando perjuicio concreto.',
        norma:  'Art. 28 Ley 13.927 PBA',
      ));
    }

    // ── Plan de pagos PBA ────────────────────────────────────────
    if (acta.jurisdiccion == Jurisdiccion.pba &&
        acta.tieneNovedad == 'plan_pagos') {
      alertas.add(const AlertaLegal(
        tipo: TipoAlerta.peligro,
        mensaje: '🚨 PLAN DE PAGOS PBA: la adhesión al plan de pagos '
                 'implica reconocimiento irrevocable de deuda y RENUNCIA '
                 'a todos los recursos. No gestionar sin asesoramiento legal.',
        norma:  NormasBase.art35PlanPagos,
      ));
    }

    // ── Plazos ──────────────────────────────────────────────────
    List<PlazoCalculado> plazos = [];
    if (acta.fechaNotificacion != null) {
      plazos = plazosService.calcularPlazos(
        jurisdiccion:      acta.jurisdiccion,
        fechaNotificacion: acta.fechaNotificacion!,
        esFotomulta:       acta.esFotomulta,
      );

      // Alerta si hay plazos urgentes o vencidos
      final urgentes = plazos
          .where((p) =>
              p.estado == EstadoPlazo.urgente ||
              p.estado == EstadoPlazo.vencido)
          .toList();
      for (final p in urgentes) {
        alertas.add(AlertaLegal(
          tipo:    p.estado == EstadoPlazo.vencido
              ? TipoAlerta.peligro
              : TipoAlerta.advertencia,
          mensaje: p.estado == EstadoPlazo.vencido
              ? '🚨 PLAZO VENCIDO: ${p.nombre} — ${p.norma}'
              : '⚠️ PLAZO URGENTE: ${p.nombre} vence en '
                '${p.diasRestantes} días — ${p.norma}',
          norma:   p.norma,
        ));
      }
    }

    return ResultadoAnalisis(
      camposFaltantes:      faltantes,
      alertas:              alertas,
      oportunidades:        oportunidades,
      posiblePrescripcion:  prescripto,
      fechaPrescripcion:    fechaPresc,
      plazos:               plazos,
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

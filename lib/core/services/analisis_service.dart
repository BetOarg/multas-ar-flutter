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
    if (acta.numeroActa == null || acta.numeroActa!.trim().isEmpty) {
      faltantes.add(const CampoFaltante(
        campo:      'Número de acta',
        norma:      'Art. 3 Ley 13.927 / Art. 9 Ley 1217',
        esCritico:  true,
      ));
      oportunidades.add('Falta número de acta — posible nulidad formal');
    }
    if (acta.patente == null || acta.patente!.trim().isEmpty) {
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
    if (acta.normaInfringida == null || acta.normaInfringida!.trim().isEmpty) {
      faltantes.add(const CampoFaltante(
        campo:     'Norma infringida',
        norma:     'Art. 3 inc. e) Ley 13.927 — Art. 18 CN',
        esCritico: true,
      ));
      oportunidades.add('Falta norma infringida — verificar el acta original y la norma aplicable');
    }
    if (acta.agente == null || acta.agente!.trim().isEmpty) {
      faltantes.add(const CampoFaltante(
        campo:     'Identificación del agente',
        norma:     'Art. 3 inc. f) Ley 13.927',
        esCritico: true,
      ));
      oportunidades.add('Falta identificación del agente — verificar el acta original y el régimen aplicable');
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
    if (acta.estadoProcesal != null && acta.estadoProcesal!.trim().isNotEmpty) {
      alertas.add(AlertaLegal(
        tipo: TipoAlerta.info,
        mensaje: 'Estado procesal informado: ${acta.estadoProcesal}. Confirmar con la resolución o expediente correspondiente.',
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
    final jurisdiccionReconocida =
        Jurisdiccion.todas.contains(acta.jurisdiccion) &&
        acta.jurisdiccion != Jurisdiccion.otra;
    final tipoFaltaReconocido = TipoFalta.todos.contains(acta.tipoFalta);
    if (acta.fechaInfraccion != null &&
        jurisdiccionReconocida &&
        tipoFaltaReconocido) {
      fechaPresc = plazosService.calcularPrescripcion(
          acta.fechaInfraccion!, acta.jurisdiccion, acta.tipoFalta!);
      if (fechaPresc != null) {
        prescripto = DateTime.now().isAfter(fechaPresc);

        if (prescripto) {
          alertas.add(AlertaLegal(
            tipo: TipoAlerta.advertencia,
            mensaje: 'Posible prescripción teórica desde ${_fmt(fechaPresc)} '
                'según el plazo base del art. 89 Ley 24.449. '
                'No confirma prescripción: revisar actos interruptivos, '
                'estado procesal, normativa local y expediente con un letrado.',
            norma: NormasBase.art89Prescrip,
          ));
          oportunidades.add(
              'Solicitar revisión de prescripción y posibles actos interruptivos');
        }
      } else {
        alertas.add(AlertaLegal(
          tipo: TipoAlerta.info,
          mensaje: 'No se calcula automáticamente la prescripción para '
              '${acta.jurisdiccion}: requiere verificar la normativa local '
              'vigente y los criterios aplicables al expediente.',
        ));
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
          mensaje: 'La prescripción en CABA requiere revisión del régimen '
                   'local vigente, los criterios jurisprudenciales aplicables, '
                   'las interrupciones y el expediente. No se aplica de forma '
                   'automática un plazo de 2 o 5 años.',
          norma:  'Verificar Ley 451 CABA, Ley 24.449 y jurisprudencia vigente',
        ));
      }
    }

    if (acta.jurisdiccion == Jurisdiccion.pba && acta.esFotomulta) {
      alertas.add(const AlertaLegal(
        tipo: TipoAlerta.advertencia,
        mensaje: 'En PBA, la Ley 13.927 prevé despachar la notificación '
                 'de la fotomulta dentro de 60 días hábiles desde el hecho. '
                 'Verificar fecha de comisión, constancia de despacho y '
                 'notificación efectiva. Un eventual incumplimiento no '
                 'determina por sí solo la nulidad automática.',
        norma:  'Ley 13.927 PBA, art. 35 inc. g)',
      ));
    }

    // ── Plan de pagos PBA ────────────────────────────────────────
    if (acta.jurisdiccion == Jurisdiccion.pba &&
        acta.tieneNovedad == 'plan_pagos') {
      alertas.add(const AlertaLegal(
        tipo: TipoAlerta.peligro,
        mensaje: 'La adhesión a un plan de pagos puede tener efectos sobre '
                 'el reconocimiento de la deuda o las vías de impugnación según '
                 'el régimen y sus condiciones. Revisar el instrumento concreto '
                 'antes de adherir; no se presume una renuncia universal.',
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

      if (plazos.isEmpty) {
        alertas.add(const AlertaLegal(
          tipo: TipoAlerta.info,
          mensaje: 'No se calculó un vencimiento automático: el plazo depende '
              'de la jurisdicción, el procedimiento y la notificación efectiva. '
              'Verificar la citación y la norma vigente; la ausencia de cálculo '
              'no significa que no exista un plazo.',
        ));
      }

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

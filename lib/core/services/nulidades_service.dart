import '../constants/legal_constants.dart';

// ══════════════════════════════════════════════════════════════════
// NULIDADES SERVICE
// Motor de detección de causales de nulidad formal de actas.
//
// Fuentes normativas:
//   PBA  → Art. 3 Ley 13.927 (nulidades absolutas del acta)
//   CABA → Art. 9 Ley 1217 (t.c. Ley 6.764/2024)
//   NAC  → Art. 70 Ley 24.449 (requisitos del acta)
//
// ADVERTENCIA: La nulidad debe ser declarada por el órgano
// competente. Este motor identifica CAUSALES POTENCIALES para
// que el letrado evalúe su procedencia en cada caso concreto.
// ══════════════════════════════════════════════════════════════════

// ── Tipos de nulidad ─────────────────────────────────────────────
enum TipoNulidad { absoluta, relativa, subsanable }

// ── Causal de nulidad detectada ───────────────────────────────────
class CausalNulidad {
  final String id;
  final String titulo;
  final String descripcion;
  final String norma;
  final TipoNulidad tipo;
  final String? argumentoJuridico;
  final String? jurisprudencia;
  final bool requiereAcreditarPerjuicio;

  const CausalNulidad({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.norma,
    required this.tipo,
    this.argumentoJuridico,
    this.jurisprudencia,
    this.requiereAcreditarPerjuicio = false,
  });
}

// ── Resultado del análisis de nulidades ───────────────────────────
class ResultadoNulidades {
  final List<CausalNulidad> causalesDetectadas;
  final List<CausalNulidad> causalesPotenciales; // requieren verificación manual
  final String recomendacion;
  final bool tieneNulidadAbsoluta;

  const ResultadoNulidades({
    required this.causalesDetectadas,
    required this.causalesPotenciales,
    required this.recomendacion,
    required this.tieneNulidadAbsoluta,
  });

  bool get tieneNulidades => causalesDetectadas.isNotEmpty;
}

// ── Datos de entrada para el análisis ────────────────────────────
class DatosActaParaAnalisis {
  final String jurisdiccion;
  final String? numeroActa;
  final DateTime? fechaInfraccion;
  final DateTime? fechaNotificacion;
  final String? patente;
  final String? normaInfringida;
  final String? agente;
  final String? legajoAgente;
  final bool tieneFiremaAgente;
  final bool tieneFirmaInfractor;
  final String? lugarInfraccion;
  final String? descripcionHecho;
  final bool esFotomulta;
  final bool? camaraHomologada;    // fotomultas: cámara con resolución aprobada
  final bool? notificacionValida;  // fotomultas: notificación en término
  final String? textoCompleto;     // texto OCR para análisis adicional

  const DatosActaParaAnalisis({
    required this.jurisdiccion,
    this.numeroActa,
    this.fechaInfraccion,
    this.fechaNotificacion,
    this.patente,
    this.normaInfringida,
    this.agente,
    this.legajoAgente,
    this.tieneFiremaAgente = true,
    this.tieneFirmaInfractor = true,
    this.lugarInfraccion,
    this.descripcionHecho,
    this.esFotomulta = false,
    this.camaraHomologada,
    this.notificacionValida,
    this.textoCompleto,
  });
}

// ══════════════════════════════════════════════════════════════════
// SERVICIO PRINCIPAL
// ══════════════════════════════════════════════════════════════════
class NulidadesService {

  ResultadoNulidades analizar(DatosActaParaAnalisis datos) {
    final detectadas  = <CausalNulidad>[];
    final potenciales = <CausalNulidad>[];

    switch (datos.jurisdiccion) {
      case Jurisdiccion.pba:
        _analizarPBA(datos, detectadas, potenciales);
      case Jurisdiccion.caba:
        _analizarCABA(datos, detectadas, potenciales);
      default:
        _analizarNacional(datos, detectadas, potenciales);
    }

    // Causales comunes a todas las jurisdicciones
    _analizarComunas(datos, detectadas, potenciales);

    final tieneAbsoluta = detectadas.any(
        (c) => c.tipo == TipoNulidad.absoluta);

    return ResultadoNulidades(
      causalesDetectadas:  detectadas,
      causalesPotenciales: potenciales,
      tieneNulidadAbsoluta: tieneAbsoluta,
      recomendacion: _buildRecomendacion(
          detectadas, potenciales, tieneAbsoluta),
    );
  }

  // ── PBA — Art. 3 Ley 13.927 ─────────────────────────────────
  void _analizarPBA(
    DatosActaParaAnalisis d,
    List<CausalNulidad> det,
    List<CausalNulidad> pot,
  ) {
    // 3.a — Número de acta
    if (d.numeroActa == null || d.numeroActa!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'pba_3a_num_acta',
        titulo: 'Falta número de acta',
        descripcion: 'El acta no contiene número identificatorio.',
        norma: 'Art. 3 inc. a) Ley 13.927 PBA',
        tipo: TipoNulidad.absoluta,
        argumentoJuridico:
            'La Ley 13.927 exige que cada acta tenga número único. '
            'Su ausencia impide identificar el instrumento y vulnera '
            'el derecho de defensa (Art. 18 CN).',
      ));
    }

    // 3.b — Fecha y hora
    if (d.fechaInfraccion == null) {
      det.add(const CausalNulidad(
        id: 'pba_3b_fecha',
        titulo: 'Falta fecha de la infracción',
        descripcion: 'El acta no consigna fecha de comisión del hecho.',
        norma: 'Art. 3 inc. b) Ley 13.927 PBA',
        tipo: TipoNulidad.absoluta,
        argumentoJuridico:
            'Sin fecha no es posible computar prescripción ni verificar '
            'la vigencia de la habilitación del agente. Nulidad insanable.',
      ));
    }

    // 3.c — Lugar de la infracción
    if (d.lugarInfraccion == null || d.lugarInfraccion!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'pba_3c_lugar',
        titulo: 'Falta lugar de la infracción',
        descripcion: 'El acta no identifica el lugar donde ocurrió el hecho.',
        norma: 'Art. 3 inc. c) Ley 13.927 PBA',
        tipo: TipoNulidad.absoluta,
        argumentoJuridico:
            'La determinación del lugar es requisito para establecer '
            'competencia territorial y verificar el hecho imputado.',
      ));
    }

    // 3.d — Identificación del vehículo (patente)
    if (d.patente == null || d.patente!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'pba_3d_patente',
        titulo: 'Falta identificación del vehículo',
        descripcion: 'El acta no consigna patente o dominio del vehículo.',
        norma: 'Art. 3 inc. d) Ley 13.927 PBA',
        tipo: TipoNulidad.absoluta,
        argumentoJuridico:
            'Sin identificación del vehículo no puede establecerse '
            'la autoría ni la responsabilidad del titular registral.',
      ));
    }

    // 3.e — Norma infringida
    if (d.normaInfringida == null || d.normaInfringida!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'pba_3e_norma',
        titulo: 'Falta norma infringida',
        descripcion: 'El acta no cita el artículo de la norma infringida.',
        norma: 'Art. 3 inc. e) Ley 13.927 PBA',
        tipo: TipoNulidad.absoluta,
        argumentoJuridico:
            'El principio de tipicidad exige la cita exacta del artículo '
            'violado. Sin ella no puede ejercerse defensa (Art. 18 CN).',
      ));
    }

    // 3.f — Identificación del agente
    if (!d.tieneFiremaAgente || d.legajoAgente == null || d.legajoAgente!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'pba_3f_agente',
        titulo: 'Falta firma o identificación del agente',
        descripcion: 'El acta carece de firma del agente labrador o su número de legajo.',
        norma: 'Art. 3 inc. f) Ley 13.927 PBA',
        tipo: TipoNulidad.absoluta,
        argumentoJuridico:
            'La firma del agente es requisito de autenticidad del '
            'instrumento público. Su ausencia produce nulidad absoluta '
            'e insanable por expresa disposición legal.',
      ));
    }

    // Fotomultas PBA — Art. 28 Ley 13.927
    if (d.esFotomulta) {
      _analizarFotomultaPBA(d, det, pot);
    }

    // Descripción vaga del hecho (relativa)
    if (d.descripcionHecho != null &&
        d.descripcionHecho!.trim().length < 20) {
      pot.add(const CausalNulidad(
        id: 'pba_desc_vaga',
        titulo: 'Descripción del hecho insuficiente',
        descripcion: 'La descripción del hecho imputado es demasiado escueta '
            'para identificar con precisión la conducta infractora.',
        norma: 'Art. 3 Ley 13.927 PBA — Art. 18 CN',
        tipo: TipoNulidad.relativa,
        requiereAcreditarPerjuicio: true,
        argumentoJuridico:
            'Si bien no existe causal expresa, una descripción que no '
            'permita identificar la conducta vulnera el derecho de '
            'defensa. Oponer como nulidad relativa acreditando perjuicio.',
      ));
    }
  }

  // ── Fotomultas PBA — Art. 28 Ley 13.927 ─────────────────────
  void _analizarFotomultaPBA(
    DatosActaParaAnalisis d,
    List<CausalNulidad> det,
    List<CausalNulidad> pot,
  ) {
    // Notificación fuera de término (60 días hábiles)
    if (d.fechaInfraccion != null && d.fechaNotificacion != null) {
      final diasTranscurridos =
          d.fechaNotificacion!.difference(d.fechaInfraccion!).inDays;
      // ~60 días hábiles ≈ 84 días corridos (conservador)
      if (diasTranscurridos > 84) {
        pot.add(CausalNulidad(
          id: 'pba_fotomulta_notif_tardia',
          titulo: 'Notificación de fotomulta fuera de término',
          descripcion: 'Transcurrieron aprox. $diasTranscurridos días '
              'entre el hecho y la notificación. El Art. 28 Ley 13.927 '
              'establece 60 días hábiles para notificar.',
          norma: 'Art. 28 Ley 13.927 PBA',
          tipo: TipoNulidad.relativa,
          requiereAcreditarPerjuicio: true,
          jurisprudencia:
              'ATENCIÓN: Cámara Apelación Gral. San Martín Sala I, '
              '2018, Exp. 37.639: el plazo es ORDENATORIO. '
              'Verificar estado en alzada antes de invocar caducidad automática.',
        ));
      }
    }

    // Cámara no homologada: observación potencial, su efecto jurídico requiere verificación.
    if (d.camaraHomologada == false) {
      pot.add(const CausalNulidad(
        id: 'pba_fotomulta_camara',
        titulo: 'Cámara fotográfica sin homologación vigente',
        descripcion: 'El equipo de fotomulta no cuenta con resolución de '
            'homologación vigente o la misma no surge del acta.',
        norma: 'Art. 27-28 Ley 13.927 PBA — Res. ANSV',
        tipo: TipoNulidad.relativa,
        argumentoJuridico:
            'La Ley 13.927 exige que los equipos de control automático '
            'estén homologados y calibrados. Sin homologación vigente '
            'la prueba carece de valor probatorio.',
      ));
    }
  }

  // ── CABA — Art. 9 Ley 1217 ───────────────────────────────────
  void _analizarCABA(
    DatosActaParaAnalisis d,
    List<CausalNulidad> det,
    List<CausalNulidad> pot,
  ) {
    if (d.numeroActa == null || d.numeroActa!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'caba_9_num',
        titulo: 'Falta número de acta',
        descripcion: 'El comprobante de falta no contiene número identificatorio.',
        norma: 'Art. 9 Ley 1217 CABA',
        tipo: TipoNulidad.absoluta,
      ));
    }

    if (d.fechaInfraccion == null) {
      det.add(const CausalNulidad(
        id: 'caba_9_fecha',
        titulo: 'Falta fecha de la infracción',
        descripcion: 'El acta no consigna fecha y hora del hecho.',
        norma: 'Art. 9 Ley 1217 CABA',
        tipo: TipoNulidad.absoluta,
      ));
    }

    if (d.normaInfringida == null || d.normaInfringida!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'caba_9_norma',
        titulo: 'Falta norma infringida',
        descripcion: 'El acta no cita el artículo de la Ley 451 infringido.',
        norma: 'Art. 9 Ley 1217 CABA — Art. 18 CN',
        tipo: TipoNulidad.absoluta,
        argumentoJuridico:
            'El código de faltas CABA (Ley 451) exige tipificación '
            'expresa. Sin cita de norma no hay tipo infraccional.',
      ));
    }

    if (!d.tieneFiremaAgente) {
      det.add(const CausalNulidad(
        id: 'caba_9_firma',
        titulo: 'Falta firma del inspector',
        descripcion: 'El acta de comprobación carece de firma del inspector actuante.',
        norma: 'Art. 9 Ley 1217 CABA',
        tipo: TipoNulidad.absoluta,
      ));
    }

    // Prescripción CABA — alerta dual
    if (d.fechaInfraccion != null) {
      final aniosTranscurridos =
          DateTime.now().difference(d.fechaInfraccion!).inDays / 365.25;
      if (aniosTranscurridos >= 2) {
        pot.add(CausalNulidad(
          id: 'caba_prescripcion_andrade',
          titulo: 'Posible prescripción — Fallo Andrade (2 años)',
          descripcion: 'Transcurrieron ${aniosTranscurridos.toStringAsFixed(1)} años '
              'desde la infracción. El Fallo Andrade (PCyF N°15, 30/05/2023) '
              'aplica prescripción bienal del Art. 89 Ley 24.449.',
          norma: 'Fallo Andrade — Juzgado PCyF N°15 CABA (30/05/2023) — Art. 89 Ley 24.449',
          tipo: TipoNulidad.relativa,
          jurisprudencia:
              'VERIFICAR estado en alzada antes de invocar. '
              'Ley 451 establece 5 años (texto vigente). '
              'Andrade aplica Ley 24.449 subsidiariamente. '
              'Consultar con letrado el estado actual de la cuestión.',
        ));
      }
    }
  }

  // ── Nacional — Art. 70 Ley 24.449 ───────────────────────────
  void _analizarNacional(
    DatosActaParaAnalisis d,
    List<CausalNulidad> det,
    List<CausalNulidad> pot,
  ) {
    if (d.numeroActa == null || d.numeroActa!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'nac_70_num',
        titulo: 'Falta número de acta',
        descripcion: 'Requisito del Art. 70 Ley 24.449.',
        norma: 'Art. 70 Ley 24.449',
        tipo: TipoNulidad.absoluta,
      ));
    }
    if (d.normaInfringida == null || d.normaInfringida!.trim().isEmpty) {
      det.add(const CausalNulidad(
        id: 'nac_70_norma',
        titulo: 'Falta cita de norma infringida',
        descripcion: 'Requisito del Art. 70 Ley 24.449.',
        norma: 'Art. 70 Ley 24.449',
        tipo: TipoNulidad.absoluta,
      ));
    }
  }

  // ── Causales comunes a todas las jurisdicciones ──────────────
  void _analizarComunas(
    DatosActaParaAnalisis d,
    List<CausalNulidad> det,
    List<CausalNulidad> pot,
  ) {
    // Patente que no coincide con titular (potencial — requiere verificación DNRPA)
    if (d.patente != null && d.textoCompleto != null) {
      final texto = d.textoCompleto!.toUpperCase();
      // Si el texto menciona una patente diferente a la detectada
      if (!texto.contains(d.patente!.toUpperCase())) {
        pot.add(CausalNulidad(
          id: 'com_patente_discordante',
          titulo: 'Posible discordancia de patente',
          descripcion: 'La patente detectada por OCR (${d.patente}) '
              'podría no coincidir con el texto original del acta. '
              'Verificar con el documento físico.',
          norma: 'Art. 18 CN — Derecho de defensa',
          tipo: TipoNulidad.relativa,
          requiereAcreditarPerjuicio: true,
        ));
      }
    }

    // Norma citada incorrectamente (potencial)
    if (d.normaInfringida != null) {
      final normaUpper = d.normaInfringida!.toUpperCase();
      // Verificar coherencia básica: PBA no debería citar Ley 451
      if (d.jurisdiccion == Jurisdiccion.pba &&
          normaUpper.contains('LEY 451')) {
        pot.add(const CausalNulidad(
          id: 'com_norma_incorrecta_jur',
          titulo: 'Norma citada no corresponde a la jurisdicción',
          descripcion: 'El acta labrada en PBA cita la Ley 451 CABA, '
              'que es de aplicación exclusiva en CABA.',
          norma: 'Art. 3 Ley 13.927 PBA',
          tipo: TipoNulidad.relativa,
          argumentoJuridico:
              'La cita de una norma inaplicable en la jurisdicción '
              'configura error en la tipificación que puede fundar nulidad.',
        ));
      }
    }
  }

  // ── Recomendación final ──────────────────────────────────────
  String _buildRecomendacion(
    List<CausalNulidad> det,
    List<CausalNulidad> pot,
    bool tieneAbsoluta,
  ) {
    if (det.isEmpty && pot.isEmpty) {
      return 'No se detectaron causales de nulidad evidentes en los datos '
          'disponibles. Esto no excluye defectos no visibles en el acta '
          'física. Se recomienda revisión profesional completa del expediente.';
    }
    if (tieneAbsoluta) {
      return 'Se detectaron ${det.length} causal(es) de NULIDAD ABSOLUTA. '
          'Interponer la nulidad en el primer acto procesal oportuno '
          '(descargo/presentación ante el juzgado). '
          'La nulidad absoluta puede declararse de oficio. '
          'CONSULTAR con abogado matriculado antes de actuar.';
    }
    if (det.isNotEmpty) {
      return 'Se detectaron ${det.length} causal(es) de nulidad relativa. '
          'Debe oponerse en la primera oportunidad procesal '
          'y acreditar el perjuicio concreto causado. '
          'CONSULTAR con abogado matriculado.';
    }
    return 'Se identificaron ${pot.length} causal(es) POTENCIAL(ES) '
        'que requieren verificación con el documento físico original. '
        'CONSULTAR con abogado matriculado antes de invocarlas.';
  }
}

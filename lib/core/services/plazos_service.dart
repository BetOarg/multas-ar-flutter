// ══════════════════════════════════════════════════════════════════
// PLAZOS SERVICE — implementación completa
// Motor de cálculo de plazos legales para tránsito Argentina.
//
// Tipos de plazo:
//   - Días hábiles administrativos (L-V, sin feriados)
//   - Días hábiles judiciales (ídem, con receso julio/enero)
//   - Días corridos (calendario, sin excepción)
//
// Prescripción: por jurisdicción y tipo de falta.
// EstadoPlazo: semáforo vencido/urgente/próximo/vigente.
// ══════════════════════════════════════════════════════════════════

enum EstadoPlazo { vencido, urgente, proximo, vigente }

class PlazoCalculado {
  final String nombre;
  final String norma;
  final String tipoPlazo;
  final DateTime fechaInicio;
  final DateTime fechaVencimiento;
  final int diasRestantesVal;
  final EstadoPlazo estado;

  const PlazoCalculado({
    required this.nombre,
    required this.norma,
    required this.tipoPlazo,
    required this.fechaInicio,
    required this.fechaVencimiento,
    required this.diasRestantesVal,
    required this.estado,
  });

  int get diasRestantes => diasRestantesVal;
}

class PlazosService {
  final List<DateTime> feriados;

  PlazosService({required this.feriados});

  DateTime sumarDiasHabilesAdmin(DateTime inicio, int dias) {
    var fecha = inicio;
    var contados = 0;
    while (contados < dias) {
      fecha = fecha.add(const Duration(days: 1));
      if (_esHabilAdmin(fecha)) contados++;
    }
    return fecha;
  }

  DateTime sumarDiasHabilesJud(DateTime inicio, int dias) {
    var fecha = inicio;
    var contados = 0;
    while (contados < dias) {
      fecha = fecha.add(const Duration(days: 1));
      if (_esHabilJud(fecha)) contados++;
    }
    return fecha;
  }

  DateTime sumarDiasCorridos(DateTime inicio, int dias) =>
      inicio.add(Duration(days: dias));

  DateTime calcularPrescripcion(
      DateTime hecho, String jurisdiccion, String tipoFalta) {
    final anios = _aniosPrescrip(jurisdiccion, tipoFalta);
    return DateTime(hecho.year + anios, hecho.month, hecho.day);
  }

  int _aniosPrescrip(String jur, String tipo) {
    switch (jur) {
      case 'CABA':
        return 5; // Verificar texto vigente y jurisprudencia aplicable.
      case 'Mendoza':
        return switch (tipo) {
          'gravisima' => 4,
          'grave' => 3,
          _ => 2,
        };
      case 'Neuquén':
        return 3;
      default:
        return switch (tipo) {
          'grave' => 5,
          _ => 2,
        };
    }
  }

  /// Compara fechas de calendario: la hora actual no debe alterar el día
  /// restante de un vencimiento que se almacena como fecha.
  int diasRestantes(DateTime vencimiento) {
    final hoy = DateTime.now();
    final hoyCalendario = DateTime(hoy.year, hoy.month, hoy.day);
    final vencimientoCalendario = DateTime(
      vencimiento.year,
      vencimiento.month,
      vencimiento.day,
    );
    return vencimientoCalendario.difference(hoyCalendario).inDays;
  }

  EstadoPlazo evaluarEstado(DateTime vencimiento) {
    final diff = diasRestantes(vencimiento);
    if (diff < 0) return EstadoPlazo.vencido;
    if (diff <= 3) return EstadoPlazo.urgente;
    if (diff <= 7) return EstadoPlazo.proximo;
    return EstadoPlazo.vigente;
  }

  bool _esHabilAdmin(DateTime d) =>
      d.weekday != DateTime.saturday &&
      d.weekday != DateTime.sunday &&
      !_esFeriado(d);

  bool _esHabilJud(DateTime d) {
    if (!_esHabilAdmin(d)) return false;
    if (d.month == 1) return false;
    if (d.month == 7) return false;
    return true;
  }

  bool _esFeriado(DateTime d) => feriados.any(
        (f) => f.year == d.year && f.month == d.month && f.day == d.day);

  List<PlazoCalculado> calcularPlazos({
    required String jurisdiccion,
    required DateTime fechaNotificacion,
    bool esFotomulta = false,
  }) {
    final plazos = <PlazoCalculado>[];

    switch (jurisdiccion) {
      case 'CABA':
        plazos.addAll(_plazosCaba(fechaNotificacion));
        break;
      case 'PBA':
        plazos.addAll(_plazosPba(fechaNotificacion, esFotomulta));
        break;
      default:
        plazos.addAll(_plazosGeneral(fechaNotificacion));
        break;
    }

    return plazos;
  }

  List<PlazoCalculado> _plazosCaba(DateTime inicio) {
    final venc = sumarDiasHabilesAdmin(inicio, 5);
    return [
      PlazoCalculado(
        nombre: 'Descargo administrativo',
        tipoPlazo: 'habiles_adm',
        norma: 'Art. 8 Ley 1217 CABA — 5 días hábiles',
        fechaInicio: inicio,
        fechaVencimiento: venc,
        diasRestantesVal: diasRestantes(venc),
        estado: evaluarEstado(venc),
      ),
    ];
  }

  List<PlazoCalculado> _plazosPba(DateTime inicio, bool esFoto) {
    final descargo = sumarDiasHabilesAdmin(inicio, 45);
    final presentacion = sumarDiasCorridos(inicio, 30);
    final caducidadLic = sumarDiasCorridos(inicio, 90);
    final apelacion = sumarDiasHabilesJud(inicio, 5);

    final lista = [
      PlazoCalculado(
        nombre: 'Descargo administrativo',
        tipoPlazo: 'habiles_adm',
        norma: 'Art. 35 Ley 13.927 PBA — 45 días hábiles',
        fechaInicio: inicio,
        fechaVencimiento: descargo,
        diasRestantesVal: diasRestantes(descargo),
        estado: evaluarEstado(descargo),
      ),
      PlazoCalculado(
        nombre: 'Presentación ante JAITP',
        tipoPlazo: 'corridos',
        norma: 'Art. 35 Ley 13.927 PBA — 30 días corridos',
        fechaInicio: inicio,
        fechaVencimiento: presentacion,
        diasRestantesVal: diasRestantes(presentacion),
        estado: evaluarEstado(presentacion),
      ),
      PlazoCalculado(
        nombre: 'Caducidad habilitación para conducir',
        tipoPlazo: 'corridos',
        norma: 'Art. 35 Ley 13.927 PBA — 90 días corridos',
        fechaInicio: inicio,
        fechaVencimiento: caducidadLic,
        diasRestantesVal: diasRestantes(caducidadLic),
        estado: evaluarEstado(caducidadLic),
      ),
      PlazoCalculado(
        nombre: 'Recurso de apelación (fundado)',
        tipoPlazo: 'habiles_jud',
        norma: 'Arts. 40-41 Ley 13.927 PBA — 5 días hábiles judiciales',
        fechaInicio: inicio,
        fechaVencimiento: apelacion,
        diasRestantesVal: diasRestantes(apelacion),
        estado: evaluarEstado(apelacion),
      ),
    ];

    if (esFoto) {
      final notifFoto = sumarDiasHabilesAdmin(inicio, 60);
      lista.add(PlazoCalculado(
        nombre: 'Notificación fotomulta (término legal)',
        tipoPlazo: 'habiles_adm',
        norma: 'Art. 28 Ley 13.927 PBA — 60 días hábiles',
        fechaInicio: inicio,
        fechaVencimiento: notifFoto,
        diasRestantesVal: diasRestantes(notifFoto),
        estado: evaluarEstado(notifFoto),
      ));
    }

    return lista;
  }

  List<PlazoCalculado> _plazosGeneral(DateTime inicio) {
    final venc = sumarDiasCorridos(inicio, 30);
    return [
      PlazoCalculado(
        nombre: 'Plazo general de descargo',
        tipoPlazo: 'corridos',
        norma: 'Art. 70 Ley 24.449 — verificar normativa local',
        fechaInicio: inicio,
        fechaVencimiento: venc,
        diasRestantesVal: diasRestantes(venc),
        estado: evaluarEstado(venc),
      ),
    ];
  }
}

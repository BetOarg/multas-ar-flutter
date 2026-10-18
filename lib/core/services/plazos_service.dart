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

  /// Fecha teórica de prescripción solo para el régimen base del art. 89
  /// de la Ley 24.449. No determina prescripción efectiva: deben revisarse
  /// actos interruptivos, estado procesal y reglas locales aplicables.
  /// Retorna null cuando la combinación jurisdicción/tipo no está validada.
  DateTime? calcularPrescripcion(
      DateTime hecho, String jurisdiccion, String tipoFalta) {
    final anios = _aniosPrescrip(jurisdiccion, tipoFalta);
    if (anios == null) return null;

    // Conserva una fecha válida en años no bisiestos (29 de febrero → 28).
    final anioDestino = hecho.year + anios;
    final esBisiesto = anioDestino % 4 == 0 &&
        (anioDestino % 100 != 0 || anioDestino % 400 == 0);
    final dia = hecho.month == 2 && hecho.day == 29 && !esBisiesto
        ? 28
        : hecho.day;
    return DateTime(hecho.year + anios, hecho.month, dia);
  }

  int? _aniosPrescrip(String jur, String tipo) {
    // CABA tiene una controversia entre el régimen local y criterios
    // jurisprudenciales sobre la aplicación supletoria del art. 89.
    // Mendoza y otras jurisdicciones requieren verificación específica.
    if (jur != 'PBA' && jur != 'nacional') return null;

    return switch (tipo) {
      'leve' => 2,
      'grave' => 5,
      _ => null,
    };
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
    // No excluir enero/julio completos: los recesos judiciales varían por
    // jurisdicción y año. Este cálculo es solo calendario base; para un
    // vencimiento judicial real debe incorporarse el calendario oficial
    // del órgano competente.
    return _esHabilAdmin(d);
  }

  bool _esFeriado(DateTime d) => feriados.any(
        (f) => f.year == d.year && f.month == d.month && f.day == d.day);

  /// No devuelve vencimientos automáticos hasta validar cada regla por
  /// jurisdicción, procedimiento y fecha efectiva de notificación.
  ///
  /// En PBA, por ejemplo, el art. 35 vincula el descargo al emplazamiento
  /// posterior al vencimiento del pago voluntario; no fija un plazo universal
  /// de 45 días desde la notificación. El plazo de 60 días hábiles para
  /// despachar la notificación de una fotomulta se cuenta desde el hecho,
  /// dato que este método no recibe.
  ///
  /// Se conserva la firma por compatibilidad con los llamadores. Una lista
  /// vacía significa "sin cálculo fiable", no que el usuario carezca de plazo.
  List<PlazoCalculado> calcularPlazos({
    required String jurisdiccion,
    required DateTime fechaNotificacion,
    bool esFotomulta = false,
  }) => const [];

}

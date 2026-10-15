// ══════════════════════════════════════════════════════════════════
// LEGAL CONSTANTS
// Constantes del dominio jurídico. Usar siempre estas referencias
// en lugar de strings literales para evitar inconsistencias.
// ══════════════════════════════════════════════════════════════════

abstract class Jurisdiccion {
  static const caba = 'CABA';
  static const pba = 'PBA';
  static const cordoba = 'Córdoba';
  static const santaFe = 'Santa Fe';
  static const mendoza = 'Mendoza';
  static const tucuman = 'Tucumán';
  static const salta = 'Salta';
  static const neuquen = 'Neuquén';
  static const nacional = 'nacional';
  static const otra = 'otra';

  static const todas = [
    caba, pba, cordoba, santaFe, mendoza,
    tucuman, salta, neuquen, nacional, otra,
  ];

  static String label(String jur) => switch (jur) {
    caba    => 'Ciudad Autónoma de Buenos Aires',
    pba     => 'Provincia de Buenos Aires',
    cordoba => 'Córdoba',
    santaFe => 'Santa Fe',
    mendoza => 'Mendoza',
    tucuman => 'Tucumán',
    salta   => 'Salta',
    neuquen => 'Neuquén',
    nacional => 'Nacional / ANSV',
    _       => 'Otra jurisdicción',
  };
}

abstract class TipoFalta {
  static const leve      = 'leve';
  static const grave     = 'grave';
  static const gravisima = 'gravisima';

  static const todos = [leve, grave, gravisima];

  static String label(String tipo) => switch (tipo) {
    leve      => 'Leve',
    grave     => 'Grave',
    gravisima => 'Gravísima',
    _         => 'Sin determinar',
  };
}

abstract class EstadoProcesal {
  static const admin    = 'admin';
  static const descargo = 'descargo';
  static const condenado = 'condenado';
  static const apelacion = 'apelacion';
  static const firme    = 'firme';
  static const apremio  = 'apremio';
  static const prescripto = 'prescripto';

  static const todos = [
    admin, descargo, condenado,
    apelacion, firme, apremio, prescripto,
  ];

  static String label(String estado) => switch (estado) {
    admin      => 'Instancia administrativa',
    descargo   => 'Descargo presentado',
    condenado  => 'Resolución condenatoria',
    apelacion  => 'En apelación judicial',
    firme      => 'Resolución firme',
    apremio    => 'Juicio de apremio',
    prescripto => 'Prescripto',
    _          => 'Desconocido',
  };

  /// Estados que requieren acción urgente
  static bool esUrgente(String estado) =>
      estado == condenado || estado == apremio;
}

abstract class ErrorFormal {
  static const patenteErronea           = 'Patente errónea';
  static const fechaIncorrecta          = 'Fecha incorrecta';
  static const horaIncorrecta           = 'Hora incorrecta';
  static const lugarNoCoincide          = 'Lugar no coincide';
  static const normaMalCitada           = 'Norma mal citada';
  static const faltaFirmaAgente         = 'Falta firma del agente';
  static const datosTitularIncorrectos  = 'Datos del titular incorrectos';
  static const faltaIdAgente            = 'Falta identificación del agente';
  static const senalizacionDeficiente   = 'Señalización deficiente';
  static const fotomultaSinNotif        = 'Fotomulta sin notificación válida';

  static const todos = [
    patenteErronea, fechaIncorrecta, horaIncorrecta, lugarNoCoincide,
    normaMalCitada, faltaFirmaAgente, datosTitularIncorrectos,
    faltaIdAgente, senalizacionDeficiente, fotomultaSinNotif,
  ];
}

abstract class NormasBase {
  // Nacional
  static const ley24449     = 'Ley Nacional N° 24.449';
  static const art89Prescrip = 'Art. 89 Ley 24.449 — Prescripción';
  static const art88Extinc   = 'Art. 88 Ley 24.449 — Extinción de la acción';
  static const decreto77995  = 'Decreto 779/95 — Reglamentación Ley 24.449';

  // CABA
  static const ley1217       = 'Ley 1217 CABA (t.c. Ley 6.764/2024)';
  static const art8Descargo  = 'Art. 8 Ley 1217 — Plazo descargo: 5 días hábiles';
  static const ley451        = 'Ley 451 CABA — Código de Faltas';

  // PBA
  static const ley13927      = 'Ley 13.927 PBA';
  static const ley15002      = 'Ley 15.002 PBA (modificatoria)';
  static const art3Nulidad   = 'Art. 3 Ley 13.927 — Nulidad formal del acta';
  static const art35Descargo = 'Art. 35 Ley 13.927 — Descargo: 45 días hábiles';
  static const art35Caducidad = 'Art. 35 Ley 13.927 — Caducidad habilitación: 90 días';
  static const art35PlanPagos = 'Art. 35 Ley 13.927 — Plan de pagos = renuncia a recursos';
  static const art35Conductor = 'Art. 35 inc. f Ley 13.927 — Denuncia conductor real';
  static const art40Fundamento = 'Art. 40 Ley 13.927 — Recurso debe fundarse en mismo escrito';
  static const art41Apelacion  = 'Art. 41 Ley 13.927 — Apelación: 5 días hábiles';
  static const art6Ruit        = 'Art. 6 Ley 13.927 — Caducidad RUIT: 10 años';

  // Mendoza
  static const ley9024        = 'Ley 9024 Mendoza';
  static const art94Prescrip  = 'Art. 94 Ley 9024 — Prescripción tripartita';

  // Constitucional
  static const art18CN        = 'Art. 18 CN — Derecho de defensa';
  static const art43CN        = 'Art. 43 CN — Acción de amparo';
  static const ley16986       = 'Ley 16.986 — Reglamentación amparo';
}

abstract class PlazosClave {
  static const int descargoCabaDiasHabiles  = 5;
  static const int descargoPbaDiasHabiles   = 45;
  static const int presentacionPbaCorridos  = 30;
  static const int caducidadLicPbaCorridos  = 90;
  static const int apelacionPbaDiasHabiles  = 5;
  static const int notifFotomultaPbaHabiles = 60;
  static const int caducidadRuitAnios       = 10;
  static const int prescripcionCabaAnios    = 5;
  static const int prescripcionFalloAndradeAnios = 2; // ⚠️ verificar alzada
  static const int prescripcionLeveAnios    = 2;
  static const int prescripcionGraveAnios   = 5;
  static const int prescripcionMendozaLeveAnios     = 2;
  static const int prescripcionMendozaGraveAnios    = 3;
  static const int prescripcionMendozaGravisimaAnios = 4;
  static const int prescripcionNeuquenAnios = 3;
}

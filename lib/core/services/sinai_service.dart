import 'dart:convert';
import 'package:http/http.dart' as http;

// ══════════════════════════════════════════════════════════════════
// SINAI / DVE SERVICE
// Consulta de infracciones online por patente.
//
// SINAI (Sistema de Notificación de Infracciones) — ANSV
//   URL pública: https://www.argentina.gob.ar/transporte/ansv/sinai
//
// DVE (Dirección de Verificación de Emisiones) — para consulta
//   técnica de vehículos.
//
// ESTADO ACTUAL:
//   - El SINAI no expone API REST pública documentada.
//   - La consulta se realiza mediante scraping del formulario HTML.
//   - PBA usa su propio portal: multastransito.gba.gob.ar
//   - CABA: tramitación online GCBA (buscaminfracciones.buenosaires.gob.ar)
//
// ADVERTENCIA: Los portales gubernamentales cambian su estructura
// con frecuencia. Verificar URLs y selectores antes de cada release.
// ══════════════════════════════════════════════════════════════════

/// Infracción encontrada en consulta online
class InfraccionOnline {
  final String fuente;        // 'SINAI' | 'PBA' | 'CABA'
  final String? numeroActa;
  final String? fecha;
  final String? descripcion;
  final String? importe;
  final String? estado;       // 'pendiente' | 'pagada' | 'vencida'
  final String urlConsulta;

  const InfraccionOnline({
    required this.fuente,
    this.numeroActa,
    this.fecha,
    this.descripcion,
    this.importe,
    this.estado,
    required this.urlConsulta,
  });
}

/// Resultado de la consulta online
class ResultadoConsultaOnline {
  final bool exito;
  final List<InfraccionOnline> infracciones;
  final String? errorMensaje;
  final String fuente;
  final String urlConsultada;

  const ResultadoConsultaOnline({
    required this.exito,
    this.infracciones = const [],
    this.errorMensaje,
    required this.fuente,
    required this.urlConsultada,
  });

  bool get tieneInfracciones => infracciones.isNotEmpty;
}

// ── URLs de consulta por jurisdicción ────────────────────────────
abstract class UrlsConsulta {
  static const pba =
      'https://multastransito.gba.gob.ar/consulta';
  static const caba =
      'https://buscaminfracciones.buenosaires.gob.ar';
  static const sinai =
      'https://www.argentina.gob.ar/transporte/ansv/sinai';
  static const dnrpa =
      'https://www.dnrpa.gov.ar/portal_dnrpa/index.html';
}

// ══════════════════════════════════════════════════════════════════
// SERVICIO PRINCIPAL
// ══════════════════════════════════════════════════════════════════
class SinaiService {
  final http.Client _client;

  SinaiService({http.Client? client})
      : _client = client ?? http.Client();

  // ── Consulta PBA ─────────────────────────────────────────────
  /// Abre la URL del portal PBA para consulta manual.
  /// No realiza scraping automático (portal requiere CAPTCHA).
  Future<ResultadoConsultaOnline> consultarPBA(String patente) async {
    // El portal PBA usa CAPTCHA — no es automatizable.
    // Retornamos la URL para que el usuario la abra manualmente.
    return ResultadoConsultaOnline(
      exito: true,
      fuente: 'PBA',
      urlConsultada: UrlsConsulta.pba,
      errorMensaje: 'El portal PBA requiere validación manual. '
          'Se abrirá el navegador con la URL de consulta.',
    );
  }

  // ── Consulta CABA ─────────────────────────────────────────────
  Future<ResultadoConsultaOnline> consultarCABA(String patente) async {
    return ResultadoConsultaOnline(
      exito: true,
      fuente: 'CABA',
      urlConsultada: '${UrlsConsulta.caba}?dominio=${patente.toUpperCase()}',
      errorMensaje: 'El portal CABA requiere validación manual.',
    );
  }

  // ── Consulta SINAI (nacional) ─────────────────────────────────
  Future<ResultadoConsultaOnline> consultarSINAI(String patente) async {
    return ResultadoConsultaOnline(
      exito: true,
      fuente: 'SINAI',
      urlConsultada: UrlsConsulta.sinai,
      errorMensaje: 'SINAI requiere validación manual con CUIT/DNI.',
    );
  }

  // ── Consulta múltiple ─────────────────────────────────────────
  /// Retorna URLs de consulta para todas las fuentes disponibles
  /// según la jurisdicción detectada.
  List<ResultadoConsultaOnline> urlsConsulta(
      String patente, String? jurisdiccion) {
    final resultados = <ResultadoConsultaOnline>[];

    if (jurisdiccion == 'PBA' || jurisdiccion == null) {
      resultados.add(ResultadoConsultaOnline(
        exito: true,
        fuente: 'PBA',
        urlConsultada: UrlsConsulta.pba,
      ));
    }
    if (jurisdiccion == 'CABA' || jurisdiccion == null) {
      resultados.add(ResultadoConsultaOnline(
        exito: true,
        fuente: 'CABA',
        urlConsultada:
            '${UrlsConsulta.caba}?dominio=${patente.toUpperCase()}',
      ));
    }
    // SINAI siempre disponible como respaldo
    resultados.add(ResultadoConsultaOnline(
      exito: true,
      fuente: 'SINAI / ANSV',
      urlConsultada: UrlsConsulta.sinai,
    ));
    // DNRPA para verificar titular registral
    resultados.add(ResultadoConsultaOnline(
      exito: true,
      fuente: 'DNRPA',
      urlConsultada: UrlsConsulta.dnrpa,
    ));

    return resultados;
  }

  void dispose() => _client.close();
}

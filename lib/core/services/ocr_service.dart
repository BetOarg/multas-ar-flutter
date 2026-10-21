import 'dart:io';
import 'package:flutter/services.dart';

// ══════════════════════════════════════════════════════════════════
// OCR SERVICE — v2
// OCR exclusivamente local: PaddleOCR/ONNX en Android y Apple Vision en iOS.
// No usa SDKs con telemetría ni envía imágenes/texto a servicios externos.
// ══════════════════════════════════════════════════════════════════

const _kOcrChannel = MethodChannel('com.betOarg.multas_ar/ocr');

// ── Resultado de reconocimiento ───────────────────────────────────
class OcrResult {
  final String textoCompleto;
  final String? patente;
  final DateTime? fechaInfraccion;
  final String? numeroActa;
  final String? normaInfringida;
  final String? agente;
  final String? lugarInfraccion;
  final String? jurisdiccionDetectada;
  final bool esFotomulta;
  final List<String> camposFaltantes;
  final String motor;

  const OcrResult({
    required this.textoCompleto,
    this.patente,
    this.fechaInfraccion,
    this.numeroActa,
    this.normaInfringida,
    this.agente,
    this.lugarInfraccion,
    this.jurisdiccionDetectada,
    this.esFotomulta = false,
    this.camposFaltantes = const [],
    required this.motor,
  });
}

// ── Interfaz base ─────────────────────────────────────────────────
abstract class IOcrService {
  Future<OcrResult> reconocer(String imagePath);
  Future<bool> isDisponible();
}

// ── Factory ───────────────────────────────────────────────────────
class OcrServiceFactory {
  static IOcrService crear() {
    if (Platform.isAndroid) return PaddleOcrService();
    if (Platform.isIOS)     return AppleVisionOcrService();
    return UnsupportedOcrService();
  }
}

// ══════════════════════════════════════════════════════════════════
// PADDLE OCR SERVICE — Android
// ══════════════════════════════════════════════════════════════════
class PaddleOcrService implements IOcrService {
  @override
  Future<bool> isDisponible() async {
    try {
      final r = await _kOcrChannel.invokeMethod<bool>('isAvailable');
      return r ?? false;
    } catch (_) { return false; }
  }

  @override
  Future<OcrResult> reconocer(String imagePath) async {
    try {
      final texto = await _kOcrChannel.invokeMethod<String>(
            'recognizeImage', {'imagePath': imagePath}) ?? '';
      return ActaParser.parsear(texto, motor: 'paddle');
    } on PlatformException catch (e) {
      throw OcrLocalException(
        'PaddleOCR local no pudo procesar la imagen (${e.code}). '
        'Los datos no se enviaron a ningún servicio externo.',
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// APPLE VISION SERVICE — iOS
// ══════════════════════════════════════════════════════════════════
class AppleVisionOcrService implements IOcrService {
  @override
  Future<bool> isDisponible() async {
    try {
      final r = await _kOcrChannel.invokeMethod<bool>('isAvailable');
      return r ?? false;
    } catch (_) { return false; }
  }

  @override
  Future<OcrResult> reconocer(String imagePath) async {
    try {
      final texto = await _kOcrChannel.invokeMethod<String>(
            'recognizeImage', {'imagePath': imagePath}) ?? '';
      return ActaParser.parsear(texto, motor: 'vision');
    } on PlatformException catch (e) {
      throw OcrLocalException(
        'Apple Vision local no pudo procesar la imagen (${e.code}). '
        'Los datos no se enviaron a ningún servicio externo.',
      );
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// FALLBACK EXPLÍCITO — sin OCR de terceros
// ══════════════════════════════════════════════════════════════════

class OcrLocalException implements Exception {
  final String message;
  const OcrLocalException(this.message);

  @override
  String toString() => message;
}

class UnsupportedOcrService implements IOcrService {
  @override
  Future<bool> isDisponible() async => false;

  @override
  Future<OcrResult> reconocer(String imagePath) async {
    throw const OcrLocalException(
      'El OCR local no está disponible en esta plataforma.',
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ACTA PARSER — extrae campos estructurados del texto OCR crudo
// ══════════════════════════════════════════════════════════════════
class ActaParser {
  static final _rePatente  = RegExp(r'\b([A-Z]{2}\d{3}[A-Z]{2}|[A-Z]{3}\d{3})\b', caseSensitive: false);
  static final _reFecha    = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})');
  static final _reNumActa  = RegExp(r'(?:N[°º]?|NÚMERO|NUMERO|ACTA)[:\s#]*([0-9\-]{4,20})', caseSensitive: false);
  static final _reFotomulta = RegExp(r'\b(FM[-\s]|FOTOMULTA|FOTO\s*MULTA)\b', caseSensitive: false);
  static final _reAgente = RegExp(r'(?:AGENTE|INSPECTOR)[:\s]*([A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+(?:[ \t]+[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+){0,3}).{0,35}?(?:LEG(?:AJO)?\.?\s*(?:N[°º]\s*)?[:#]?\s*([0-9]{3,8})|N[°º]\s*AGENTE[:\s]*([0-9]{3,8}))', caseSensitive: false);
  static final _reNorma = RegExp(r'(?:ART[.\s]*\d+(?:[.\w()/-]*)(?:\s+INC\.?\s*[a-z0-9]+)?[\s\w()./-]{0,35}?(?:LEY|LN)[.\s]*[\d.]+|LEY[\s]*[\d.]+)', caseSensitive: false);
  static final _reGeo      = RegExp(r'(?:LUGAR|DOMICILIO|CALLE|AV\.|RUTA|KM|AVENIDA)[:\s]+(.{5,80})', caseSensitive: false);

  static OcrResult parsear(String texto, {String motor = 'unknown'}) {
    final upper     = texto.toUpperCase();
    final faltantes = <String>[];

    final patente = extraerPatente(texto);
    if (patente == null) faltantes.add('patente');

    final fecha = _extraerFecha(texto);
    if (fecha == null) faltantes.add('fecha');

    final numActa = _reNumActa.firstMatch(texto)?.group(1)?.trim();
    if (numActa == null || numActa.isEmpty) faltantes.add('número de acta');

    final norma = _reNorma.firstMatch(texto)?.group(0)?.trim();
    final agenteMatch = _reAgente.firstMatch(texto);
    final agente = agenteMatch == null
        ? null
        : '${agenteMatch.group(1)?.trim() ?? ''} ${agenteMatch.group(2) ?? agenteMatch.group(3) ?? ''}'.trim();
    if (norma == null || norma.isEmpty) faltantes.add('norma infringida');

    if (agente == null || agente.isEmpty) faltantes.add('agente');

    return OcrResult(
      textoCompleto:       texto,
      patente:             patente,
      fechaInfraccion:     fecha,
      numeroActa:          numActa,
      normaInfringida:     norma,
      agente:              agente,
      lugarInfraccion:     _reGeo.firstMatch(texto)?.group(1)?.trim(),
      jurisdiccionDetectada: _detectarJurisdiccion(upper),
      esFotomulta:         _reFotomulta.hasMatch(texto),
      camposFaltantes:     faltantes,
      motor:               motor,
    );
  }

  static String? extraerPatente(String texto) =>
      _rePatente.firstMatch(texto.toUpperCase())?.group(0);

  static DateTime? _extraerFecha(String texto) {
    final m = _reFecha.firstMatch(texto);
    if (m == null) return null;
    try {
      final d  = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final y  = int.parse(m.group(3)!);
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
      final fecha = DateTime(y, mo, d);
      if (fecha.year != y || fecha.month != mo || fecha.day != d) return null;
      return fecha;
    } catch (_) { return null; }
  }

  static String? _detectarJurisdiccion(String upper) {
    if (upper.contains('CIUDAD AUTÓNOMA') || upper.contains('GCBA') ||
        upper.contains('CABA') || upper.contains('LEY 1217') ||
        upper.contains('LEY 451')) return 'CABA';
    if (upper.contains('PROVINCIA DE BUENOS AIRES') || upper.contains('JAITP') ||
        upper.contains('LEY 13.927') || upper.contains('LEY 15.002')) return 'PBA';
    if (upper.contains('MENDOZA') || upper.contains('LEY 9024')) return 'Mendoza';
    if (upper.contains('CÓRDOBA') || upper.contains('CORDOBA')) return 'Córdoba';
    if (upper.contains('SANTA FE')) return 'Santa Fe';
    if (upper.contains('TUCUMÁN') || upper.contains('TUCUMAN')) return 'Tucumán';
    if (upper.contains('SALTA')) return 'Salta';
    if (upper.contains('NEUQUÉN') || upper.contains('NEUQUEN')) return 'Neuquén';
    return null;
  }
}

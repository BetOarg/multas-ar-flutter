import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../database/app_database.dart';
import '../database/daos/normativa_dao.dart';

// ══════════════════════════════════════════════════════════════════
// NORMATIVA REPOSITORY
// Carga normativa desde assets locales (seed) o desde URL remota
// (OTA). Usa versionado: solo actualiza si el servidor tiene
// versión mayor a la almacenada en la DB.
//
// URL OTA apunta al JSON versionado en assets/normativa del repositorio.
 // Mantener el esquema JSON compatible con _actualizarDesdeJson.
// ══════════════════════════════════════════════════════════════════

class NormativaRepository {
  static const _urlOta =
      'https://raw.githubusercontent.com/BetOarg/multas-ar-flutter/main/assets/normativa/normativa_base.json';
  static const _assetPath = 'assets/normativa/normativa_base.json';

  final NormativaDao _dao;

  NormativaRepository(this._dao);

  // ── Inicializar — carga seed si la DB está vacía ──────────
  Future<void> inicializar() async {
    final version = await _dao.getVersionActual();
    if (version == 0) {
      await seedDesdeAssets();
    }
  }

  // ── Seed desde assets (primera vez o reinstalación) ───────
  Future<void> seedDesdeAssets() async {
    try {
      final raw  = await rootBundle.loadString(_assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      await _actualizarDesdeJson(json);
    } catch (e) {
      // No interrumpir la app si el asset falla
      assert(false, 'Error cargando normativa desde assets: $e');
    }
  }

  // ── Actualización OTA ─────────────────────────────────────
  /// Retorna [true] si hubo actualización, [false] si ya estaba
  /// vigente o si hubo error de red.
  Future<bool> actualizarOta({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      final resp = await http
          .get(Uri.parse(_urlOta))
          .timeout(timeout);

      if (resp.statusCode != 200) return false;

      final json       = jsonDecode(resp.body) as Map<String, dynamic>;
      final versionRemota = json['version'] as int? ?? 0;
      final versionLocal  = await _dao.getVersionActual();

      if (versionRemota <= versionLocal) return false;

      await _actualizarDesdeJson(json);
      return true;
    } catch (_) {
      // Sin conexión o timeout → continuar con versión local
      return false;
    }
  }

  // ── Internos ──────────────────────────────────────────────
  Future<void> _actualizarDesdeJson(Map<String, dynamic> json) async {
    final version  = json['version'] as int? ?? 1;
    final entradas = (json['entradas'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final companions = entradas.map((e) {
      return NormativaEntradasCompanion(
        jurisdiccion:      Value(e['jurisdiccion'] as String),
        categoria:         Value(e['categoria'] as String),
        titulo:            Value(e['titulo'] as String),
        contenido:         Value(e['contenido'] as String),
        normaBase:         Value(e['norma_base'] as String? ?? ''),
        esAltaImportancia: Value(e['es_alta_importancia'] as bool? ?? false),
        tieneAlertaDual:   Value(e['tiene_alerta_dual'] as bool? ?? false),
        alertaDualDetalle: Value(e['alerta_dual_detalle'] as String?),
        orden:             Value(e['orden'] as int? ?? 99),
        version:           Value(version),
      );
    }).toList();

    await _dao.actualizarDesdeJson(companions);

    // Seed feriados nacionales 2026 si es la primera carga
    final feriadosJson = json['feriados'] as List<dynamic>?;
    if (feriadosJson != null) {
      await _seedFeriados(feriadosJson.cast<Map<String, dynamic>>());
    } else if ((await _dao.getFeriadosPorAnio(2026)).isEmpty) {
      // No duplicar el seed de respaldo cada vez que se aplique una OTA
      // que no incluya una lista explícita de feriados.
      await _seedFeriados2026();
    }
  }

  Future<void> _seedFeriados(List<Map<String, dynamic>> lista) async {
    final companions = lista.map((f) {
      final fecha = DateTime.parse(f['fecha'] as String);
      return FeriadosCompanion(
        fecha:         Value(fecha),
        anio:          Value(fecha.year),
        descripcion:   Value(f['descripcion'] as String? ?? ''),
        tipo:          Value(f['tipo'] as String? ?? 'nacional'),
        jurisdiccion:  Value(f['jurisdiccion'] as String?),
      );
    }).toList();
    await _dao.reemplazarFeriados(companions);
  }

  /// Feriados nacionales 2026 como fallback si no vienen en el JSON
  Future<void> _seedFeriados2026() async {
    final nacionales2026 = [
      (DateTime(2026, 1, 1),  'Año Nuevo'),
      (DateTime(2026, 2, 16), 'Carnaval'),
      (DateTime(2026, 2, 17), 'Carnaval'),
      (DateTime(2026, 3, 24), 'Día Nacional de la Memoria'),
      (DateTime(2026, 4, 2),  'Día del Veterano de Malvinas'),
      (DateTime(2026, 4, 3),  'Viernes Santo'),
      (DateTime(2026, 5, 1),  'Día del Trabajo'),
      (DateTime(2026, 5, 25), 'Revolución de Mayo'),
      (DateTime(2026, 6, 17), 'Paso a la Inmortalidad del Gral. Güemes'),
      (DateTime(2026, 6, 20), 'Día de la Bandera — Gral. Belgrano'),
      (DateTime(2026, 7, 9),  'Día de la Independencia'),
      (DateTime(2026, 8, 17), 'Paso a la Inmortalidad del Gral. San Martín'),
      (DateTime(2026, 10, 12),'Día del Respeto a la Diversidad Cultural'),
      (DateTime(2026, 11, 20),'Día de la Soberanía Nacional'),
      (DateTime(2026, 12, 8), 'Inmaculada Concepción de María'),
      (DateTime(2026, 12, 25),'Navidad'),
    ];

    final companions = nacionales2026.map((f) {
      return FeriadosCompanion(
        fecha:        Value(f.$1),
        anio:         Value(f.$1.year),
        descripcion:  Value(f.$2),
        tipo:         Value('nacional'),
        jurisdiccion: const Value(null),
      );
    }).toList();

    await _dao.insertarFeriados(companions);
  }
}

import 'package:drift/drift.dart';

// ══════════════════════════════════════════════════════════════════
// TABLAS DRIFT — Multas Argentina Pro
// 6 tablas: Casos, Plazos, Escritos, NormativaEntradas,
//           Configuracion, Feriados
// ══════════════════════════════════════════════════════════════════

// ── Casos ─────────────────────────────────────────────────────────
class Casos extends Table {
  TextColumn  get id               => text().named('id')();
  TextColumn  get jurisdiccion     => text().nullable()();
  TextColumn  get numeroActa       => text().named('numero_acta').nullable()();
  TextColumn  get patente          => text().nullable()();
  DateTimeColumn get fechaInfraccion  => dateTime().named('fecha_infraccion').nullable()();
  DateTimeColumn get fechaNotificacion => dateTime().named('fecha_notificacion').nullable()();
  TextColumn  get normaInfringida  => text().named('norma_infringida').nullable()();
  TextColumn  get agente           => text().nullable()();
  TextColumn  get legajoAgente     => text().named('legajo_agente').nullable()();
  BoolColumn  get tieneFiremaAgente => boolean().named('tiene_firma_agente').withDefault(const Constant(true))();
  TextColumn  get lugarInfraccion  => text().named('lugar_infraccion').nullable()();
  TextColumn  get descripcionHecho => text().named('descripcion_hecho').nullable()();
  TextColumn  get estado           => text().nullable()();
  TextColumn  get tipoFalta        => text().named('tipo_falta').nullable()();
  BoolColumn  get esFotomulta      => boolean().named('es_fotomulta').withDefault(const Constant(false))();
  TextColumn  get textoOcrCompleto => text().named('texto_ocr_completo').nullable()();
  DateTimeColumn get creadoEn      => dateTime().named('creado_en')();
  DateTimeColumn get actualizadoEn => dateTime().named('actualizado_en')();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Plazos ────────────────────────────────────────────────────────
class Plazos extends Table {
  IntColumn  get id               => integer().autoIncrement()();
  TextColumn get casoId           => text().named('caso_id').references(Casos, #id)();
  TextColumn get nombre           => text()();
  TextColumn get norma            => text()();
  DateTimeColumn get fechaInicio  => dateTime().named('fecha_inicio')();
  DateTimeColumn get fechaVencimiento => dateTime().named('fecha_vencimiento')();
  TextColumn get tipoPlazo        => text().named('tipo_plazo')(); // 'habiles_adm' | 'habiles_jud' | 'corridos'
  BoolColumn get notificado       => boolean().withDefault(const Constant(false))();
  BoolColumn get vencido          => boolean().withDefault(const Constant(false))();
}

// ── Escritos ──────────────────────────────────────────────────────
class Escritos extends Table {
  IntColumn  get id           => integer().autoIncrement()();
  TextColumn get casoId       => text().named('caso_id').references(Casos, #id)();
  TextColumn get tipo         => text()(); // 'descargo_pba' | 'nulidad_formal' | etc.
  TextColumn get titulo       => text()();
  TextColumn get contenido    => text()();
  BoolColumn get completo     => boolean().withDefault(const Constant(false))();
  DateTimeColumn get creadoEn    => dateTime().named('creado_en')();
  DateTimeColumn get actualizadoEn => dateTime().named('actualizado_en')();
}

// ── Normativa Entradas ────────────────────────────────────────────
class NormativaEntradas extends Table {
  IntColumn  get id                => integer().autoIncrement()();
  TextColumn get jurisdiccion      => text()();
  TextColumn get categoria         => text()(); // 'ley' | 'plazo' | 'prescripcion' | 'advertencia'
  TextColumn get titulo            => text()();
  TextColumn get contenido         => text()();
  TextColumn get normaBase         => text().named('norma_base')();
  BoolColumn get esAltaImportancia => boolean().named('es_alta_importancia').withDefault(const Constant(false))();
  BoolColumn get tieneAlertaDual   => boolean().named('tiene_alerta_dual').withDefault(const Constant(false))();
  TextColumn get alertaDualDetalle => text().named('alerta_dual_detalle').nullable()();
  IntColumn  get orden             => integer().withDefault(const Constant(99))();
  IntColumn  get version           => integer().withDefault(const Constant(1))();
}

// ── Configuracion ─────────────────────────────────────────────────
class Configuracion extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column> get primaryKey => {clave};
}

// ── Feriados ──────────────────────────────────────────────────────
class Feriados extends Table {
  IntColumn  get id           => integer().autoIncrement()();
  DateTimeColumn get fecha    => dateTime()();
  IntColumn  get anio         => integer()();
  TextColumn get descripcion  => text()();
  TextColumn get tipo         => text()(); // 'nacional' | 'provincial' | 'puente'
  TextColumn get jurisdiccion => text().nullable()();
}

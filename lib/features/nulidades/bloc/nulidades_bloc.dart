import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/nulidades_service.dart';
import '../../../core/constants/legal_constants.dart';
import '../../../core/repository/casos_repository.dart';
import '../../../core/database/daos/escritos_dao.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tables.dart';
import 'package:drift/drift.dart' show Value;

part 'nulidades_event.dart';
part 'nulidades_state.dart';

// ══════════════════════════════════════════════════════════════════
// NULIDADES BLOC
// Orquesta el análisis de nulidades y la generación del escrito.
// Dependencias:
//   - NulidadesService  → motor de análisis
//   - ICasosRepository  → lee datos del caso desde la DB
//   - EscritosDao       → persiste el escrito generado
// ══════════════════════════════════════════════════════════════════

class NulidadesBloc extends Bloc<NulidadesEvent, NulidadesState> {
  final NulidadesService _nulidades;
  final ICasosRepository _repository;
  final EscritosDao _escritosDao;

  NulidadesBloc({
    required NulidadesService nulidadesService,
    required ICasosRepository repository,
    required EscritosDao escritosDao,
  })  : _nulidades = nulidadesService,
        _repository = repository,
        _escritosDao = escritosDao,
        super(const NulidadesInicial()) {
    on<NulidadesAnalizar>(_onAnalizar);
    on<NulidadesGenerarEscrito>(_onGenerarEscrito);
    on<NulidadesLimpiar>(_onLimpiar);
  }

  // ── Analizar ─────────────────────────────────────────────────
  Future<void> _onAnalizar(
    NulidadesAnalizar event,
    Emitter<NulidadesState> emit,
  ) async {
    emit(const NulidadesCargando());
    try {
      final caso = await _repository.getCasoPorId(event.casoId);
      if (caso == null) {
        emit(const NulidadesError(mensaje: 'Caso no encontrado.'));
        return;
      }

      final datos = DatosActaParaAnalisis(
        // La columna es nullable: sin jurisdicción confirmada no inferir PBA/CABA.
        jurisdiccion:      caso.jurisdiccion ?? Jurisdiccion.otra,
        numeroActa:        caso.numeroActa,
        fechaInfraccion:   caso.fechaInfraccion,
        fechaNotificacion: caso.fechaNotificacion,
        patente:           caso.patente,
        normaInfringida:   caso.normaInfringida,
        agente:            caso.agente,
        legajoAgente:      caso.legajoAgente,
        tieneFiremaAgente: caso.tieneFiremaAgente,
        lugarInfraccion:   caso.lugarInfraccion,
        descripcionHecho:  caso.descripcionHecho,
        esFotomulta:       caso.esFotomulta,
        textoCompleto:     caso.textoOcrCompleto,
      );

      final resultado = _nulidades.analizar(datos);

      emit(NulidadesAnalizado(
        resultado: resultado,
        casoId: event.casoId,
      ));
    } catch (e) {
      emit(NulidadesError(
        mensaje: 'Error al analizar nulidades: ${e.toString()}',
      ));
    }
  }

  // ── Generar escrito ──────────────────────────────────────────
  Future<void> _onGenerarEscrito(
    NulidadesGenerarEscrito event,
    Emitter<NulidadesState> emit,
  ) async {
    final estadoActual = state;
    if (estadoActual is! NulidadesAnalizado) return;
    // Nunca asociar el resultado de un caso con otro caso por un evento obsoleto.
    if (estadoActual.casoId != event.casoId) {
      emit(const NulidadesError(
        mensaje: 'El análisis no corresponde al caso seleccionado. Vuelva a analizarlo.',
      ));
      return;
    }

    emit(const NulidadesCargando());
    try {
      final caso = await _repository.getCasoPorId(event.casoId);
      if (caso == null) {
        emit(const NulidadesError(mensaje: 'Caso no encontrado.'));
        return;
      }

      final resultado = estadoActual.resultado;
      final contenido = _buildEscritoNulidad(caso, resultado);

      final id = await _escritosDao.insertarEscrito(
        EscritosCompanion(
          casoId:    Value(event.casoId),
          tipo:      const Value('nulidad_formal'),
          titulo:    const Value('Planteo de Nulidad Formal del Acta'),
          contenido: Value(contenido),
          // El borrador conserva campos de identidad, firma y fecha sin completar.
          completo:  const Value(false),
          creadoEn:  Value(DateTime.now()),
          actualizadoEn: Value(DateTime.now()),
        ),
      );

      emit(NulidadesEscritoGenerado(
        escritoId: id,
        casoId: event.casoId,
      ));
    } catch (e) {
      emit(NulidadesError(
        mensaje: 'Error al generar escrito: ${e.toString()}',
      ));
    }
  }

  void _onLimpiar(NulidadesLimpiar event, Emitter<NulidadesState> emit) {
    emit(const NulidadesInicial());
  }

  // ── Constructor del texto del escrito ────────────────────────
  String _buildEscritoNulidad(dynamic caso, ResultadoNulidades resultado) {
    final buf = StringBuffer();
    final patente    = caso.patente ?? '[PATENTE]';
    final numActa    = caso.numeroActa ?? '[N° ACTA]';
    final jur        = caso.jurisdiccion ?? '[JURISDICCIÓN]';
    final fecha      = caso.fechaInfraccion != null
        ? '${caso.fechaInfraccion!.day.toString().padLeft(2, '0')}/'
          '${caso.fechaInfraccion!.month.toString().padLeft(2, '0')}/'
          '${caso.fechaInfraccion!.year}'
        : '[FECHA]';

    buf.writeln('PLANTEO DE NULIDAD FORMAL DEL ACTA');
    buf.writeln('${'═' * 50}');
    buf.writeln();
    buf.writeln('Señor/a Juez/a:');
    buf.writeln();
    buf.writeln(
      '[NOMBRE Y APELLIDO], DNI N° [DNI], con domicilio en '
      '[DOMICILIO], constituyendo domicilio procesal en [DOMICILIO PROCESAL], '
      'a V.S. respetuosamente me presento y digo:',
    );
    buf.writeln();
    buf.writeln('I. OBJETO');
    buf.writeln();
    buf.writeln(
      'Que vengo a plantear la NULIDAD FORMAL del acta de infracción '
      'N° $numActa, labrada en fecha $fecha en jurisdicción $jur, '
      'respecto del vehículo dominio $patente, '
      'por los fundamentos que a continuación se exponen.',
    );
    buf.writeln();

    // Causales absolutas
    final absolutas = resultado.causalesDetectadas
        .where((c) => c.tipo == TipoNulidad.absoluta)
        .toList();
    if (absolutas.isNotEmpty) {
      buf.writeln('II. CAUSALES DE NULIDAD ABSOLUTA');
      buf.writeln();
      for (int i = 0; i < absolutas.length; i++) {
        final c = absolutas[i];
        buf.writeln('${i + 1}. ${c.titulo.toUpperCase()}');
        buf.writeln();
        buf.writeln(c.descripcion);
        buf.writeln();
        if (c.argumentoJuridico != null) {
          buf.writeln(c.argumentoJuridico);
          buf.writeln();
        }
        buf.writeln('Norma: ${c.norma}');
        buf.writeln();
      }
    }

    // Causales relativas
    final relativas = resultado.causalesDetectadas
        .where((c) => c.tipo != TipoNulidad.absoluta)
        .toList();
    if (relativas.isNotEmpty) {
      buf.writeln('III. CAUSALES DE NULIDAD RELATIVA');
      buf.writeln();
      for (int i = 0; i < relativas.length; i++) {
        final c = relativas[i];
        buf.writeln('${i + 1}. ${c.titulo.toUpperCase()}');
        buf.writeln();
        buf.writeln(c.descripcion);
        if (c.argumentoJuridico != null) {
          buf.writeln();
          buf.writeln(c.argumentoJuridico);
        }
        buf.writeln();
        buf.writeln('Norma: ${c.norma}');
        buf.writeln();
      }
    }

    buf.writeln('IV. DERECHO');
    buf.writeln();
    buf.writeln(
      'Fundo el presente en los artículos citados ut supra, '
      'en el Art. 18 de la Constitución Nacional (derecho de defensa '
      'en juicio), y en los principios generales del derecho '
      'administrativo sancionador.',
    );
    buf.writeln();
    buf.writeln('V. PETITORIO');
    buf.writeln();
    buf.writeln(
      'Por todo lo expuesto, solicito a V.S.:',
    );
    buf.writeln();
    buf.writeln(
      '1. Se tenga por presentado el planteo de nulidad.');
    buf.writeln(
      '2. Se declare la NULIDAD del acta N° $numActa '
      'y se disponga el archivo de las actuaciones.');
    buf.writeln(
      '3. Con costas.');
    buf.writeln();
    buf.writeln(
      'Proveer de conformidad,');
    buf.writeln('SERÁ JUSTICIA.');
    buf.writeln();
    buf.writeln(
      '[Lugar], [Fecha]');
    buf.writeln();
    buf.writeln('${'─' * 40}');
    buf.writeln('[Firma del letrado]');
    buf.writeln('[Nombre y matrícula]');

    return buf.toString();
  }

}

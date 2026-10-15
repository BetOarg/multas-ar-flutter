import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:drift/drift.dart';
import '../../../core/database/tables/tables.dart';
import '../../../core/repository/casos_repository.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/plazos_service.dart';
import '../../../core/services/analisis_service.dart';

part 'analisis_event.dart';
part 'analisis_state.dart';

// ══════════════════════════════════════════════════════════════════
// ANALISIS BLOC
// Orquesta: OCR → parseo → análisis normativo → plazos → guardado
// ══════════════════════════════════════════════════════════════════

class AnalisisBloc extends Bloc<AnalisisEvent, AnalisisState> {
  final ICasosRepository _casosRepository;
  final IOcrService _ocrService;
  final PlazosService _plazosService;
  final AnalisisService _analisisService;

  AnalisisBloc({
    required ICasosRepository casosRepository,
    required IOcrService ocrService,
    required PlazosService plazosService,
    required AnalisisService analisisService,
  })  : _casosRepository = casosRepository,
        _ocrService = ocrService,
        _plazosService = plazosService,
        _analisisService = analisisService,
        super(const AnalisisInitial()) {

    on<AnalizarImagenEvent>(_onAnalizarImagen);
    on<AnalizarFormularioEvent>(_onAnalizarFormulario);
    on<GuardarCasoEvent>(_onGuardarCaso);
    on<ActualizarCampoEvent>(_onActualizarCampo);
    on<LimpiarAnalisisEvent>(_onLimpiar);
  }

  // ── OCR + análisis desde imagen ──────────────────────────────
  Future<void> _onAnalizarImagen(
    AnalizarImagenEvent event,
    Emitter<AnalisisState> emit,
  ) async {
    emit(const AnalisisOcrEnProceso());

    try {
      // 1. OCR — extraer texto de la imagen
      final acta = await _ocrService.extraerCamposActa(event.imagen);
      emit(AnalisisOcrCompletado(acta: acta));

      // 2. Si hay jurisdicción y fecha → calcular plazos
      if (acta.jurisdiccion != null) {
        emit(AnalisisCalculandoPlazos(acta: acta));
        final resultado = await _analisisService.analizar(
          jurisdiccion: acta.jurisdiccion!,
          fechaNotificacion: acta.fechaInfraccion, // preliminar
          tipoFalta: null,
          erroresFormales: acta.erroresFormalesDetectados,
          titularEsConductor: null,
          estadoProcesal: null,
          vaJudicial: false,
          agotamientoVia: false,
        );
        emit(AnalisisCompletado(acta: acta, resultado: resultado));
      }
    } catch (e) {
      emit(AnalisisError(mensaje: 'Error al procesar la imagen: $e'));
    }
  }

  // ── Análisis desde formulario manual ────────────────────────
  Future<void> _onAnalizarFormulario(
    AnalizarFormularioEvent event,
    Emitter<AnalisisState> emit,
  ) async {
    emit(const AnalisisCalculandoPlazos());

    try {
      final resultado = await _analisisService.analizar(
        jurisdiccion: event.jurisdiccion,
        fechaNotificacion: event.fechaNotificacion,
        tipoFalta: event.tipoFalta,
        erroresFormales: event.erroresFormales,
        titularEsConductor: event.titularEsConductor,
        estadoProcesal: event.estadoProcesal,
        vaJudicial: event.vaJudicial,
        agotamientoVia: event.agotamientoVia,
        numeroActa: event.numeroActa,
      );
      emit(AnalisisCompletado(resultado: resultado));
    } catch (e) {
      emit(AnalisisError(mensaje: 'Error en el análisis: $e'));
    }
  }

  // ── Guardar caso en base de datos ────────────────────────────
  Future<void> _onGuardarCaso(
    GuardarCasoEvent event,
    Emitter<AnalisisState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnalisisCompletado) return;

    emit(AnalisisGuardando(resultado: currentState.resultado));

    try {
      final id = await _casosRepository.crearCaso(
        CasosCompanion.insert(
          id: Value(event.id ?? _generarId()),
          jurisdiccion: event.jurisdiccion,
          numeroActa: Value(event.numeroActa),
          fechaNotificacion: Value(event.fechaNotificacion),
          tipoFalta: Value(event.tipoFalta),
          patente: Value(event.patente),
          estadoProcesal: Value(event.estadoProcesal ?? 'admin'),
          normaImputada: Value(event.normaImputada),
          erroresFormales: Value(event.erroresFormales?.join('|')),
        ),
      );
      emit(AnalisisGuardado(casoId: id, resultado: currentState.resultado));
    } catch (e) {
      emit(AnalisisError(mensaje: 'Error al guardar el caso: $e'));
    }
  }

  // ── Actualizar campo individual del formulario ───────────────
  void _onActualizarCampo(
    ActualizarCampoEvent event,
    Emitter<AnalisisState> emit,
  ) {
    final currentState = state;
    if (currentState is AnalisisFormularioActivo) {
      emit(currentState.copyWith(campos: {
        ...currentState.campos,
        event.campo: event.valor,
      }));
    } else {
      emit(AnalisisFormularioActivo(campos: {event.campo: event.valor}));
    }
  }

  void _onLimpiar(LimpiarAnalisisEvent event, Emitter<AnalisisState> emit) {
    emit(const AnalisisInitial());
  }

  String _generarId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}

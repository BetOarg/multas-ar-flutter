import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables/tables.dart';
import '../../../core/repository/casos_repository.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/plazos_service.dart';
import '../../../core/services/analisis_service.dart';
import '../../../core/constants/legal_constants.dart';

part 'analisis_event.dart';
part 'analisis_state.dart';

/// Coordina OCR, análisis de reglas/plazos y persistencia local.
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

  Future<void> _onAnalizarImagen(
    AnalizarImagenEvent event,
    Emitter<AnalisisState> emit,
  ) async {
    emit(const AnalisisOcrEnProceso());
    try {
      final ocr = await _ocrService.reconocer(event.imagen.path);
      emit(AnalisisOcrCompletado(acta: ocr));

      final jurisdiccion = ocr.jurisdiccionDetectada;
      if (jurisdiccion == null || jurisdiccion.trim().isEmpty) {
        emit(AnalisisError(
          mensaje: 'No se pudo detectar la jurisdicción. Seleccionala y analizá el formulario.',
        ));
        return;
      }

      emit(AnalisisCalculandoPlazos(acta: ocr));
      final resultado = _analisisService.analizar(DatosActa(
        jurisdiccion: jurisdiccion,
        numeroActa: ocr.numeroActa,
        fechaInfraccion: ocr.fechaInfraccion,
        patente: ocr.patente,
        normaInfringida: ocr.normaInfringida,
        tipoFalta: TipoFalta.leve,
        lugarInfraccion: ocr.lugarInfraccion,
        agente: ocr.agente,
        esFotomulta: ocr.esFotomulta,
      ));
      emit(AnalisisCompletado(acta: ocr, resultado: resultado));
    } catch (e) {
      emit(AnalisisError(mensaje: 'Error al procesar la imagen: $e'));
    }
  }

  Future<void> _onAnalizarFormulario(
    AnalizarFormularioEvent event,
    Emitter<AnalisisState> emit,
  ) async {
    emit(const AnalisisCalculandoPlazos());
    try {
      final resultado = _analisisService.analizar(DatosActa(
        jurisdiccion: event.jurisdiccion,
        fechaNotificacion: event.fechaNotificacion,
        tipoFalta: event.tipoFalta ?? TipoFalta.leve,
        numeroActa: event.numeroActa,
      ));
      emit(AnalisisCompletado(resultado: resultado));
    } catch (e) {
      emit(AnalisisError(mensaje: 'Error en el análisis: $e'));
    }
  }

  Future<void> _onGuardarCaso(
    GuardarCasoEvent event,
    Emitter<AnalisisState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AnalisisCompletado) return;

    emit(AnalisisGuardando(resultado: currentState.resultado));
    try {
      final now = DateTime.now();
      final id = await _casosRepository.crearCaso(CasosCompanion.insert(
        id: event.id ?? _generarId(),
        jurisdiccion: event.jurisdiccion,
        numeroActa: event.numeroActa,
        fechaNotificacion: event.fechaNotificacion,
        tipoFalta: event.tipoFalta,
        patente: event.patente,
        estado: event.estadoProcesal ?? 'admin',
        normaInfringida: event.normaImputada,
        creadoEn: now,
        actualizadoEn: now,
      ));
      emit(AnalisisGuardado(casoId: id, resultado: currentState.resultado));
    } catch (e) {
      emit(AnalisisError(mensaje: 'Error al guardar el caso: $e'));
    }
  }

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

  String _generarId() => DateTime.now().microsecondsSinceEpoch.toString();
}

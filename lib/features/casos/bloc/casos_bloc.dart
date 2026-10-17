import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/database/app_database.dart';
import '../../../core/repository/casos_repository.dart';
import '../../../core/database/daos/plazos_dao.dart';
import '../../../core/services/analisis_service.dart';

part 'casos_event.dart';
part 'casos_state.dart';

class CasosBloc extends Bloc<CasosEvent, CasosState> {
  final ICasosRepository _repo;
  final PlazosDao? _plazosDao;

  CasosBloc({required ICasosRepository casosRepository, PlazosDao? plazosDao})
      : _repo = casosRepository,
        _plazosDao = plazosDao,
        super(const CasosInitial()) {
    on<CargarCasosEvent>(_onCargar);
    on<CasoCargar>(_onCargarDetalle);
    on<CasoEliminar>(_onEliminarDetalle);
    on<ArchivarCasoEvent>(_onArchivar);
    on<ActualizarEstadoCasoEvent>(_onActualizarEstado);
  }

  Future<void> _onCargar(
      CargarCasosEvent event, Emitter<CasosState> emit) async {
    emit(const CasosCargando());
    await emit.forEach<List<Caso>>(
      _repo.watchCasosActivos(),
      onData: (lista) => lista.isEmpty
          ? const CasosVacio()
          : CasosCargados(casos: lista),
      onError: (e, _) => CasosError(mensaje: e.toString()),
    );
  }

  Future<void> _onCargarDetalle(
      CasoCargar event, Emitter<CasosState> emit) async {
    emit(const CasosCargando());
    try {
      final caso = await _repo.getCasoPorId(event.casoId);
      if (caso == null) {
        emit(const CasosError(mensaje: 'Caso no encontrado.'));
        return;
      }
      final plazos = _plazosDao == null
          ? <Plazo>[]
          : await _plazosDao!.getPlazosDeCaso(event.casoId);
      emit(CasoDetalleCargado(
        caso: caso,
        plazos: plazos,
        alertas: const <AlertaLegal>[],
      ));
    } catch (error) {
      emit(CasosError(mensaje: 'No se pudo cargar el detalle: $error'));
    }
  }

  Future<void> _onEliminarDetalle(
      CasoEliminar event, Emitter<CasosState> emit) async {
    try {
      await _repo.eliminarCaso(event.casoId);
      emit(const CasosVacio());
    } catch (error) {
      emit(CasosError(mensaje: 'No se pudo eliminar el caso: $error'));
    }
  }

  Future<void> _onArchivar(
      ArchivarCasoEvent event, Emitter<CasosState> emit) async {
    await _repo.archivarCaso(event.casoId);
  }

  Future<void> _onActualizarEstado(
      ActualizarEstadoCasoEvent event, Emitter<CasosState> emit) async {
    await _repo.actualizarEstado(event.casoId, event.nuevoEstado);
  }
}

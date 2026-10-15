import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/database/tables/tables.dart';
import '../../../core/repository/casos_repository.dart';

part 'casos_event.dart';
part 'casos_state.dart';

class CasosBloc extends Bloc<CasosEvent, CasosState> {
  final ICasosRepository _repo;

  CasosBloc({required ICasosRepository casosRepository})
      : _repo = casosRepository,
        super(const CasosInitial()) {
    on<CargarCasosEvent>(_onCargar);
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

  Future<void> _onArchivar(
      ArchivarCasoEvent event, Emitter<CasosState> emit) async {
    await _repo.archivarCaso(event.casoId);
  }

  Future<void> _onActualizarEstado(
      ActualizarEstadoCasoEvent event, Emitter<CasosState> emit) async {
    await _repo.actualizarEstado(event.casoId, event.nuevoEstado);
  }
}

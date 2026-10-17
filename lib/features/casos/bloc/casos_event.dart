part of 'casos_bloc.dart';

sealed class CasosEvent extends Equatable {
  const CasosEvent();
  @override
  List<Object?> get props => [];
}

class CasoCargar extends CasosEvent {
  final String casoId;
  const CasoCargar({required this.casoId});
  @override
  List<Object?> get props => [casoId];
}

class CasoEliminar extends CasosEvent {
  final String casoId;
  const CasoEliminar({required this.casoId});
  @override
  List<Object?> get props => [casoId];
}

class CargarCasosEvent extends CasosEvent {
  const CargarCasosEvent();
}

class ArchivarCasoEvent extends CasosEvent {
  final String casoId;
  const ArchivarCasoEvent({required this.casoId});
  @override
  List<Object?> get props => [casoId];
}

class ActualizarEstadoCasoEvent extends CasosEvent {
  final String casoId;
  final String nuevoEstado;
  const ActualizarEstadoCasoEvent({
    required this.casoId,
    required this.nuevoEstado,
  });
  @override
  List<Object?> get props => [casoId, nuevoEstado];
}

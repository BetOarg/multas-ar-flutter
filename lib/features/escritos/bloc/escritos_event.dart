part of 'escritos_bloc.dart';

sealed class EscritosEvent extends Equatable {
  const EscritosEvent();
  @override
  List<Object?> get props => [];
}

class SeleccionarModeloEvent extends EscritosEvent {
  final String modeloId;
  const SeleccionarModeloEvent({required this.modeloId});
  @override
  List<Object?> get props => [modeloId];
}

class LimpiarEscritoEvent extends EscritosEvent {
  const LimpiarEscritoEvent();
}

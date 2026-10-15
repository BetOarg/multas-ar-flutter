part of 'escritos_bloc.dart';

sealed class EscritosState extends Equatable {
  const EscritosState();
  @override
  List<Object?> get props => [];
}

class EscritosInitial extends EscritosState {
  const EscritosInitial();
}

class EscritoSeleccionado extends EscritosState {
  final ModeloEscrito modelo;
  const EscritoSeleccionado({required this.modelo});
  @override
  List<Object?> get props => [modelo.id];
}

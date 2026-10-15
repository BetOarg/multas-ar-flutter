part of 'casos_bloc.dart';

sealed class CasosState extends Equatable {
  const CasosState();
  @override
  List<Object?> get props => [];
}

class CasosInitial extends CasosState {
  const CasosInitial();
}

class CasosCargando extends CasosState {
  const CasosCargando();
}

class CasosCargados extends CasosState {
  final List<Caso> casos;
  const CasosCargados({required this.casos});
  @override
  List<Object?> get props => [casos];
}

class CasosVacio extends CasosState {
  const CasosVacio();
}

class CasosError extends CasosState {
  final String mensaje;
  const CasosError({required this.mensaje});
  @override
  List<Object?> get props => [mensaje];
}

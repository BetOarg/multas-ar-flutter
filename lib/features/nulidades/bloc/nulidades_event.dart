part of 'nulidades_bloc.dart';

abstract class NulidadesEvent extends Equatable {
  const NulidadesEvent();
  @override
  List<Object?> get props => [];
}

/// Disparar análisis de nulidades para un caso
class NulidadesAnalizar extends NulidadesEvent {
  final String casoId;
  const NulidadesAnalizar({required this.casoId});
  @override
  List<Object?> get props => [casoId];
}

/// Generar escrito de nulidad a partir del resultado
class NulidadesGenerarEscrito extends NulidadesEvent {
  final String casoId;
  const NulidadesGenerarEscrito({required this.casoId});
  @override
  List<Object?> get props => [casoId];
}

/// Limpiar resultado (para nuevo análisis)
class NulidadesLimpiar extends NulidadesEvent {
  const NulidadesLimpiar();
}

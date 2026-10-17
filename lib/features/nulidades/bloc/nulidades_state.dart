part of 'nulidades_bloc.dart';

abstract class NulidadesState extends Equatable {
  const NulidadesState();
  @override
  List<Object?> get props => [];
}

class NulidadesInicial extends NulidadesState {
  const NulidadesInicial();
}

class NulidadesCargando extends NulidadesState {
  const NulidadesCargando();
}

class NulidadesAnalizado extends NulidadesState {
  final ResultadoNulidades resultado;
  final String casoId;
  const NulidadesAnalizado({required this.resultado, required this.casoId});
  @override
  List<Object?> get props => [
    casoId,
    resultado.causalesDetectadas.map((causal) => causal.id).toList(),
    resultado.causalesPotenciales.map((causal) => causal.id).toList(),
    resultado.recomendacion,
    resultado.tieneNulidadAbsoluta,
  ];
}

class NulidadesEscritoGenerado extends NulidadesState {
  final int escritoId;
  final String casoId;
  const NulidadesEscritoGenerado({
    required this.escritoId,
    required this.casoId,
  });
  @override
  List<Object?> get props => [escritoId, casoId];
}

class NulidadesError extends NulidadesState {
  final String mensaje;
  const NulidadesError({required this.mensaje});
  @override
  List<Object?> get props => [mensaje];
}

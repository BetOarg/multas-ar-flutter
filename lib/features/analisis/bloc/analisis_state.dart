part of 'analisis_bloc.dart';

sealed class AnalisisState extends Equatable {
  const AnalisisState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial — formulario vacío
class AnalisisInitial extends AnalisisState {
  const AnalisisInitial();
}

/// Formulario activo con campos parcialmente completados
class AnalisisFormularioActivo extends AnalisisState {
  final Map<String, dynamic> campos;
  const AnalisisFormularioActivo({required this.campos});

  AnalisisFormularioActivo copyWith({Map<String, dynamic>? campos}) {
    return AnalisisFormularioActivo(campos: campos ?? this.campos);
  }

  @override
  List<Object?> get props => [campos];
}

/// OCR en proceso (analizando imagen)
class AnalisisOcrEnProceso extends AnalisisState {
  const AnalisisOcrEnProceso();
}

/// OCR completado — datos extraídos disponibles para corrección
class AnalisisOcrCompletado extends AnalisisState {
  final ActaExtraida acta;
  const AnalisisOcrCompletado({required this.acta});

  @override
  List<Object?> get props => [acta];
}

/// Calculando plazos y análisis normativo
class AnalisisCalculandoPlazos extends AnalisisState {
  final ActaExtraida? acta;
  const AnalisisCalculandoPlazos({this.acta});

  @override
  List<Object?> get props => [acta];
}

/// Análisis completado — resultado disponible
class AnalisisCompletado extends AnalisisState {
  final ActaExtraida? acta;
  final ResultadoAnalisis resultado;

  const AnalisisCompletado({
    this.acta,
    required this.resultado,
  });

  @override
  List<Object?> get props => [acta, resultado];
}

/// Guardando el caso en base de datos
class AnalisisGuardando extends AnalisisState {
  final ResultadoAnalisis resultado;
  const AnalisisGuardando({required this.resultado});

  @override
  List<Object?> get props => [resultado];
}

/// Caso guardado correctamente
class AnalisisGuardado extends AnalisisState {
  final String casoId;
  final ResultadoAnalisis resultado;

  const AnalisisGuardado({
    required this.casoId,
    required this.resultado,
  });

  @override
  List<Object?> get props => [casoId];
}

/// Error en cualquier etapa del análisis
class AnalisisError extends AnalisisState {
  final String mensaje;
  const AnalisisError({required this.mensaje});

  @override
  List<Object?> get props => [mensaje];
}

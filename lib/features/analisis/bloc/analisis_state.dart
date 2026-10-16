part of 'analisis_bloc.dart';

sealed class AnalisisState extends Equatable {
  const AnalisisState();

  @override
  List<Object?> get props => [];
}

class AnalisisInitial extends AnalisisState {
  const AnalisisInitial();
}

class AnalisisFormularioActivo extends AnalisisState {
  final Map<String, dynamic> campos;
  const AnalisisFormularioActivo({required this.campos});

  AnalisisFormularioActivo copyWith({Map<String, dynamic>? campos}) =>
      AnalisisFormularioActivo(campos: campos ?? this.campos);

  @override
  List<Object?> get props => [campos];
}

class AnalisisOcrEnProceso extends AnalisisState {
  const AnalisisOcrEnProceso();
}

class AnalisisOcrCompletado extends AnalisisState {
  final OcrResult acta;
  const AnalisisOcrCompletado({required this.acta});

  @override
  List<Object?> get props => [acta.textoCompleto, acta.motor];
}

class AnalisisCalculandoPlazos extends AnalisisState {
  final OcrResult? acta;
  const AnalisisCalculandoPlazos({this.acta});

  @override
  List<Object?> get props => [acta?.textoCompleto];
}

class AnalisisCompletado extends AnalisisState {
  final OcrResult? acta;
  final ResultadoAnalisis resultado;

  const AnalisisCompletado({this.acta, required this.resultado});

  @override
  List<Object?> get props => [acta?.textoCompleto, resultado];
}

class AnalisisGuardando extends AnalisisState {
  final ResultadoAnalisis resultado;
  const AnalisisGuardando({required this.resultado});

  @override
  List<Object?> get props => [resultado];
}

class AnalisisGuardado extends AnalisisState {
  final String casoId;
  final ResultadoAnalisis resultado;

  const AnalisisGuardado({required this.casoId, required this.resultado});

  @override
  List<Object?> get props => [casoId];
}

class AnalisisError extends AnalisisState {
  final String mensaje;
  final OcrResult? acta;
  const AnalisisError({required this.mensaje, this.acta});

  @override
  List<Object?> get props => [mensaje, acta?.textoCompleto];
}

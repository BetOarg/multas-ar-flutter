part of 'analisis_bloc.dart';

sealed class AnalisisEvent extends Equatable {
  const AnalisisEvent();

  @override
  List<Object?> get props => [];
}

/// Analizar una imagen subida (foto o PDF convertido)
class AnalizarImagenEvent extends AnalisisEvent {
  final File imagen;
  const AnalizarImagenEvent({required this.imagen});

  @override
  List<Object?> get props => [imagen.path];
}

/// Analizar desde formulario manual (sin imagen)
class AnalizarFormularioEvent extends AnalisisEvent {
  final String jurisdiccion;
  final DateTime? fechaNotificacion;
  final String? tipoFalta;
  final List<String> erroresFormales;
  final bool? titularEsConductor;
  final String? estadoProcesal;
  final bool vaJudicial;
  final bool agotamientoVia;
  final String? numeroActa;

  const AnalizarFormularioEvent({
    required this.jurisdiccion,
    this.fechaNotificacion,
    this.tipoFalta,
    this.erroresFormales = const [],
    this.titularEsConductor,
    this.estadoProcesal,
    this.vaJudicial = false,
    this.agotamientoVia = false,
    this.numeroActa,
  });

  @override
  List<Object?> get props => [
        jurisdiccion,
        fechaNotificacion,
        tipoFalta,
        erroresFormales,
        estadoProcesal,
      ];
}

/// Guardar el caso analizado en la base de datos
class GuardarCasoEvent extends AnalisisEvent {
  final String? id;
  final String jurisdiccion;
  final String? numeroActa;
  final DateTime? fechaNotificacion;
  final String? tipoFalta;
  final String? patente;
  final String? estadoProcesal;
  final String? normaImputada;
  final List<String>? erroresFormales;

  const GuardarCasoEvent({
    this.id,
    required this.jurisdiccion,
    this.numeroActa,
    this.fechaNotificacion,
    this.tipoFalta,
    this.patente,
    this.estadoProcesal,
    this.normaImputada,
    this.erroresFormales,
  });

  @override
  List<Object?> get props => [jurisdiccion, numeroActa];
}

/// Actualizar un campo del formulario en tiempo real
class ActualizarCampoEvent extends AnalisisEvent {
  final String campo;
  final dynamic valor;
  const ActualizarCampoEvent({required this.campo, required this.valor});

  @override
  List<Object?> get props => [campo, valor];
}

/// Limpiar el estado y comenzar un nuevo análisis
class LimpiarAnalisisEvent extends AnalisisEvent {
  const LimpiarAnalisisEvent();
}

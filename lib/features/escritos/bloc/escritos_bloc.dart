import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/repository/casos_repository.dart';

part 'escritos_event.dart';
part 'escritos_state.dart';

// Modelos de escritos disponibles
class ModeloEscrito {
  final String id;
  final String titulo;
  final String jurisdiccion;
  final String icon;
  final String normaBase;
  final List<String> camposObligatorios;
  final String nota;
  final String plantilla;

  const ModeloEscrito({
    required this.id,
    required this.titulo,
    required this.jurisdiccion,
    required this.icon,
    required this.normaBase,
    required this.camposObligatorios,
    required this.nota,
    required this.plantilla,
  });
}

class EscritosBloc extends Bloc<EscritosEvent, EscritosState> {
  final ICasosRepository _repo;

  static const modelos = [
    ModeloEscrito(
      id: 'descargo_pba',
      titulo: 'Descargo administrativo',
      jurisdiccion: 'PBA',
      icon: '📄',
      normaBase: 'Art. 35 Ley 13.927 PBA',
      camposObligatorios: [
        'NÚMERO JUZGADO', 'DEPTO JUDICIAL', 'NOMBRE APELLIDO',
        'DNI', 'CUIL', 'DOMICILIO', 'EMAIL',
        'FECHA NOTIFICACIÓN', 'N° ACTA', 'PATENTE',
      ],
      nota: '⚠️ El recurso debe fundarse en el mismo escrito. '
          'Si no se funda, queda desierto (Art. 40 Ley 13.927).',
      plantilla: 'Al Sr./Sra. Juez/a Administrativo/a de Infracciones de Tránsito\n'
          'Juzgado N° [NÚMERO JUZGADO] — Departamento Judicial [DEPTO JUDICIAL]\n\n'
          '[NOMBRE APELLIDO], DNI [DNI], CUIL [CUIL], domicilio [DOMICILIO], '
          'domicilio electrónico [EMAIL], me presento y digo:\n\n'
          'I. OBJETO\n'
          'Que dentro de los 45 días hábiles administrativos de la notificación del '
          '[FECHA NOTIFICACIÓN], formulo DESCARGO contra el Acta N° [N° ACTA], '
          'vehículo [PATENTE], conforme Art. 35 y cc. Ley 13.927 PBA.\n\n'
          'II. HECHOS\n[⚠️ COMPLETAR — relatar los hechos con precisión]\n\n'
          'III. NULIDADES Y DEFENSAS\n[⚠️ COMPLETAR — indicar defensas formales y sustanciales]\n\n'
          'IV. PRUEBA\n'
          '□ Documental: [LISTAR]\n'
          '□ Pericial: [si corresponde]\n'
          '□ Testimonial: [si corresponde]\n\n'
          'V. PETITORIO\n'
          '1. Se tenga por presentado el descargo en legal tiempo y forma.\n'
          '2. Se admita la prueba ofrecida.\n'
          '3. Oportunamente, se ARCHIVE / ABSUELVA al suscripto.\n\n'
          '[LUGAR Y FECHA]\n[FIRMA — LETRADO PATROCINANTE si lo hubiera]\n\nSERÁ JUSTICIA.',
    ),
    ModeloEscrito(
      id: 'descargo_caba',
      titulo: 'Descargo administrativo',
      jurisdiccion: 'CABA',
      icon: '📄',
      normaBase: 'Art. 8 Ley 1217 CABA (t.c. Ley 6.764/2024)',
      camposObligatorios: [
        'NOMBRE APELLIDO', 'DNI', 'DOMICILIO', 'EMAIL',
        'N° ACTA', 'FECHA NOTIFICACIÓN', 'NORMA IMPUTADA',
      ],
      nota: '⚠️ Plazo: 5 días hábiles administrativos. '
          'Desde reforma Ley 1217: el email es notificación fehaciente.',
      plantilla: 'Al/la Sr./Sra. Controlador/a Administrativo/a de Faltas\n'
          'Ciudad Autónoma de Buenos Aires\n\n'
          '[NOMBRE APELLIDO], DNI [DNI], domicilio [DOMICILIO], '
          'domicilio electrónico [EMAIL], en relación al Acta N° [N° ACTA], digo:\n\n'
          'I. OBJETO\n'
          'Dentro de los 5 días hábiles administrativos de la notificación del [FECHA NOTIFICACIÓN], '
          'formulo DESCARGO por presunta infracción a [NORMA IMPUTADA], '
          'conforme Arts. 8 y cc. Ley 1217 (t.c. Ley 6.764/2024).\n\n'
          'II. HECHOS\n[⚠️ COMPLETAR]\n\n'
          'III. NULIDADES Y DEFENSAS FORMALES\n[⚠️ COMPLETAR]\n\n'
          'IV. PRUEBA\n□ Documental: [ADJUNTAR]\n\n'
          'V. PETITORIO\n'
          '1. Se archive la actuación.\n'
          '2. En subsidio, revisión ante la Junta de Faltas.\n\n'
          'Notificaciones al email: [EMAIL]\n\n'
          '[FECHA — FIRMA]\n\nSERÁ JUSTICIA.',
    ),
    ModeloEscrito(
      id: 'recurso_apelacion_pba',
      titulo: 'Recurso de apelación judicial',
      jurisdiccion: 'PBA',
      icon: '⚖️',
      normaBase: 'Arts. 40-41 Ley 13.927 PBA',
      camposObligatorios: [
        'TRIBUNAL', 'EXPEDIENTE', 'NOMBRE', 'DNI',
        'DOMICILIO PROCESAL', 'EMAIL', 'FECHA RESOLUCIÓN',
        'N° JUZGADO ADMIN', 'AGRAVIOS',
      ],
      nota: '🚨 CRÍTICO: DEBE fundarse en el mismo escrito. '
          'Si no se funda queda desierto (Art. 40). '
          'Plazo: 5 días hábiles desde notificación de la condena.',
      plantilla: '[TRIBUNAL]\nExpediente N° [EXPEDIENTE]\n\n'
          '[NOMBRE], DNI [DNI], domicilio procesal [DOMICILIO PROCESAL], '
          'domicilio electrónico [EMAIL], me presento y digo:\n\n'
          'I. OBJETO\n'
          'Dentro del plazo de 5 días hábiles (Art. 41 Ley 13.927), interpongo '
          'RECURSO DE APELACIÓN con fundamentos contra la resolución del '
          '[FECHA RESOLUCIÓN] del Juzgado Admin. N° [N° JUZGADO ADMIN].\n\n'
          'II. ADMISIBILIDAD\n'
          '- Interpuesto en término (Art. 41 Ley 13.927).\n'
          '- Fundado en el presente escrito (Art. 40 Ley 13.927).\n\n'
          'III. AGRAVIOS\n[⚠️ AGRAVIOS — desarrollar con precisión fáctica y jurídica]\n\n'
          'IV. DERECHO\n'
          '- Art. 18 CN (defensa en juicio)\n'
          '- Arts. 38-41 Ley 13.927 PBA\n'
          '- [⚠️ NO citar jurisprudencia sin fuente verificada]\n\n'
          'V. PETITORIO\n'
          '1. Se tenga por interpuesto el recurso en término y forma.\n'
          '2. Se eleven las actuaciones al tribunal de alzada.\n'
          '3. Oportunamente, se REVOQUE la resolución y se ARCHIVE / ABSUELVA.\n\n'
          '[FECHA — FIRMA — LETRADO]\n\nSERÁ JUSTICIA.',
    ),
    ModeloEscrito(
      id: 'prescripcion_admin',
      titulo: 'Solicitud de prescripción',
      jurisdiccion: 'Todas',
      icon: '⏱️',
      normaBase: 'Art. 89 Ley 24.449 / Ley 451 CABA / Art. 94 Ley 9024 Mendoza',
      camposObligatorios: [
        'ORGANISMO DESTINATARIO', 'NOMBRE', 'DNI',
        'DOMICILIO', 'EMAIL', 'N° ACTA', 'FECHA INFRACCIÓN',
        'NORMA PRESCRIPCIÓN', 'PLAZO APLICABLE',
      ],
      nota: '⚠️ La prescripción NO opera automáticamente. '
          'Debe ser invocada y reconocida formalmente por el organismo.',
      plantilla: '[ORGANISMO DESTINATARIO]\n\n'
          '[NOMBRE], DNI [DNI], domicilio [DOMICILIO], '
          'domicilio electrónico [EMAIL], me presento y digo:\n\n'
          'I. OBJETO\n'
          'Solicito se declare la PRESCRIPCIÓN del Acta N° [N° ACTA] '
          'de fecha [FECHA INFRACCIÓN].\n\n'
          'II. FUNDAMENTO\n'
          'Han transcurrido [PLAZO APLICABLE] desde la infracción sin resolución '
          'ni acto interruptivo válido.\n'
          'Norma aplicable: [NORMA PRESCRIPCIÓN]\n\n'
          'III. PETITORIO\n'
          '1. Se declare la prescripción del Acta N° [N° ACTA].\n'
          '2. Se archive el expediente y cesen todos los bloqueos asociados.\n'
          '3. Se expida constancia de prescripción y archivo.\n\n'
          '[FECHA — FIRMA]\n\nSERÁ JUSTICIA.',
    ),
    ModeloEscrito(
      id: 'telegrama',
      titulo: 'Telegrama colacionado',
      jurisdiccion: 'Todas',
      icon: '✉️',
      normaBase: 'Correo Argentino — servicio TCL',
      camposObligatorios: [
        'ORGANISMO DESTINATARIO', 'DIRECCIÓN', 'CIUDAD',
        'NOMBRE REMITENTE', 'DNI REMITENTE',
        'N° DÍAS PLAZO', 'OBJETO DE LA INTIMACIÓN',
      ],
      nota: 'Remitir por Correo Argentino como "Telegrama Colacionado" (TCL). '
          'Conservar duplicado con número de envío y constancia de entrega.',
      plantilla: 'TELEGRAMA COLACIONADO (TCL)\n'
          'Remitir por: Correo Argentino — servicio colacionado\n\n'
          'DESTINATARIO: [ORGANISMO DESTINATARIO]\n'
          'DIRECCIÓN: [DIRECCIÓN]\n'
          'CIUDAD: [CIUDAD]\n'
          '━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
          '[NOMBRE REMITENTE], DNI [DNI REMITENTE], intima a ese organismo '
          'para que en el plazo de [N° DÍAS PLAZO] días hábiles:\n\n'
          '1. [OBJETO DE LA INTIMACIÓN]\n\n'
          'Caso contrario se iniciarán las acciones legales que correspondan, '
          'con reserva de daños y perjuicios.\n\n'
          '[FECHA — FIRMA]',
    ),
    ModeloEscrito(
      id: 'denuncia_conductor',
      titulo: 'Denuncia del conductor real',
      jurisdiccion: 'PBA',
      icon: '🔄',
      normaBase: 'Art. 35 inc. f Ley 13.927 PBA',
      camposObligatorios: [
        'N° JUZGADO', 'NOMBRE TITULAR', 'DNI TITULAR',
        'PATENTE', 'N° ACTA', 'FECHA INFRACCIÓN',
        'NOMBRE CONDUCTOR REAL', 'DNI CONDUCTOR REAL',
        'DOMICILIO CONDUCTOR REAL', 'RELACIÓN CON TITULAR',
      ],
      nota: '⚠️ Si el titular no denuncia al conductor real, '
          'es responsable de la multa (Art. 35 inc. f Ley 13.927 PBA).',
      plantilla: 'Al Sr./Sra. Juez/a Administrativo/a de Infracciones de Tránsito\n'
          'Juzgado N° [N° JUZGADO]\n\n'
          '[NOMBRE TITULAR], DNI [DNI TITULAR], titular del vehículo [PATENTE], '
          'en relación al Acta N° [N° ACTA] del [FECHA INFRACCIÓN], digo:\n\n'
          'I. OBJETO\n'
          'Que vengo a IDENTIFICAR AL CONDUCTOR REAL del vehículo al momento '
          'de la infracción, conforme Art. 35 inc. f) Ley 13.927 PBA.\n\n'
          'II. CONDUCTOR REAL\n'
          'Nombre: [NOMBRE CONDUCTOR REAL]\n'
          'DNI: [DNI CONDUCTOR REAL]\n'
          'Domicilio: [DOMICILIO CONDUCTOR REAL]\n'
          'Relación con el titular: [RELACIÓN CON TITULAR]\n\n'
          'III. PETITORIO\n'
          '1. Se tenga presente la denuncia.\n'
          '2. Se notifique a [NOMBRE CONDUCTOR REAL] en el domicilio indicado.\n'
          '3. Se exima al suscripto de responsabilidad como titular registral.\n\n'
          '[FECHA — FIRMA]\n\nSERÁ JUSTICIA.',
    ),
  ];

  EscritosBloc({required ICasosRepository casosRepository})
      : _repo = casosRepository,
        super(const EscritosInitial()) {
    on<SeleccionarModeloEvent>(_onSeleccionar);
    on<LimpiarEscritoEvent>(_onLimpiar);
  }

  void _onSeleccionar(
      SeleccionarModeloEvent event, Emitter<EscritosState> emit) {
    final modelo =
        modelos.firstWhere((m) => m.id == event.modeloId);
    emit(EscritoSeleccionado(modelo: modelo));
  }

  void _onLimpiar(LimpiarEscritoEvent event, Emitter<EscritosState> emit) {
    emit(const EscritosInitial());
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/analisis_bloc.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';
import '../../../shared/widgets/plazo_card_widget.dart';
import '../../../shared/widgets/campo_faltante_widget.dart';

// ══════════════════════════════════════════════════════════════════
// ANALISIS SCREEN
// ══════════════════════════════════════════════════════════════════

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({super.key});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Controladores de formulario
  String? _jurisdiccion;
  DateTime? _fechaNotificacion;
  String? _tipoFalta;
  String? _estadoProcesal;
  final List<String> _erroresFormales = [];
  bool? _titularEsConductor;
  bool _vaJudicial = false;
  bool _agotamientoVia = false;

  static const _jurisdicciones = [
    'CABA', 'PBA', 'Córdoba', 'Santa Fe',
    'Mendoza', 'Tucumán', 'Salta', 'Neuquén', 'nacional', 'otra',
  ];
  static const _tiposFalta = ['leve', 'grave', 'gravisima'];
  static const _estadosProc = [
    'admin', 'descargo', 'condenado',
    'apelacion', 'firme', 'apremio',
  ];
  static const _erroresOpciones = [
    'Patente errónea', 'Fecha incorrecta', 'Hora incorrecta',
    'Lugar no coincide', 'Norma mal citada', 'Falta firma del agente',
    'Datos del titular incorrectos', 'Falta identificación del agente',
    'Señalización deficiente', 'Fotomulta sin notificación válida',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚖️  Analizar multa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Nuevo análisis',
            onPressed: () => context.read<AnalisisBloc>().add(const LimpiarAnalisisEvent()),
          ),
        ],
      ),
      body: BlocConsumer<AnalisisBloc, AnalisisState>(
        listener: (ctx, state) {
          if (state is AnalisisGuardado) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(content: Text('✅ Caso guardado correctamente')),
            );
          }
          if (state is AnalisisError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.mensaje),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        },
        builder: (ctx, state) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aviso legal
              const LegalAlertWidget(
                tipo: TipoAlerta.info,
                mensaje: 'Prioridad: precisión. Si falta información, se indica con la norma exacta. No inventa datos.',
              ),
              const SizedBox(height: 4),

              // ── Zona de carga de imagen ────────────────────
              _UploadZone(
                isLoading: state is AnalisisOcrEnProceso,
                onImageSelected: (file) => ctx.read<AnalisisBloc>()
                    .add(AnalizarImagenEvent(imagen: file)),
              ),

              // ── Resultado OCR ──────────────────────────────
              if (state is AnalisisOcrCompletado)
                _OcrResultadoCard(acta: state.acta),

              const SizedBox(height: 8),

              // ── Formulario manual ──────────────────────────
              _FormularioCard(
                formKey: _formKey,
                jurisdiccion: _jurisdiccion,
                fechaNotificacion: _fechaNotificacion,
                tipoFalta: _tipoFalta,
                estadoProcesal: _estadoProcesal,
                erroresFormales: _erroresFormales,
                titularEsConductor: _titularEsConductor,
                vaJudicial: _vaJudicial,
                agotamientoVia: _agotamientoVia,
                jurisdicciones: _jurisdicciones,
                tiposFalta: _tiposFalta,
                estadosProc: _estadosProc,
                erroresOpciones: _erroresOpciones,
                onJurisdiccionChanged: (v) => setState(() => _jurisdiccion = v),
                onFechaNotificacionChanged: (v) =>
                    setState(() => _fechaNotificacion = v),
                onTipoFaltaChanged: (v) => setState(() => _tipoFalta = v),
                onEstadoProcChanged: (v) => setState(() => _estadoProcesal = v),
                onTitularChanged: (v) =>
                    setState(() => _titularEsConductor = v),
                onVaJudicialChanged: (v) => setState(() => _vaJudicial = v),
                onAgotamientoChanged: (v) =>
                    setState(() => _agotamientoVia = v),
                onErrorFormalToggled: (e) => setState(() {
                  _erroresFormales.contains(e)
                      ? _erroresFormales.remove(e)
                      : _erroresFormales.add(e);
                }),
              ),

              // ── Botón analizar ─────────────────────────────
              const SizedBox(height: 8),
              if (state is AnalisisCalculandoPlazos)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('ANALIZAR MULTA'),
                    onPressed: _jurisdiccion == null
                        ? null
                        : () => ctx.read<AnalisisBloc>().add(
                              AnalizarFormularioEvent(
                                jurisdiccion: _jurisdiccion!,
                                fechaNotificacion: _fechaNotificacion,
                                tipoFalta: _tipoFalta,
                                erroresFormales: _erroresFormales,
                                titularEsConductor: _titularEsConductor,
                                estadoProcesal: _estadoProcesal,
                                vaJudicial: _vaJudicial,
                                agotamientoVia: _agotamientoVia,
                              ),
                            ),
                  ),
                ),

              // ── Resultados ─────────────────────────────────
              if (state is AnalisisCompletado) ...[
                const SizedBox(height: 20),
                _ResultadoSection(resultado: state.resultado),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── ZONA DE UPLOAD ────────────────────────────────────────────────
class _UploadZone extends StatelessWidget {
  final bool isLoading;
  final ValueChanged<File> onImageSelected;

  const _UploadZone({required this.isLoading, required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📎  Subir multa / fotomulta',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Tomar foto'),
                    onPressed: isLoading
                        ? null
                        : () => _seleccionarImagen(
                            context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galería'),
                    onPressed: isLoading
                        ? null
                        : () => _seleccionarImagen(
                            context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text('Analizando con IA...',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'JPG · PNG — el sistema extrae los datos automáticamente con OCR + IA.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen(
      BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (picked != null) onImageSelected(File(picked.path));
  }
}

// ── RESULTADO OCR ─────────────────────────────────────────────────
class _OcrResultadoCard extends StatelessWidget {
  final dynamic acta;
  const _OcrResultadoCard({required this.acta});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.indigo.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋  Datos extraídos por IA',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.indigoLight)),
            const SizedBox(height: 10),
            _campo('N° de acta', acta.numeroActa),
            _campo('Patente', acta.patente),
            _campo('Jurisdicción', acta.jurisdiccion),
            _campo('Norma imputada', acta.normaImputada),
            const SizedBox(height: 8),
            const LegalAlertWidget(
              tipo: TipoAlerta.advertencia,
              mensaje: 'Verificar todos los datos antes de usar en escritos. El OCR puede contener errores.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3,
                    letterSpacing: 0.05)),
          ),
          Expanded(
            child: Text(
              valor ?? '⚠️ No detectado',
              style: TextStyle(
                fontSize: 13,
                color: valor != null ? AppColors.text : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FORMULARIO CARD ───────────────────────────────────────────────
class _FormularioCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? jurisdiccion;
  final DateTime? fechaNotificacion;
  final String? tipoFalta;
  final String? estadoProcesal;
  final List<String> erroresFormales;
  final bool? titularEsConductor;
  final bool vaJudicial;
  final bool agotamientoVia;
  final List<String> jurisdicciones;
  final List<String> tiposFalta;
  final List<String> estadosProc;
  final List<String> erroresOpciones;
  final ValueChanged<String?> onJurisdiccionChanged;
  final ValueChanged<DateTime?> onFechaNotificacionChanged;
  final ValueChanged<String?> onTipoFaltaChanged;
  final ValueChanged<String?> onEstadoProcChanged;
  final ValueChanged<bool?> onTitularChanged;
  final ValueChanged<bool> onVaJudicialChanged;
  final ValueChanged<bool> onAgotamientoChanged;
  final ValueChanged<String> onErrorFormalToggled;

  const _FormularioCard({
    required this.formKey,
    required this.jurisdiccion,
    required this.fechaNotificacion,
    required this.tipoFalta,
    required this.estadoProcesal,
    required this.erroresFormales,
    required this.titularEsConductor,
    required this.vaJudicial,
    required this.agotamientoVia,
    required this.jurisdicciones,
    required this.tiposFalta,
    required this.estadosProc,
    required this.erroresOpciones,
    required this.onJurisdiccionChanged,
    required this.onFechaNotificacionChanged,
    required this.onTipoFaltaChanged,
    required this.onEstadoProcChanged,
    required this.onTitularChanged,
    required this.onVaJudicialChanged,
    required this.onAgotamientoChanged,
    required this.onErrorFormalToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📋  Datos del acta',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),

              // Jurisdicción
              _label('Jurisdicción *'),
              DropdownButtonFormField<String>(
                value: jurisdiccion,
                decoration: const InputDecoration(hintText: 'Seleccionar...'),
                items: jurisdicciones
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: onJurisdiccionChanged,
              ),
              const SizedBox(height: 14),

              // Fecha notificación
              _label('Fecha de notificación fehaciente *'),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2015),
                    lastDate: DateTime.now(),
                    locale: const Locale('es', 'AR'),
                  );
                  if (picked != null) onFechaNotificacionChanged(picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(),
                  child: Text(
                    fechaNotificacion != null
                        ? '${fechaNotificacion!.day}/${fechaNotificacion!.month}/${fechaNotificacion!.year}'
                        : 'Seleccionar fecha...',
                    style: TextStyle(
                      color: fechaNotificacion != null
                          ? AppColors.text
                          : AppColors.text3,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Tipo de falta
              _label('Tipo de falta'),
              DropdownButtonFormField<String>(
                value: tipoFalta,
                decoration: const InputDecoration(hintText: 'Sin determinar'),
                items: tiposFalta
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t[0].toUpperCase() + t.substring(1))))
                    .toList(),
                onChanged: onTipoFaltaChanged,
              ),
              const SizedBox(height: 14),

              // Estado procesal
              _label('Estado procesal actual *'),
              DropdownButtonFormField<String>(
                value: estadoProcesal,
                decoration: const InputDecoration(hintText: 'Sin determinar'),
                items: {
                  'admin': 'Instancia administrativa — sin descargo',
                  'descargo': 'Descargo presentado — esperando resolución',
                  'condenado': 'Resolución condenatoria — plazo apelación',
                  'apelacion': 'En apelación judicial',
                  'firme': 'Resolución firme',
                  'apremio': 'Juicio de apremio iniciado',
                }.entries.map((e) => DropdownMenuItem(
                    value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: onEstadoProcChanged,
              ),
              const SizedBox(height: 14),

              // ¿Titular es conductor?
              _label('¿El titular es quien conducía?'),
              Wrap(spacing: 8, children: [
                _opcionChip('Sí', titularEsConductor == true,
                    () => onTitularChanged(true)),
                _opcionChip('No — otro conductor', titularEsConductor == false,
                    () => onTitularChanged(false)),
                _opcionChip('Vehículo vendido', titularEsConductor == null,
                    () => onTitularChanged(null)),
              ]),
              const SizedBox(height: 14),

              // Errores formales
              _label('Errores formales en el acta'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: erroresOpciones.map((e) {
                  final activo = erroresFormales.contains(e);
                  return FilterChip(
                    label: Text(e),
                    selected: activo,
                    onSelected: (_) => onErrorFormalToggled(e),
                    selectedColor: AppColors.warning.withOpacity(0.2),
                    checkmarkColor: AppColors.warning,
                    labelStyle: TextStyle(
                      color: activo ? AppColors.warning : AppColors.text2,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: activo ? AppColors.warning : AppColors.border,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // ¿Va a judicial?
              SwitchListTile(
                value: vaJudicial,
                onChanged: onVaJudicialChanged,
                title: const Text('¿Planificás la vía judicial?',
                    style: TextStyle(fontSize: 13, color: AppColors.text)),
                activeColor: AppColors.indigo,
                contentPadding: EdgeInsets.zero,
              ),
              if (vaJudicial)
                SwitchListTile(
                  value: agotamientoVia,
                  onChanged: onAgotamientoChanged,
                  title: const Text('¿Se agotó la vía administrativa?',
                      style: TextStyle(fontSize: 13, color: AppColors.text)),
                  subtitle: const Text(
                      'Generalmente requerido antes de acudir a la justicia.',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.text3)),
                  activeColor: AppColors.success,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.text2,
                letterSpacing: 0.07)),
      );

  Widget _opcionChip(String label, bool activo, VoidCallback onTap) =>
      ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor:
            activo ? AppColors.indigo.withOpacity(0.2) : AppColors.surface3,
        side: BorderSide(
            color: activo ? AppColors.indigo : AppColors.border),
        labelStyle: TextStyle(
            color: activo ? AppColors.indigoLight : AppColors.text2,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      );
}

// ── SECCIÓN DE RESULTADOS ─────────────────────────────────────────
class _ResultadoSection extends StatelessWidget {
  final dynamic resultado;
  const _ResultadoSection({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campos faltantes
        if (resultado.faltantes.isNotEmpty) ...[
          Text('⚠️  Información faltante',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.danger)),
          const SizedBox(height: 8),
          ...resultado.faltantes
              .map<Widget>((f) => CampoFaltanteWidget(faltante: f))
              .toList(),
          const SizedBox(height: 12),
        ],

        // Alertas
        if (resultado.alertas.isNotEmpty) ...[
          ...resultado.alertas
              .map<Widget>((a) => LegalAlertWidget(
                    tipo: a.tipo,
                    mensaje: a.mensaje,
                    norma: a.norma,
                  ))
              .toList(),
          const SizedBox(height: 12),
        ],

        // Oportunidades defensivas
        if (resultado.oportunidades.isNotEmpty) ...[
          Text('🎯  Oportunidades defensivas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.success)),
          const SizedBox(height: 8),
          ...resultado.oportunidades
              .map<Widget>((o) => Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: AppColors.success.withOpacity(0.3)),
                    ),
                    color:
                        AppColors.success.withOpacity(0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text('✅  ${o.titulo}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                  fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(o.detalle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.text2)),
                          if (o.normaAplicable != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(o.normaAplicable!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.indigoLight)),
                            ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
          const SizedBox(height: 12),
        ],

        // Plazos
        if (resultado.plazos.isNotEmpty) ...[
          Text('📅  Plazos calculados',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const LegalAlertWidget(
            tipo: TipoAlerta.advertencia,
            mensaje: 'Feriados nacionales y provinciales NO incluidos — verificar calendario antes de presentar.',
          ),
          const SizedBox(height: 8),
          ...resultado.plazos
              .map<Widget>((p) => PlazoCardWidget(plazo: p))
              .toList(),
        ],
      ],
    );
  }
}

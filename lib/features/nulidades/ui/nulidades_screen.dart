import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/nulidades_bloc.dart';
import '../../../core/services/nulidades_service.dart';
import '../../../core/services/analisis_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';

// ══════════════════════════════════════════════════════════════════
// NULIDADES SCREEN
// Muestra el resultado del análisis de nulidades formales del acta.
// Permite copiar el argumento jurídico de cada causal y
// generar el escrito de nulidad directamente.
// ══════════════════════════════════════════════════════════════════

class NulidadesScreen extends StatelessWidget {
  final String casoId;
  const NulidadesScreen({super.key, required this.casoId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NulidadesBloc, NulidadesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('⚖️  Nulidades del acta'),
            actions: [
              if (state is NulidadesAnalizado &&
                  state.resultado.tieneNulidades)
                IconButton(
                  icon: const Icon(Icons.description_outlined),
                  tooltip: 'Generar escrito de nulidad',
                  onPressed: () => context.read<NulidadesBloc>().add(
                        NulidadesGenerarEscrito(casoId: casoId),
                      ),
                ),
            ],
          ),
          body: switch (state) {
            NulidadesInicial()    => _buildInicial(context),
            NulidadesCargando()   => _buildCargando(),
            NulidadesAnalizado()  => _buildResultado(context, state.resultado),
            NulidadesError()      => _buildError(context, state.mensaje),
            _                    => _buildInicial(context),
          },
        );
      },
    );
  }

  // ── Estado inicial ────────────────────────────────────────────
  Widget _buildInicial(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gavel_outlined,
                size: 56, color: AppColors.text3),
            const SizedBox(height: 20),
            Text(
              'Análisis de nulidades',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Detecta causales de nulidad formal del acta según '
              'Art. 3 Ley 13.927 (PBA), Art. 9 Ley 1217 (CABA) '
              'y Art. 70 Ley 24.449 (nacional).',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.text3, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Analizar nulidades'),
              onPressed: () => context
                  .read<NulidadesBloc>()
                  .add(NulidadesAnalizar(casoId: casoId)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cargando ──────────────────────────────────────────────────
  Widget _buildCargando() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.indigo),
          SizedBox(height: 16),
          Text('Analizando causales de nulidad...',
              style: TextStyle(color: AppColors.text3)),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, String mensaje) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text2)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context
                  .read<NulidadesBloc>()
                  .add(NulidadesAnalizar(casoId: casoId)),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Resultado completo ────────────────────────────────────────
  Widget _buildResultado(
      BuildContext context, ResultadoNulidades resultado) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner resumen
          _BannerResumen(resultado: resultado),
          const SizedBox(height: 16),

          // Causales detectadas (absolutas/relativas)
          if (resultado.causalesDetectadas.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.warning_amber_rounded,
              label: 'Causales detectadas '
                  '(${resultado.causalesDetectadas.length})',
              color: resultado.tieneNulidadAbsoluta
                  ? AppColors.danger
                  : AppColors.warning,
            ),
            const SizedBox(height: 8),
            ...resultado.causalesDetectadas.map(
              (c) => _CausalCard(causal: c, expandida: true),
            ),
            const SizedBox(height: 16),
          ],

          // Causales potenciales
          if (resultado.causalesPotenciales.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.info_outline,
              label: 'Verificar manualmente '
                  '(${resultado.causalesPotenciales.length})',
              color: AppColors.indigo,
            ),
            const SizedBox(height: 8),
            ...resultado.causalesPotenciales.map(
              (c) => _CausalCard(causal: c, expandida: false),
            ),
            const SizedBox(height: 16),
          ],

          // Sin causales
          if (!resultado.tieneNulidades &&
              resultado.causalesPotenciales.isEmpty)
            const LegalAlertWidget(
              tipo: TipoAlerta.info,
              mensaje:
                  'No se detectaron causales de nulidad evidentes en '
                  'los datos disponibles. Esto no excluye defectos '
                  'no visibles en el acta física.',
            ),

          // Recomendación
          _RecomendacionCard(texto: resultado.recomendacion),

          // Botón generar escrito
          if (resultado.tieneNulidades ||
              resultado.causalesPotenciales.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit_document, size: 18),
                label: const Text('Generar escrito de nulidad'),
                onPressed: () => context
                    .read<NulidadesBloc>()
                    .add(NulidadesGenerarEscrito(casoId: casoId)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// WIDGETS INTERNOS
// ══════════════════════════════════════════════════════════════════

class _BannerResumen extends StatelessWidget {
  final ResultadoNulidades resultado;
  const _BannerResumen({required this.resultado});

  @override
  Widget build(BuildContext context) {
    final color = resultado.tieneNulidadAbsoluta
        ? AppColors.danger
        : resultado.tieneNulidades
            ? AppColors.warning
            : resultado.causalesPotenciales.isNotEmpty
                ? AppColors.indigo
                : AppColors.success;

    final icon = resultado.tieneNulidadAbsoluta
        ? '🚨'
        : resultado.tieneNulidades
            ? '⚠️'
            : resultado.causalesPotenciales.isNotEmpty
                ? 'ℹ️'
                : '✅';

    final titulo = resultado.tieneNulidadAbsoluta
        ? '${resultado.causalesDetectadas.length} causal(es) de nulidad ABSOLUTA'
        : resultado.tieneNulidades
            ? '${resultado.causalesDetectadas.length} causal(es) de nulidad relativa'
            : resultado.causalesPotenciales.isNotEmpty
                ? '${resultado.causalesPotenciales.length} causal(es) a verificar'
                : 'Sin causales detectadas';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Las causales deben ser valoradas por letrado matriculado.',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.text3, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.04,
          ),
        ),
      ],
    );
  }
}

class _CausalCard extends StatefulWidget {
  final CausalNulidad causal;
  final bool expandida;
  const _CausalCard({required this.causal, required this.expandida});

  @override
  State<_CausalCard> createState() => _CausalCardState();
}

class _CausalCardState extends State<_CausalCard> {
  late bool _expandida;

  @override
  void initState() {
    super.initState();
    _expandida = widget.expandida;
  }

  Color get _colorTipo => switch (widget.causal.tipo) {
        TipoNulidad.absoluta   => AppColors.danger,
        TipoNulidad.relativa   => AppColors.warning,
        TipoNulidad.subsanable => AppColors.indigo,
      };

  String get _labelTipo => switch (widget.causal.tipo) {
        TipoNulidad.absoluta   => 'ABSOLUTA',
        TipoNulidad.relativa   => 'RELATIVA',
        TipoNulidad.subsanable => 'SUBSANABLE',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _expandida = !_expandida),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _colorTipo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _labelTipo,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _colorTipo,
                        letterSpacing: 0.06,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.causal.titulo,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Icon(
                    _expandida
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: AppColors.text3,
                  ),
                ],
              ),

              // Norma siempre visible
              const SizedBox(height: 8),
              Text(
                widget.causal.norma,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.indigoLight,
                    fontWeight: FontWeight.w600),
              ),

              // Contenido expandible
              if (_expandida) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Descripción
                Text(
                  widget.causal.descripcion,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text2,
                      height: 1.5),
                ),

                // Argumento jurídico
                if (widget.causal.argumentoJuridico != null) ...[
                  const SizedBox(height: 12),
                  _ExpandableSection(
                    titulo: 'Argumento jurídico',
                    contenido: widget.causal.argumentoJuridico!,
                    icono: Icons.balance_outlined,
                    color: AppColors.indigo,
                    copiable: true,
                  ),
                ],

                // Jurisprudencia / advertencia
                if (widget.causal.jurisprudencia != null) ...[
                  const SizedBox(height: 8),
                  _ExpandableSection(
                    titulo: 'Jurisprudencia / Advertencia',
                    contenido: widget.causal.jurisprudencia!,
                    icono: Icons.warning_amber_outlined,
                    color: AppColors.warning,
                    copiable: false,
                  ),
                ],

                // Requiere acreditar perjuicio
                if (widget.causal.requiereAcreditarPerjuicio) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface3,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: AppColors.text3),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nulidad relativa: debe oponerse en primer '
                            'acto procesal y acreditar perjuicio concreto.',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.text3,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String titulo;
  final String contenido;
  final IconData icono;
  final Color color;
  final bool copiable;

  const _ExpandableSection({
    required this.titulo,
    required this.contenido,
    required this.icono,
    required this.color,
    required this.copiable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 13, color: color),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.05,
                ),
              ),
              if (copiable) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: contenido));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Argumento copiado al portapapeles'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_outlined,
                      size: 14, color: AppColors.text3),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            contenido,
            style: const TextStyle(
                fontSize: 12, color: AppColors.text2, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _RecomendacionCard extends StatelessWidget {
  final String texto;
  const _RecomendacionCard({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECOMENDACIÓN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text3,
                    letterSpacing: 0.08,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  texto,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.text2,
                      height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

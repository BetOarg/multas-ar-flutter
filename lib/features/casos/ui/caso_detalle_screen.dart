import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/casos_bloc.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';
import '../../../shared/widgets/plazo_card_widget.dart';

class CasoDetalleScreen extends StatefulWidget {
  final String casoId;
  const CasoDetalleScreen({super.key, required this.casoId});
  @override
  State<CasoDetalleScreen> createState() => _CasoDetalleScreenState();
}

class _CasoDetalleScreenState extends State<CasoDetalleScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CasosBloc>().add(CasoCargar(casoId: widget.casoId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CasosBloc, CasosState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(state is CasoDetalleCargado
                ? (state.caso.numeroActa ?? 'Caso sin número')
                : 'Detalle del caso'),
            actions: [
              if (state is CasoDetalleCargado)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'nulidades') {
                      context.push('/casos/${widget.casoId}/nulidades');
                    } else if (v == 'escritos') {
                      context.push('/escritos?casoId=${widget.casoId}');
                    } else if (v == 'eliminar') {
                      _confirmarEliminar(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'nulidades',
                        child: Text('Analizar nulidades')),
                    const PopupMenuItem(value: 'escritos',
                        child: Text('Generar escrito')),
                    const PopupMenuItem(value: 'eliminar',
                        child: Text('Eliminar caso',
                            style: TextStyle(color: AppColors.danger))),
                  ],
                ),
            ],
          ),
          body: switch (state) {
            CasosCargando()      => const Center(
                child: CircularProgressIndicator(color: AppColors.indigo)),
            CasoDetalleCargado() => _buildDetalle(context, state),
            CasosError()         => Center(child: Text(state.mensaje,
                style: const TextStyle(color: AppColors.danger))),
            _                    => const Center(
                child: CircularProgressIndicator(color: AppColors.indigo)),
          },
        );
      },
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar caso'),
        content: const Text('¿Eliminar este caso? No puede deshacerse.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CasosBloc>().add(CasoEliminar(casoId: widget.casoId));
              context.pop();
            },
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalle(BuildContext context, CasoDetalleCargado state) {
    final caso   = state.caso;
    final plazos = state.plazos;
    final alertas = state.alertas;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Acciones rápidas
          Row(children: [
            Expanded(child: _accionBtn(context, Icons.gavel_outlined,
                'Nulidades', () => context.push('/casos/${widget.casoId}/nulidades'))),
            const SizedBox(width: 8),
            Expanded(child: _accionBtn(context, Icons.description_outlined,
                'Escritos', () => context.push('/escritos?casoId=${widget.casoId}'))),
            const SizedBox(width: 8),
            Expanded(child: _accionBtn(context, Icons.share_outlined,
                'Compartir', () {})),
          ]),
          const SizedBox(height: 16),

          // Alertas
          ...alertas.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LegalAlertWidget(tipo: a.tipo, mensaje: a.mensaje),
          )),

          // Datos del acta
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📄  Datos del acta', style: Theme.of(context).textTheme.titleMedium),
              const Divider(height: 16),
              _row('N° acta',     caso.numeroActa      ?? '—'),
              _row('Patente',     caso.patente         ?? '—'),
              _row('Jurisdicción',caso.jurisdiccion    ?? '—'),
              _row('Norma',       caso.normaInfringida ?? '—'),
              _row('Fecha',       _fmt(caso.fechaInfraccion)),
              _row('Notificación',_fmt(caso.fechaNotificacion)),
              _row('Lugar',       caso.lugarInfraccion ?? '—'),
              _row('Estado',      caso.estado          ?? '—'),
            ]),
          )),

          // Plazos
          if (plazos.isNotEmpty) ...[
            const Text('⏱️  Plazos', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.text3)),
            const SizedBox(height: 8),
            ...plazos.map((p) => PlazoCardWidget(plazo: p)),
            const SizedBox(height: 8),
          ],

          // Botón nulidades
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.gavel_outlined, size: 16),
              label: const Text('Analizar nulidades formales'),
              onPressed: () => context.push('/casos/${widget.casoId}/nulidades'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.indigo,
                  side: const BorderSide(color: AppColors.indigo)),
            )),
        ],
      ),
    );
  }

  Widget _accionBtn(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface3,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: AppColors.indigoLight),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(
              fontSize: 11, color: AppColors.text2, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text3))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 12, color: AppColors.text2, height: 1.4))),
    ]),
  );

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2,'0')}/'
        '${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

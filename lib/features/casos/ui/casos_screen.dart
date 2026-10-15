import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/casos_bloc.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/router/app_router.dart';

class CasosScreen extends StatelessWidget {
  const CasosScreen({super.key});

  static const _estadoLabel = {
    'admin': ('Instancia admin.', AppColors.indigo),
    'descargo': ('Descargo presentado', AppColors.warning),
    'condenado': ('Condenado', AppColors.danger),
    'apelacion': ('En apelación', AppColors.warning),
    'firme': ('Firme', AppColors.danger),
    'apremio': ('Apremio', Color(0xFFE53E3E)),
    'prescripto': ('Prescripto', AppColors.success),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📁  Mis casos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            tooltip: 'Filtrar',
            onPressed: () => _mostrarFiltros(context),
          ),
        ],
      ),
      body: BlocBuilder<CasosBloc, CasosState>(
        builder: (ctx, state) {
          if (state is CasosCargando || state is CasosInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CasosError) {
            return Center(
              child: Text(state.mensaje,
                  style: const TextStyle(color: AppColors.danger)),
            );
          }
          if (state is CasosVacio) {
            return _EmptyState();
          }
          if (state is CasosCargados) {
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: state.casos.length,
              itemBuilder: (_, i) {
                final caso = state.casos[i];
                final estadoCfg = _estadoLabel[caso.estadoProcesal] ??
                    ('Desconocido', AppColors.text3);
                return _CasoCard(
                  caso: caso,
                  estadoLabel: estadoCfg.$1,
                  estadoColor: estadoCfg.$2,
                  onTap: () =>
                      ctx.go('/casos/${caso.id}'),
                  onArchivar: () => ctx
                      .read<CasosBloc>()
                      .add(ArchivarCasoEvent(casoId: caso.id)),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRouter.analisis),
        backgroundColor: AppColors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo caso',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _mostrarFiltros(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrar por estado',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _estadoLabel.entries
                  .map((e) => FilterChip(
                        label: Text(e.value.$1),
                        selected: false,
                        onSelected: (_) => Navigator.pop(context),
                        selectedColor: e.value.$2.withOpacity(0.2),
                        labelStyle: TextStyle(
                            color: e.value.$2, fontSize: 12),
                        side: BorderSide(
                            color: e.value.$2.withOpacity(0.4)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── CARD DE CASO ─────────────────────────────────────────────────
class _CasoCard extends StatelessWidget {
  final dynamic caso;
  final String estadoLabel;
  final Color estadoColor;
  final VoidCallback onTap;
  final VoidCallback onArchivar;

  const _CasoCard({
    required this.caso,
    required this.estadoLabel,
    required this.estadoColor,
    required this.onTap,
    required this.onArchivar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      caso.numeroActa != null
                          ? 'Acta N° ${caso.numeroActa}'
                          : 'Sin número de acta',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  // Badge estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: estadoColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      estadoLabel,
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Menú
                  PopupMenuButton<String>(
                    color: AppColors.surface2,
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: AppColors.text3),
                    onSelected: (v) {
                      if (v == 'archivar') onArchivar();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'archivar',
                        child: Row(
                          children: [
                            Icon(Icons.archive_outlined,
                                size: 16, color: AppColors.text2),
                            SizedBox(width: 8),
                            Text('Archivar',
                                style: TextStyle(
                                    color: AppColors.text2,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Datos del caso
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (caso.jurisdiccion != null)
                    _dato(Icons.location_on_outlined, caso.jurisdiccion),
                  if (caso.patente != null)
                    _dato(Icons.directions_car_outlined, caso.patente),
                  if (caso.tipoFalta != null)
                    _dato(Icons.gavel_outlined,
                        'Falta ${caso.tipoFalta}'),
                ],
              ),
              const SizedBox(height: 6),
              // Fecha notificación
              if (caso.fechaNotificacion != null)
                _dato(
                  Icons.calendar_today_outlined,
                  'Notif: ${_fmt(caso.fechaNotificacion!)}',
                  color: AppColors.text3,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dato(IconData icon, String? text,
      {Color color = AppColors.text2}) {
    if (text == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

// ── ESTADO VACÍO ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📂', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Sin casos cargados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Analizá una multa para crear tu primer caso.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Analizar multa'),
            onPressed: () => context.go(AppRouter.analisis),
          ),
        ],
      ),
    );
  }
}

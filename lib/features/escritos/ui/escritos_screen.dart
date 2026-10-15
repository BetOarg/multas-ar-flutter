import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../bloc/escritos_bloc.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';
import '../../../core/services/analisis_service.dart';

class EscritosScreen extends StatelessWidget {
  const EscritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📝  Escritos')),
      body: BlocBuilder<EscritosBloc, EscritosState>(
        builder: (ctx, state) => Column(
          children: [
            // ── Grid de modelos ─────────────────────────────
            _ModelosGrid(modeloActivoId:
                state is EscritoSeleccionado ? state.modelo.id : null),

            // ── Editor del modelo seleccionado ──────────────
            if (state is EscritoSeleccionado)
              Expanded(child: _EscritoEditor(modelo: state.modelo))
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📄',
                          style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'Seleccioná un modelo para comenzar',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── GRID DE MODELOS ───────────────────────────────────────────────
class _ModelosGrid extends StatelessWidget {
  final String? modeloActivoId;
  const _ModelosGrid({this.modeloActivoId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: EscritosBloc.modelos.length,
        itemBuilder: (ctx, i) {
          final m = EscritosBloc.modelos[i];
          final activo = m.id == modeloActivoId;
          return GestureDetector(
            onTap: () => ctx
                .read<EscritosBloc>()
                .add(SeleccionarModeloEvent(modeloId: m.id)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 110,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: activo
                    ? AppColors.indigo.withOpacity(0.2)
                    : AppColors.surface3,
                border: Border.all(
                  color: activo
                      ? AppColors.indigo
                      : AppColors.border,
                  width: activo ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.icon,
                      style: const TextStyle(fontSize: 20)),
                  Text(
                    m.titulo,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: activo
                          ? AppColors.indigoLight
                          : AppColors.text,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    m.jurisdiccion,
                    style: TextStyle(
                      fontSize: 10,
                      color: activo
                          ? AppColors.indigoLight.withOpacity(0.7)
                          : AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── EDITOR DEL ESCRITO ────────────────────────────────────────────
class _EscritoEditor extends StatelessWidget {
  final ModeloEscrito modelo;
  const _EscritoEditor({required this.modelo});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              Text('${modelo.icon}  ${modelo.titulo}',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              // Acciones
              _accionIcon(
                context,
                icon: Icons.copy_outlined,
                tooltip: 'Copiar',
                onTap: () => _copiar(context, modelo.plantilla),
              ),
              const SizedBox(width: 4),
              _accionIcon(
                context,
                icon: Icons.share_outlined,
                tooltip: 'Compartir',
                onTap: () => Share.share(
                  modelo.plantilla,
                  subject: '${modelo.titulo} — ${modelo.jurisdiccion}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Norma base
          Text(
            modelo.normaBase,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.indigoLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Nota de advertencia
          LegalAlertWidget(
            tipo: TipoAlerta.advertencia,
            mensaje: modelo.nota,
          ),

          // Campos obligatorios
          _CamposObligatorios(campos: modelo.camposObligatorios),
          const SizedBox(height: 12),

          // Texto del escrito
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              modelo.plantilla,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: AppColors.text,
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Advertencia final
          const LegalAlertWidget(
            tipo: TipoAlerta.info,
            mensaje: 'Completar todos los campos [EN MAYÚSCULAS] antes de presentar. '
                'Verificar vigencia normativa al momento de uso. '
                'No citar jurisprudencia sin fuente verificada.',
          ),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar texto'),
                  onPressed: () => _copiar(context, modelo.plantilla),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Compartir'),
                  onPressed: () => Share.share(
                    modelo.plantilla,
                    subject: modelo.titulo,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copiar(BuildContext context, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _accionIcon(BuildContext context,
      {required IconData icon,
      required String tooltip,
      required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(icon, size: 18, color: AppColors.text2),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }
}

// ── CAMPOS OBLIGATORIOS ───────────────────────────────────────────
class _CamposObligatorios extends StatelessWidget {
  final List<String> campos;
  const _CamposObligatorios({required this.campos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CAMPOS OBLIGATORIOS — completar antes de presentar:',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.text3,
            letterSpacing: 0.06,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: campos
              .map((c) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.warning.withOpacity(0.35)),
                    ),
                    child: Text(
                      c,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFBD38D),
                        letterSpacing: 0.04,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

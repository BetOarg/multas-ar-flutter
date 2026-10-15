import 'package:flutter/material.dart';
import '../../core/services/plazos_service.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
// PLAZO CARD WIDGET — muestra un plazo con semáforo de urgencia
// ══════════════════════════════════════════════════════════════════

class PlazoCardWidget extends StatelessWidget {
  final PlazoCalculado plazo;

  const PlazoCardWidget({super.key, required this.plazo});

  @override
  Widget build(BuildContext context) {
    final cfg = _config();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cfg.bg,
        border: Border.all(color: cfg.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de estado
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: cfg.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plazo.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatearFecha(plazo.fechaVencimiento),
                  style: TextStyle(
                    fontSize: 12,
                    color: cfg.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plazo.norma,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.indigoLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _tipoCómputoLabel(plazo.tipoCómputo),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.text3,
                  ),
                ),
              ],
            ),
          ),

          // Badge de días restantes
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cfg.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cfg.accent.withOpacity(0.4)),
                ),
                child: Text(
                  cfg.label,
                  style: TextStyle(
                    color: cfg.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
              if (plazo.esAltaCriticidad)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '● CRÍTICO',
                    style: TextStyle(
                      color: cfg.accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _PlazoConfig _config() {
    switch (plazo.estado) {
      case EstadoPlazo.vencido:
        return _PlazoConfig(
          bg: AppColors.danger.withOpacity(0.07),
          border: AppColors.danger.withOpacity(0.3),
          accent: AppColors.danger,
          label: 'VENCIDO hace ${plazo.diasRestantes.abs()}d',
        );
      case EstadoPlazo.urgente:
        return _PlazoConfig(
          bg: AppColors.danger.withOpacity(0.05),
          border: AppColors.danger.withOpacity(0.25),
          accent: AppColors.danger,
          label: '⚡ ${plazo.diasRestantes}d',
        );
      case EstadoPlazo.proximo:
        return _PlazoConfig(
          bg: AppColors.warning.withOpacity(0.07),
          border: AppColors.warning.withOpacity(0.3),
          accent: AppColors.warning,
          label: '${plazo.diasRestantes}d',
        );
      case EstadoPlazo.vigente:
        return _PlazoConfig(
          bg: AppColors.success.withOpacity(0.05),
          border: AppColors.success.withOpacity(0.2),
          accent: AppColors.success,
          label: '${plazo.diasRestantes}d',
        );
    }
  }

  String _formatearFecha(DateTime d) {
    final dias = [
      'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo'
    ];
    final meses = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${dias[d.weekday - 1]} ${d.day} de ${meses[d.month]} de ${d.year}';
  }

  String _tipoCómputoLabel(TipoCómputo tipo) {
    switch (tipo) {
      case TipoCómputo.habilesAdministrativos:
        return 'Días hábiles administrativos';
      case TipoCómputo.habilesJudiciales:
        return 'Días hábiles judiciales';
      case TipoCómputo.corridos:
        return 'Días corridos';
    }
  }
}

class _PlazoConfig {
  final Color bg;
  final Color border;
  final Color accent;
  final String label;
  const _PlazoConfig({
    required this.bg,
    required this.border,
    required this.accent,
    required this.label,
  });
}

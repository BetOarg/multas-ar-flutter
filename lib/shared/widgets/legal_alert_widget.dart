import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../core/services/analisis_service.dart';

// ══════════════════════════════════════════════════════════════════
// LEGAL ALERT WIDGET — alerta con tipo, mensaje y norma opcional
// ══════════════════════════════════════════════════════════════════

class LegalAlertWidget extends StatelessWidget {
  final TipoAlerta tipo;
  final String mensaje;
  final String? norma;

  const LegalAlertWidget({
    super.key,
    required this.tipo,
    required this.mensaje,
    this.norma,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cfg.bg,
        border: Border.all(color: cfg.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cfg.icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mensaje,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.text,
                    height: 1.5,
                  ),
                ),
                if (norma != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    norma!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.indigoLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _AlertConfig _config() {
    switch (tipo) {
      case TipoAlerta.peligro:
        return _AlertConfig(
          bg: AppColors.danger.withOpacity(0.1),
          border: AppColors.danger.withOpacity(0.3),
          icon: '🚨',
        );
      case TipoAlerta.advertencia:
        return _AlertConfig(
          bg: AppColors.warning.withOpacity(0.1),
          border: AppColors.warning.withOpacity(0.3),
          icon: '⚠️',
        );
      case TipoAlerta.info:
        return _AlertConfig(
          bg: AppColors.indigo.withOpacity(0.1),
          border: AppColors.indigo.withOpacity(0.3),
          icon: 'ℹ️',
        );
    }
  }
}

class _AlertConfig {
  final Color bg;
  final Color border;
  final String icon;
  const _AlertConfig({required this.bg, required this.border, required this.icon});
}

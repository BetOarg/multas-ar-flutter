import 'package:flutter/material.dart';
import '../../core/services/analisis_service.dart';
import '../theme/app_theme.dart';

class CampoFaltanteWidget extends StatelessWidget {
  final CampoFaltante faltante;
  const CampoFaltanteWidget({super.key, required this.faltante});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️ ', style: TextStyle(fontSize: 13)),
              Text(
                'FALTA: ${faltante.campo}',
                style: const TextStyle(
                  color: Color(0xFFFC8181),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (faltante.esCritico)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CRÍTICO',
                    style: TextStyle(
                      color: Color(0xFFFC8181),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.08,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            faltante.detalle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.text2,
              height: 1.5,
            ),
          ),
          if (faltante.normaQueLoExige != null) ...[
            const SizedBox(height: 4),
            Text(
              faltante.normaQueLoExige!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.indigoLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

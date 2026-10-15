import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';
import '../../../core/services/analisis_service.dart';

class NormativaScreen extends StatefulWidget {
  const NormativaScreen({super.key});
  @override
  State<NormativaScreen> createState() => _NormativaScreenState();
}

class _NormativaScreenState extends State<NormativaScreen> {
  String _jurActiva = 'CABA';

  static const _jurisdicciones = [
    'CABA', 'PBA', 'Córdoba', 'Santa Fe',
    'Mendoza', 'Tucumán', 'Salta', 'Neuquén', 'Nacional',
  ];

  static const _normativa = {
    'CABA': {
      'Nombre completo': 'Ciudad Autónoma de Buenos Aires',
      'Ley procesal': 'Ley 1217 (Texto Consolidado Ley 6.764/2024)',
      'Código de faltas': 'Ley 451 — Régimen de Faltas de la CABA',
      'Prescripción (texto legal)': '5 años — Ley 451 CABA (sin distinción leve/grave)',
      'Prescripción (fallo Andrade 2023)': '⚠️ 2 años — Juzgado PCyF N°15, 30/05/2023 — verificar alzada',
      'Descargo': '5 días hábiles administrativos desde notificación (Art. 8 Ley 1217)',
      'Notificación por email': '✅ Fehaciente desde reforma Ley 1217 (t.c. Ley 6.764/2024)',
      'Órgano administrativo': 'Controlador Administrativo de Faltas / Junta de Faltas',
      'Órgano judicial': 'Justicia Penal, Contravencional y de Faltas CABA',
      'Vía ejecutiva': 'CAyT CABA (Ley 189 CCAyT) — certificado de deuda',
      'Contacto': 'DGAI – Av. Regimiento de Patricios 65 | WhatsApp (54-11) 50500147 | L-V 8-19h',
    },
    'PBA': {
      'Nombre completo': 'Provincia de Buenos Aires',
      'Ley procesal': 'Ley 13.927 y modificatoria Ley 15.002',
      'Prescripción leve': '2 años (Art. 89 Ley 24.449 — supletorio)',
      'Prescripción grave': '5 años (Art. 89 Ley 24.449 — supletorio)',
      'Descargo': '45 días hábiles administrativos desde notificación (Art. 35 Ley 13.927)',
      'Presentación ante juzgado': '30 días corridos desde labrado del acta (Art. 35)',
      'Caducidad habilitación': '90 días corridos sin presentarse (Art. 35)',
      'Apelación judicial': '5 días hábiles — FUNDADA en mismo escrito (Arts. 40-41)',
      'Notif. fotomultas': '60 días hábiles (Art. 28) — ⚠️ ver Ley 15.002 + fallo San Martín 2018',
      'Caducidad RUIT': '10 años desde el hecho (Art. 6 Ley 13.927)',
      'Órgano admin.': 'JAITP — Juzgado Administrativo de Infracciones de Tránsito Provincial',
      'Órgano rutas': 'JAITP — rutas, autopistas y semiautopistas (Art. 32)',
      'Vía ejecutiva': 'Juicio de apremio (embargo, inhibición, secuestro)',
      'Distribución multa': '50% Municipio / 50% Provincia (Art. 42)',
      'Contacto': 'infraccionesba.gba.gov.ar | (0221) 427-0034 int. 2304/2307',
      '🚨 PLAN DE PAGOS': 'Adhesión = reconocimiento irrevocable + renuncia a recursos + interrupción prescripción (Art. 35)',
    },
    'Córdoba': {
      'Nombre completo': 'Provincia de Córdoba',
      'Ley procesal': 'Ley 11.096/2025 (reemplaza Ley 8560)',
      'Prescripción': '2/5 años (supletorio Ley 24.449)',
      'Descargo': '10 días hábiles administrativos (verificar ordenanza municipal)',
      'Órgano admin.': 'Juzgado de Faltas Municipal / Centro de Atención al Infractor',
      '⚠️ Advertencia': 'Cada municipio puede tener ordenanza específica. Verificar antes de actuar.',
    },
    'Santa Fe': {
      'Nombre completo': 'Provincia de Santa Fe',
      'Ley procesal': 'Ley 13.133 + Código Fiscal SF (Arts. 115-118)',
      'Prescripción leve': '2 años (supletorio Ley 24.449)',
      'Prescripción grave': '5 años (supletorio Ley 24.449)',
      'Suspensión prescripción': '180 días desde resolución condenatoria (Art. 116 CF SF)',
      'Órgano admin.': 'Tribunal de Faltas específico de Santa Fe',
      '⚠️ Advertencia': 'Verificar ordenanza municipal. Sistema con tribunales de faltas específicos.',
    },
    'Mendoza': {
      'Nombre completo': 'Provincia de Mendoza',
      'Ley procesal': 'Ley Provincial N° 9024',
      'Prescripción leve': '2 años (Art. 94 Ley 9024)',
      'Prescripción grave': '3 años (Art. 94 Ley 9024)',
      'Prescripción gravísima': '4 años (Art. 94 Ley 9024)',
      'Descargo': '10 días hábiles administrativos',
      'Esquema': 'Tripartito leve/grave/gravísima — el más detallado del país',
    },
    'Tucumán': {
      'Nombre completo': 'Provincia de Tucumán',
      'Ley procesal': 'Ley Provincial N° 7557 y modificatorias',
      'Prescripción': '2/5 años (verificar normativa actualizada)',
      'Órgano admin.': 'Dirección Provincial de Seguridad Vial / Juzgado de Faltas Municipal',
      '⚠️ Advertencia': 'Verificar normativa local vigente antes de actuar.',
    },
    'Salta': {
      'Nombre completo': 'Provincia de Salta',
      'Ley procesal': 'Ley 7848 (adhesión Ley 24.449) y modificatorias',
      'Prescripción leve': '2 años (Art. 89 Ley 24.449)',
      'Prescripción grave': '5 años (Art. 89 Ley 24.449)',
      'Órgano admin.': 'Dirección Provincial de Tránsito / Juzgado de Faltas Municipal',
      '⚠️ Advertencia': 'Verificar ordenanzas municipales, especialmente Salta Capital y Tartagal.',
    },
    'Neuquén': {
      'Nombre completo': 'Neuquén — ciudad y provincia',
      'Ley procesal': 'Ley Provincial N° 2038 y Ordenanza Municipal',
      'Prescripción ciudad': '3 años — sin distinción leve/grave (regulación local)',
      'Prescripción provincia': '2/5 años según gravedad (Ley 24.449 supletoria)',
      'Órgano admin.': 'Tribunal de Faltas Municipal / Dirección Provincial Vialidad',
      '⚠️ Diferencia ciudad/provincia': 'La ciudad de Neuquén aplica 3 años para todas las infracciones.',
    },
    'Nacional': {
      'Nombre completo': 'Régimen Nacional / Rutas Nacionales (ANSV)',
      'Ley principal': 'Ley Nacional de Tránsito N° 24.449',
      'Reglamentación': 'Decreto 779/95 y Decreto 196/2025',
      'ANSV': 'Ley 26.363 — Agencia Nacional de Seguridad Vial',
      'Prescripción leve': '2 años desde la infracción (Art. 89 Ley 24.449)',
      'Prescripción grave': '5 años desde la infracción (Art. 89 Ley 24.449)',
      'Interrupción': 'Nueva infracción grave o secuela de juicio (Art. 89)',
      'SINAI': 'Sistema Nacional de Infracciones — ver argentina.gob.ar/seguridadvial',
    },
  };

  static const _advertencias = [
    (TipoAlerta.peligro, 'La prescripción NO es automática: debe ser invocada y reconocida formalmente.'),
    (TipoAlerta.peligro, 'Cualquier notificación fehaciente reinicia el plazo de prescripción desde cero.'),
    (TipoAlerta.peligro, 'La adhesión a plan de pagos implica reconocimiento irrevocable de deuda y renuncia a recursos (Art. 35 Ley 13.927 PBA).'),
    (TipoAlerta.advertencia, 'El pago voluntario implica reconocimiento de la infracción y pérdida del derecho al descargo.'),
    (TipoAlerta.advertencia, 'Los feriados nacionales y provinciales NO se calculan automáticamente. Verificar calendario.'),
    (TipoAlerta.info, 'Los antecedentes en el RUIT caducan a los 10 años desde el hecho (Art. 6 Ley 13.927 PBA).'),
    (TipoAlerta.info, 'En CABA: apelación ante Junta disponible cuando la multa es ≥ 6.000 Unidades Fijas (Ley 1217).'),
  ];

  @override
  Widget build(BuildContext context) {
    final normas = _normativa[_jurActiva] ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('📚  Normativa')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selector de jurisdicción ─────────────────────
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _jurisdicciones.length,
                itemBuilder: (_, i) {
                  final j = _jurisdicciones[i];
                  final activo = j == _jurActiva;
                  return GestureDetector(
                    onTap: () => setState(() => _jurActiva = j),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: activo
                            ? AppColors.indigo.withOpacity(0.2)
                            : AppColors.surface3,
                        border: Border.all(
                          color: activo
                              ? AppColors.indigo
                              : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        j,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: activo
                              ? AppColors.indigoLight
                              : AppColors.text2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Tabla de normativa ───────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      normas['Nombre completo'] ?? _jurActiva,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 20),
                    ...normas.entries
                        .where((e) => e.key != 'Nombre completo')
                        .map((e) => _FilaNorma(
                              clave: e.key,
                              valor: e.value,
                            )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Advertencias generales ───────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚨  Advertencias generales',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ..._advertencias.map((a) => LegalAlertWidget(
                          tipo: a.$1,
                          mensaje: a.$2,
                        )),
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

class _FilaNorma extends StatelessWidget {
  final String clave;
  final String valor;
  const _FilaNorma({required this.clave, required this.valor});

  @override
  Widget build(BuildContext context) {
    final esCritico = clave.startsWith('🚨');
    final esAdvertencia = clave.startsWith('⚠️');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              clave,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: esCritico
                    ? AppColors.danger
                    : esAdvertencia
                        ? AppColors.warning
                        : AppColors.text3,
                letterSpacing: 0.04,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 12.5,
                color: esCritico
                    ? const Color(0xFFFC8181)
                    : esAdvertencia
                        ? const Color(0xFFFBD38D)
                        : AppColors.text,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

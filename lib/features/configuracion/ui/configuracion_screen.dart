import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';
import '../../../core/services/analisis_service.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});
  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final _storage = const FlutterSecureStorage();

  final _nombreCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  String? _perfilSeleccionado;
  String? _jurPrincipal;
  bool _guardando = false;
  bool _guardado = false;

  static const _perfiles = [
    ('abogado', '⚖️', 'Abogado/a matriculado/a'),
    ('estudio', '🏛️', 'Estudio jurídico'),
    ('particular', '🚗', 'Particular / infractor'),
    ('empresa', '🚛', 'Empresa / flota vehicular'),
  ];

  static const _jurisdicciones = [
    'CABA', 'PBA', 'Córdoba', 'Santa Fe',
    'Mendoza', 'Tucumán', 'Salta', 'Neuquén', 'Nacional', 'Otra',
  ];

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    final nombre = await _storage.read(key: 'cfg_nombre');
    final matricula = await _storage.read(key: 'cfg_matricula');
    final perfil = await _storage.read(key: 'cfg_perfil');
    final jur = await _storage.read(key: 'cfg_jur');
    setState(() {
      _nombreCtrl.text = nombre ?? '';
      _matriculaCtrl.text = matricula ?? '';
      _perfilSeleccionado = perfil;
      _jurPrincipal = jur;
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    await _storage.write(key: 'cfg_nombre', value: _nombreCtrl.text);
    await _storage.write(key: 'cfg_matricula', value: _matriculaCtrl.text);
    if (_perfilSeleccionado != null) {
      await _storage.write(key: 'cfg_perfil', value: _perfilSeleccionado!);
    }
    if (_jurPrincipal != null) {
      await _storage.write(key: 'cfg_jur', value: _jurPrincipal!);
    }
    setState(() { _guardando = false; _guardado = true; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _guardado = false);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _matriculaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️  Configuración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Perfil ───────────────────────────────────────
            _SectionCard(
              titulo: '👤  Perfil de uso',
              child: Column(
                children: _perfiles.map((p) {
                  final activo = _perfilSeleccionado == p.$1;
                  return _OpcionTile(
                    icon: p.$2,
                    label: p.$3,
                    activo: activo,
                    onTap: () => setState(() => _perfilSeleccionado = p.$1),
                  );
                }).toList(),
              ),
            ),

            // ── Jurisdicción principal ───────────────────────
            _SectionCard(
              titulo: '📍  Jurisdicción principal',
              child: DropdownButtonFormField<String>(
                value: _jurPrincipal,
                decoration: const InputDecoration(
                  hintText: 'Seleccionar jurisdicción...',
                ),
                items: _jurisdicciones
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: (v) => setState(() => _jurPrincipal = v),
              ),
            ),

            // ── Datos profesionales ──────────────────────────
            if (_perfilSeleccionado == 'abogado' ||
                _perfilSeleccionado == 'estudio')
              _SectionCard(
                titulo: '⚖️  Datos profesionales',
                child: Column(
                  children: [
                    _label('Nombre / Estudio'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Dr./Dra. Nombre Apellido · Estudio Jurídico...',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label('Matrícula profesional'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _matriculaCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Tomo X, Folio Y — Colegio de Abogados de...',
                      ),
                    ),
                  ],
                ),
              ),

            // ── Sobre el sistema ─────────────────────────────
            _SectionCard(
              titulo: '📋  Sobre el sistema',
              child: Column(
                children: [
                  _InfoTile(
                      icon: Icons.balance_outlined,
                      label: 'Versión',
                      valor: 'MULTAS ARGENTINA PRO v1.0.0'),
                  _InfoTile(
                      icon: Icons.gavel_outlined,
                      label: 'Base normativa',
                      valor: 'Ley 24.449 · Ley 1217 CABA · Ley 13.927 PBA · Ley 9024 Mendoza'),
                  _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Feriados',
                      valor: 'Nacionales 2026 precargados — verificar provinciales'),
                  _InfoTile(
                      icon: Icons.storage_outlined,
                      label: 'Almacenamiento',
                      valor: 'Local — SQLite vía Drift. Sin sincronización remota (v1.0)'),
                  _InfoTile(
                      icon: Icons.psychology_outlined,
                      label: 'IA',
                      valor: 'Anthropic Claude Sonnet — análisis de imagen (requiere conexión)'),
                ],
              ),
            ),

            // ── Aviso legal ──────────────────────────────────
            const LegalAlertWidget(
              tipo: TipoAlerta.advertencia,
              mensaje: 'MULTAS ARGENTINA PRO es una herramienta informativa. '
                  'No constituye asesoramiento jurídico profesional ni reemplaza '
                  'la intervención de un abogado/a matriculado/a (Ley 23.187).',
            ),

            // ── Botón guardar ────────────────────────────────
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _guardando
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(
                        _guardado ? Icons.check : Icons.save_outlined,
                        size: 18),
                label: Text(_guardado
                    ? '¡Guardado!'
                    : _guardando
                        ? 'Guardando...'
                        : 'Guardar configuración'),
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _guardado ? AppColors.success : AppColors.indigo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.text3,
          letterSpacing: 0.06,
        ),
      );
}

// ── WIDGETS INTERNOS ──────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _SectionCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _OpcionTile extends StatelessWidget {
  final String icon;
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _OpcionTile({
    required this.icon,
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: activo
              ? AppColors.indigo.withOpacity(0.15)
              : AppColors.surface3,
          border: Border.all(
            color: activo ? AppColors.indigo : AppColors.border,
            width: activo ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activo ? AppColors.indigoLight : AppColors.text,
                ),
              ),
            ),
            if (activo)
              const Icon(Icons.check_circle,
                  size: 18, color: AppColors.indigo),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.text3),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text3)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.text2, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

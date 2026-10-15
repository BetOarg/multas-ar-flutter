import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/legal_alert_widget.dart';
import '../../../core/services/analisis_service.dart';

// ══════════════════════════════════════════════════════════════════
// AUTH SCREEN — Fase 5
// Login con email/contraseña y Google Sign-In.
// Solo se muestra si el usuario no está autenticado.
// La app funciona completamente sin cuenta (modo local).
// ══════════════════════════════════════════════════════════════════

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _verPass       = false;
  bool _modoRegistro  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          _modoRegistro
              ? AuthRegistrarEmail(
                  email: _emailCtrl.text.trim(),
                  password: _passCtrl.text)
              : AuthIniciarEmail(
                  email: _emailCtrl.text.trim(),
                  password: _passCtrl.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensaje),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        final cargando = state is AuthCargando;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo + título ──────────────────────────────
                  const SizedBox(height: 20),
                  const Text('⚖️',
                      style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Multas\nArgentina Pro',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sincronizá tus casos entre dispositivos.',
                    style: TextStyle(
                        color: AppColors.text3, fontSize: 13),
                  ),
                  const SizedBox(height: 36),

                  // ── Modo local sin cuenta ──────────────────────
                  const LegalAlertWidget(
                    tipo: TipoAlerta.info,
                    mensaje:
                        'Podés usar la app sin cuenta. '
                        'Los datos quedan solo en este dispositivo.',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: cargando
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthUsarSinCuenta()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text2,
                        side: const BorderSide(
                            color: AppColors.border),
                      ),
                      child: const Text('Continuar sin cuenta'),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Divisor ────────────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: Text(
                        _modoRegistro
                            ? 'Crear cuenta'
                            : 'Iniciar sesión',
                        style: const TextStyle(
                            color: AppColors.text3,
                            fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 20),

                  // ── Formulario email ───────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined,
                                size: 18),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresá tu email';
                            }
                            if (!v.contains('@')) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: !_verPass,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(
                                Icons.lock_outline, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verPass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                                color: AppColors.text3,
                              ),
                              onPressed: () =>
                                  setState(() => _verPass = !_verPass),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                cargando ? null : _submitEmail,
                            child: cargando
                                ? const SizedBox(
                                    height: 18, width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : Text(_modoRegistro
                                    ? 'Crear cuenta'
                                    : 'Iniciar sesión'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Toggle registro / login ────────────────────
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _modoRegistro = !_modoRegistro),
                      child: Text(
                        _modoRegistro
                            ? '¿Ya tenés cuenta? Iniciar sesión'
                            : '¿No tenés cuenta? Registrarte',
                        style: const TextStyle(
                            color: AppColors.text3, fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Google Sign-In ─────────────────────────────
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: Text('o',
                          style: const TextStyle(
                              color: AppColors.text3,
                              fontSize: 12)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Text('G',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF4285F4),
                          )),
                      label: const Text('Continuar con Google'),
                      onPressed: cargando
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthIniciarGoogle()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: const BorderSide(
                            color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

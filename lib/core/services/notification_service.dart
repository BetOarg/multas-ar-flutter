import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'plazos_service.dart';

// ══════════════════════════════════════════════════════════════════
// NOTIFICATION SERVICE
// Notificaciones locales para vencimientos de plazos.
// Canal: ALTA prioridad para plazos críticos.
// ══════════════════════════════════════════════════════════════════

class NotificationService {
  static const _channelId = 'multas_plazos';
  static const _channelName = 'Vencimientos de plazos';
  static const _channelDesc = 'Alertas de vencimientos críticos de multas';

  static Future<void> inicializar(
      FlutterLocalNotificationsPlugin plugin) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await plugin.initialize(settings);

    // Crear canal Android con alta prioridad
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // ── Programar notificación para un plazo ─────────────────────
  static Future<void> programarAlertaPlazo({
    required FlutterLocalNotificationsPlugin plugin,
    required int id,
    required PlazoCalculado plazo,
    required String casoDescripcion,
    int diasAntes = 3,
  }) async {
    if (plazo.diasRestantes < 0) return; // ya vencido

    final fechaNotif = plazo.fechaVencimiento
        .subtract(Duration(days: diasAntes));
    if (fechaNotif.isBefore(DateTime.now())) return;

    final tzFecha = tz.TZDateTime.from(fechaNotif, tz.local);

    await plugin.zonedSchedule(
      id,
      '⚠️ Plazo próximo a vencer — $casoDescripcion',
      '${plazo.nombre} vence en $diasAntes días. ${plazo.norma}',
      tzFecha,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            '${plazo.nombre}\n'
            'Vence: ${_fmt(plazo.fechaVencimiento)}\n'
            'Norma: ${plazo.norma}',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Notificación inmediata de vencimiento ────────────────────
  static Future<void> notificarVencimientoInmediato({
    required FlutterLocalNotificationsPlugin plugin,
    required int id,
    required PlazoCalculado plazo,
    required String casoDescripcion,
  }) async {
    await plugin.show(
      id,
      '🚨 VENCIMIENTO: $casoDescripcion',
      '${plazo.nombre} — ${plazo.norma}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
        ),
      ),
    );
  }

  // ── Cancelar notificaciones de un caso ───────────────────────
  static Future<void> cancelarPorCaso({
    required FlutterLocalNotificationsPlugin plugin,
    required String casoId,
    required int cantidadPlazos,
  }) async {
    // IDs basados en hash del casoId × índice de plazo
    final baseId = casoId.hashCode.abs();
    for (int i = 0; i < cantidadPlazos; i++) {
      await plugin.cancel(baseId + i);
    }
  }

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializar zonas horarias
    tz.initializeTimeZones();

    // Configuración para Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permisos en Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final IOSFlutterLocalNotificationsPlugin? iosImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Aquí puedes manejar cuando el usuario toca una notificación
    // Por ejemplo, navegar a una página específica
    print('Notificación tocada: ${response.payload}');
  }

  // Mostrar notificación inmediata
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'treatment_channel',
      'Tratamientos',
      channelDescription: 'Notificaciones de tratamientos médicos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Programar notificación en una fecha/hora específica
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'treatment_reminders',
      'Recordatorios de Medicamentos',
      channelDescription: 'Recordatorios para tomar medicamentos',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Programar notificaciones recurrentes para un medicamento
  Future<void> scheduleMedicationReminders({
    required String medicationId,
    required String medicationName,
    required String dosage,
    required DateTime startTime,
    required Duration frequency,
    required int durationDays,
  }) async {
    // Cancelar notificaciones anteriores de este medicamento
    await cancelMedicationNotifications(medicationId);

    // Calcular el número de notificaciones a programar
    final int notificationsPerDay = const Duration(hours: 24).inHours ~/ frequency.inHours;
    final int totalNotifications = notificationsPerDay * durationDays;

    // Programar cada notificación
    for (int i = 0; i < totalNotifications; i++) {
      final notificationTime = startTime.add(frequency * i);

      // Solo programar si la fecha es futura
      if (notificationTime.isAfter(DateTime.now())) {
        final notificationId = _generateNotificationId(medicationId, i);

        await scheduleNotification(
          id: notificationId,
          title: '⏰ Recordatorio de Medicamento',
          body: 'Es hora de tomar $medicationName ($dosage)',
          scheduledTime: notificationTime,
          payload: 'medication_$medicationId',
        );
      }
    }
  }

  // Generar ID único para notificación de medicamento
  int _generateNotificationId(String medicationId, int index) {
    // Combinar medicationId hashCode con el índice para crear un ID único
    return (medicationId.hashCode % 100000) + index;
  }

  // Cancelar todas las notificaciones de un medicamento específico
  Future<void> cancelMedicationNotifications(String medicationId) async {
    // Cancelar las primeras 1000 posibles notificaciones de este medicamento
    for (int i = 0; i < 1000; i++) {
      final notificationId = _generateNotificationId(medicationId, i);
      await _notifications.cancel(notificationId);
    }
  }

  // Cancelar una notificación específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Obtener notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

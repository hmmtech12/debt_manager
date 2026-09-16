import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications so reminders work fully offline.
/// Call [init] once at app startup, then [scheduleReminder] whenever a
/// reminder row is created (see DebtRepository.addReminder).
///
/// flutter_local_notifications has no official web target, so every
/// method here is a safe no-op on web (`kIsWeb`) rather than throwing —
/// the Settings/Debt Details UI shows an explanatory note instead of
/// silently failing.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isSupported => !kIsWeb;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    tz_data.initializeTimeZones();
    // Falls back to UTC if the device timezone can't be resolved; reminders
    // still fire, just without DST-aware local-time precision.
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // requested explicitly below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Requests the OS notification permission. Call this from Settings when
  /// the user turns reminders on, not silently at first launch.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? true;
    }
    final iosImpl =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? true;
    }
    return true;
  }

  /// Schedules (or, on unsupported platforms during dev, immediately shows
  /// a debug log for) a single reminder notification.
  ///
  /// [id] must be a stable, unique integer per reminder — callers derive
  /// it from a hash of the reminder's UUID (see DebtsNotifier).
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return; // no-op: see class doc
    if (!_initialized) await init();

    // Never schedule in the past — fire immediately instead so the user
    // still sees the reminder rather than silently losing it.
    final effectiveDate = scheduledDate.isBefore(DateTime.now())
        ? DateTime.now().add(const Duration(seconds: 2))
        : scheduledDate;

    const androidDetails = AndroidNotificationDetails(
      'debt_reminders',
      'Debt Reminders',
      channelDescription: 'Reminders for upcoming or overdue debts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(effectiveDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Scheduling can fail in dev environments without timezone data
      // configured; never crash the app over a reminder.
      if (kDebugMode) debugPrint('NotificationService.scheduleReminder failed: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }
}

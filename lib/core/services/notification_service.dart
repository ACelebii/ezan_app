import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/hatirlaticilar/data/reminder_sound.dart';

/// Yerel bildirimleri (hatırlatıcılar) zamanlayan ince sarmalayıcı.
///
/// Uygulama şu an sadece Türkiye şehirleriyle çalıştığından (bkz.
/// vakitler_page.dart'taki sabit `country=Turkey`), saat dilimi
/// `Europe/Istanbul` olarak sabitlenir; ayrı bir cihaz saat dilimi
/// paketine ihtiyaç yoktur.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      for (final sound in ReminderSounds.all.where((s) => s.isAvailable)) {
        await androidPlugin.createNotificationChannel(_channelFor(sound));
      }
    }

    _initialized = true;
  }

  Future<PermissionStatus> requestPermissions() =>
      Permission.notification.request();

  Future<PermissionStatus> permissionStatus() => Permission.notification.status;

  AndroidNotificationChannel _channelFor(ReminderSound sound) {
    return AndroidNotificationChannel(
      'reminder_${sound.key}',
      'Hatırlatıcı (${sound.displayName})',
      description: 'Namaz vakti hatırlatıcı bildirimleri',
      importance: Importance.high,
      sound: sound.assetPath == null
          ? null
          : RawResourceAndroidNotificationSound(sound.key),
    );
  }

  /// Haftalık, belirli bir güne (ör. Cuma) sabitlenmiş tekrarlayan hatırlatıcı.
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required int hour,
    required int minute,
    required String soundKey,
  }) async {
    final scheduled = _nextInstanceOfWeekday(weekday, hour, minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _detailsFor(soundKey),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Her gün aynı saatte tekrarlayan hatırlatıcı (ör. Teheccüt).
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String soundKey,
  }) async {
    final scheduled = _nextInstanceOfTime(hour, minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _detailsFor(soundKey),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Tek seferlik, belirli bir tarih+saatte hatırlatıcı (ör. Ramazan'ın belirli bir günü).
  /// Geçmişte kalan bir zaman verilirse sessizce hiçbir şey planlamaz.
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    required String soundKey,
  }) async {
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _detailsFor(soundKey),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelRange(int startId, int endIdInclusive) async {
    for (var id = startId; id <= endIdInclusive; id++) {
      await _plugin.cancel(id);
    }
  }

  NotificationDetails _detailsFor(String soundKey) {
    final requested = ReminderSounds.byKey(soundKey);
    final effective = requested.isAvailable ? requested : ReminderSounds.varsayilan;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'reminder_${effective.key}',
        'Hatırlatıcı (${effective.displayName})',
        channelDescription: 'Namaz vakti hatırlatıcı bildirimleri',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        sound: effective.assetPath == null ? null : '${effective.key}.caf',
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

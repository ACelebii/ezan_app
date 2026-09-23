import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/hatirlaticilar/data/reminder_sound.dart';
import '../vakit/zaman_dilimi.dart';

/// Yerel bildirimleri (hatırlatıcılar) zamanlayan ince sarmalayıcı.
///
/// Bildirimler mutlak anlarla ([scheduleAt]) kurulur; hangi saat diliminde
/// olunduğu önemli değildir. `tz.local` yalnızca `initialize` içinde
/// Europe/Istanbul'a ayarlanır ve zamanlama tarafından kullanılmaz.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    zamanDilimleriniHazirla();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
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

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Android 12+ "Alarmlar ve hatırlatıcılar" izni verilmiş mi? Android 14'ten
  /// itibaren yeni kurulumlarda varsayılan olarak kapalıdır. Eski Android'de ve
  /// iOS'ta bu izin gerekmez, true döner.
  Future<bool> tamZamanliBildirimIzniVar() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  /// Kullanıcıyı sistemin "Alarmlar ve hatırlatıcılar" ekranına götürür ve
  /// izin durumunu döner. Kullanıcıya bu iznin neden gerektiğini (ezanın
  /// dakikasında çalması) bu çağrıdan ÖNCE açıklayın.
  Future<bool> tamZamanliBildirimIzniIste() async =>
      await _android?.requestExactAlarmsPermission() ?? true;

  /// Android'in pil optimizasyonu bu uygulamayı kısıtlamıyor mu (yoksayma
  /// izni verilmiş mi)? Kısıtlanmışsa sistem, arka plan bildirim yenilemesini
  /// (WorkManager, 12 saatte bir) geciktirebilir ya da hiç çalıştırmayabilir;
  /// tam zamanlı alarmlar (ezan bildirimleri) bundan etkilenmez. iOS'ta ve bu
  /// izni bilmeyen eski Android'de true döner (kart gösterilmez).
  Future<bool> pilOptimizasyonuYoksayiliyorMu() async {
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Kullanıcıyı sistemin "Pil optimizasyonunu yoksay" iznine götürür.
  Future<bool> pilOptimizasyonuYoksaymayiIste() async {
    try {
      return (await Permission.ignoreBatteryOptimizations.request())
          .isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Verilen anda tek seferlik bildirim (ör. bir günün ezan vakti).
  ///
  /// [tamZamanli] doğruysa `exactAllowWhileIdle` kullanılır: bildirim dakikasında
  /// çalar. Yanlışsa (izin yok) `inexactAllowWhileIdle`: Android bildirimi birkaç
  /// dakika geciktirebilir. Toplu kurulumda değeri bir kez
  /// [tamZamanliBildirimIzniVar] ile alıp bütün çağrılara verin.
  ///
  /// Geçmişte kalan bir an verilirse hiçbir şey kurulmaz ve aynı id'li eski
  /// bildirim iptal edilir. Yalnızca mutlak anı kullanır; `tz.local`'a bağlı değildir.
  ///
  /// [payload], bildirimle birlikte saklanır ve [bekleyenler] ile geri okunur;
  /// zamanlayıcı bununla "bu bildirim zaten doğru kurulu mu" diye bakar.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime zaman,
    required String soundKey,
    required bool tamZamanli,
    String? payload,
  }) async {
    if (!zaman.isAfter(DateTime.now())) {
      await cancel(id);
      return;
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      zaman,
      _detailsFor(soundKey),
      androidScheduleMode: tamZamanli
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  /// Henüz çalmamış, sistemde kayıtlı bildirimler: id → payload. Uygulama
  /// zorla durdurulup alarmlar silinirse, zamanlayıcı bunu buradan fark eder.
  Future<Map<int, String?>> bekleyenler() async => {
        for (final n in await _plugin.pendingNotificationRequests())
          n.id: n.payload,
      };

  NotificationDetails _detailsFor(String soundKey) {
    final requested = ReminderSounds.byKey(soundKey);
    final effective =
        requested.isAvailable ? requested : ReminderSounds.varsayilan;
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
}

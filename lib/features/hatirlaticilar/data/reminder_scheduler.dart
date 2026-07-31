import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../../auth/auth_service.dart';
import '../../../core/services/notification_service.dart';

/// Hatırlatıcı ayarlarını (Cuma/Oruç/Teheccüt/Ramazan) gerçek namaz
/// vakitleriyle birleştirip [NotificationService] üzerinden zamanlar.
///
/// Vakitler `AuthService`'in önbelleğinden okunur (yoksa vakitler_page.dart
/// ile aynı Aladhan uç noktasından çekilip önbelleğe alınır). Bilinçli
/// basitleştirme: dakika bazında ofset düşülürken gece yarısını geriye
/// doğru geçme ihtimali yok sayıldı — Türkiye'de İmsak vakti hiçbir zaman
/// gece 01:10'dan önce olmadığından (en uzun ofset 70 dakika), bu senaryo
/// pratikte hiç oluşmaz.
class ReminderScheduler {
  ReminderScheduler._();

  static const cumaId = 101;
  static const orucPazartesiId = 102;
  static const orucPersembeId = 103;
  static const teheccutId = 104;
  static const ramazanBaseId = 200;
  static const ramazanMaxDays = 30;

  /// 6 vakit x 7 gün = 42 id (300-341): asıl ezan alarmı.
  static const vakitEzanBaseId = 300;

  /// 6 vakit x 1 id = 6 id (350-355): vaktinden önce uyarı.
  static const vakitOnceBaseId = 350;

  /// 4 vakit x 2 hatırlatma = 8 id (400-407): "Vaktinde Kıl".
  static const vaktindeKilBaseId = 400;

  static const vakitKeys = [
    'imsak',
    'sabah',
    'ogle',
    'ikindi',
    'aksam',
    'yatsi',
  ];

  /// Ayarlar sayfalarında kullanılan görünen etiketler (vakit_settings_page
  /// ve settings_page'deki vakit alarm bölümü aynı etiketleri kullanır).
  static const vakitLabels = {
    'imsak': 'İmsak Vakti',
    'sabah': 'Sabah Ezanı',
    'ogle': 'Öğle Vakti',
    'ikindi': 'İkindi Vakti',
    'aksam': 'Akşam Vakti',
    'yatsi': 'Yatsı Vakti',
  };

  static const vakitDisplayNames = {
    'imsak': 'İmsak',
    'sabah': 'Sabah',
    'ogle': 'Öğle',
    'ikindi': 'İkindi',
    'aksam': 'Akşam',
    'yatsi': 'Yatsı',
  };

  /// Vakit anahtarlarının Aladhan API'deki karşılık gelen alan adları.
  static const vakitAladhanField = {
    'imsak': 'Fajr',
    'sabah': 'Sunrise',
    'ogle': 'Dhuhr',
    'ikindi': 'Asr',
    'aksam': 'Maghrib',
    'yatsi': 'Isha',
  };

  static const vaktindeKilKeys = ['ogle', 'ikindi', 'aksam', 'yatsi'];

  static String? vakitKeyFromLabel(String label) {
    for (final entry in vakitLabels.entries) {
      if (entry.value == label) return entry.key;
    }
    return null;
  }

  static const _turkceAylar = {
    'Ocak': 1,
    'Şubat': 2,
    'Mart': 3,
    'Nisan': 4,
    'Mayıs': 5,
    'Haziran': 6,
    'Temmuz': 7,
    'Ağustos': 8,
    'Eylül': 9,
    'Ekim': 10,
    'Kasım': 11,
    'Aralık': 12,
  };

  static Future<void> rescheduleAll(AuthService authService) async {
    final ayarlar = authService.hatirlaticiAyarlari;
    final city = authService.seciliSehir['isim'] as String? ?? 'İstanbul';

    final timings = await timingsFor(authService, city);
    if (timings == null) return;

    final imsak = parseMinutesOfDay(timings['Fajr']);
    final ogle = parseMinutesOfDay(timings['Dhuhr']);
    if (imsak == null || ogle == null) return;

    await _rescheduleCuma(_ayar(ayarlar, 'cuma'), ogle);
    await _rescheduleOruc(_ayar(ayarlar, 'oruc'), imsak);
    await _rescheduleTeheccut(_ayar(ayarlar, 'teheccut'), imsak);
    await _rescheduleRamazan(_ayar(ayarlar, 'ramazan'), imsak);
    await _rescheduleVakitEzanlari(authService, timings);
    await _rescheduleVaktindeKil(authService, timings);
  }

  static Future<void> _rescheduleVakitEzanlari(
      AuthService authService, Map<String, dynamic> timings) async {
    final ayarlar = authService.vakitEzanAyarlari;
    for (var i = 0; i < vakitKeys.length; i++) {
      final key = vakitKeys[i];
      final ayar = _ayar(ayarlar, key);
      final field = vakitAladhanField[key]!;
      final minutes = parseMinutesOfDay(timings[field]);
      final displayName = vakitDisplayNames[key]!;
      final gunler = _gunlerOf(ayar);

      final ezanBase = vakitEzanBaseId + i * 7;
      if (ayar['enabled'] != true || minutes == null) {
        await NotificationService.instance
            .cancelRange(ezanBase, ezanBase + 6);
      } else {
        final sound = (ayar['sound'] as String?) ?? 'ezan_kisa';
        for (var weekday = DateTime.monday;
            weekday <= DateTime.sunday;
            weekday++) {
          final id = ezanBase + (weekday - DateTime.monday);
          if (!gunler[weekday % 7]) {
            await NotificationService.instance.cancel(id);
            continue;
          }
          await NotificationService.instance.scheduleWeekly(
            id: id,
            title: '$displayName Ezanı',
            body: '$displayName vakti girdi.',
            weekday: weekday,
            hour: minutes ~/ 60,
            minute: minutes % 60,
            soundKey: sound,
          );
        }
      }

      final onceId = vakitOnceBaseId + i;
      if (ayar['onceEnabled'] != true || minutes == null) {
        await NotificationService.instance.cancel(onceId);
      } else {
        final onceDakika = (ayar['onceDakika'] as int?) ?? 45;
        final t = triggerTime(minutes, onceDakika);
        await NotificationService.instance.scheduleDaily(
          id: onceId,
          title: '$displayName Vaktine Yaklaşıyor',
          body: '$displayName vaktine yaklaşık $onceDakika dakika kaldı.',
          hour: t.hour,
          minute: t.minute,
          soundKey: (ayar['onceSound'] as String?) ?? 'uyari',
        );
      }
    }
  }

  /// "Günler" alanını Firestore/SharedPreferences round-trip'inden sonra
  /// bile güvenle List<bool>'a çevirir; index 0=Pazar ... 6=Cumartesi
  /// (DateTime.weekday % 7 ile aynı sırada).
  static List<bool> _gunlerOf(Map<String, dynamic> ayar) {
    final raw = ayar['gunler'] as List?;
    if (raw == null || raw.length != 7) {
      return List.filled(7, true);
    }
    return raw.map((e) => e == true).toList();
  }

  static Future<void> _rescheduleVaktindeKil(
      AuthService authService, Map<String, dynamic> timings) async {
    final ayarlar = authService.vaktindeKilAyarlari;
    for (var i = 0; i < vaktindeKilKeys.length; i++) {
      final key = vaktindeKilKeys[i];
      final ayar = _ayar(ayarlar, key);
      final field = vakitAladhanField[key]!;
      final minutes = parseMinutesOfDay(timings[field]);
      final id1 = vaktindeKilBaseId + i * 2;
      final id2 = id1 + 1;

      if (ayar['enabled'] != true || minutes == null) {
        await NotificationService.instance.cancel(id1);
        await NotificationService.instance.cancel(id2);
        continue;
      }

      final displayName = vakitDisplayNames[key]!;
      final ilkUyari = (ayar['ilkUyariDakika'] as int?) ?? 30;
      final siklik = (ayar['siklikDakika'] as int?) ?? 10;
      final sound = (ayar['sound'] as String?) ?? 'melodi_19';

      final t1 = triggerTime(minutes, -ilkUyari);
      await NotificationService.instance.scheduleDaily(
        id: id1,
        title: 'Haydi kalk!',
        body: 'Vakit girdi, $displayName namazını kıl.',
        hour: t1.hour,
        minute: t1.minute,
        soundKey: sound,
      );

      final t2 = triggerTime(minutes, -(ilkUyari + siklik));
      await NotificationService.instance.scheduleDaily(
        id: id2,
        title: 'Hatırlatma',
        body: '$displayName namazını henüz kılmadıysan vakit daralıyor.',
        hour: t2.hour,
        minute: t2.minute,
        soundKey: sound,
      );
    }
  }

  static Map<String, dynamic> _ayar(
          Map<String, dynamic> ayarlar, String key) =>
      Map<String, dynamic>.from(ayarlar[key] as Map? ?? const {});

  static Future<Map<String, dynamic>?> timingsFor(
      AuthService authService, String city) async {
    final cached = await authService.getCachedPrayerTimes(city);
    if (cached != null) return cached;
    try {
      final url = Uri.parse(
          'https://api.aladhan.com/v1/timingsByCity?city=$city&country=Turkey&method=${authService.apiMethod}');
      final response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']['timings']
            as Map<String, dynamic>;
        await authService.cachePrayerTimes(city, data);
        return data;
      }
    } catch (_) {
      // internet yok ve önbellek de boşsa, bu turda hatırlatıcı planlanamaz.
    }
    return null;
  }

  /// "05:23 (+03)" gibi Aladhan formatındaki bir vakit metnini gece
  /// yarısından itibaren geçen dakikaya çevirir. Test edilebilir olması
  /// için public bırakıldı.
  static int? parseMinutesOfDay(dynamic raw) {
    if (raw is! String) return null;
    final parts = raw.split(' ').first.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  /// Bir vakitten belirli dakika önceki saat:dakikayı hesaplar. Test
  /// edilebilir olması için public bırakıldı.
  static ({int hour, int minute}) triggerTime(
      int baseMinutesOfDay, int offsetMinutes) {
    final total = ((baseMinutesOfDay - offsetMinutes) % 1440 + 1440) % 1440;
    return (hour: total ~/ 60, minute: total % 60);
  }

  static Future<void> _rescheduleCuma(
      Map<String, dynamic> ayar, int ogleMinutes) async {
    if (ayar['enabled'] != true) {
      await NotificationService.instance.cancel(cumaId);
      return;
    }
    final offset = (ayar['offset'] as int?) ?? 60;
    final t = triggerTime(ogleMinutes, offset);
    await NotificationService.instance.scheduleWeekly(
      id: cumaId,
      title: 'Cuma Namazı Hatırlatması',
      body: 'Cuma namazına yaklaşık $offset dakika kaldı.',
      weekday: DateTime.friday,
      hour: t.hour,
      minute: t.minute,
      soundKey: (ayar['sound'] as String?) ?? 'uyari',
    );
  }

  static Future<void> _rescheduleOruc(
      Map<String, dynamic> ayar, int imsakMinutes) async {
    if (ayar['enabled'] != true) {
      await NotificationService.instance.cancel(orucPazartesiId);
      await NotificationService.instance.cancel(orucPersembeId);
      return;
    }
    final offset = (ayar['offset'] as int?) ?? 60;
    final t = triggerTime(imsakMinutes, offset);
    final soundKey = (ayar['sound'] as String?) ?? 'uyari';
    await NotificationService.instance.scheduleWeekly(
      id: orucPazartesiId,
      title: 'Pazartesi Orucu',
      body: 'Sahur vakti! İmsağa yaklaşık $offset dakika kaldı.',
      weekday: DateTime.monday,
      hour: t.hour,
      minute: t.minute,
      soundKey: soundKey,
    );
    await NotificationService.instance.scheduleWeekly(
      id: orucPersembeId,
      title: 'Perşembe Orucu',
      body: 'Sahur vakti! İmsağa yaklaşık $offset dakika kaldı.',
      weekday: DateTime.thursday,
      hour: t.hour,
      minute: t.minute,
      soundKey: soundKey,
    );
  }

  static Future<void> _rescheduleTeheccut(
      Map<String, dynamic> ayar, int imsakMinutes) async {
    if (ayar['enabled'] != true) {
      await NotificationService.instance.cancel(teheccutId);
      return;
    }
    final offset = (ayar['offset'] as int?) ?? 45;
    final t = triggerTime(imsakMinutes, offset);
    await NotificationService.instance.scheduleDaily(
      id: teheccutId,
      title: 'Teheccüt Vakti',
      body: 'Teheccüt namazı için uyanma vakti, imsağa yaklaşık $offset dakika var.',
      hour: t.hour,
      minute: t.minute,
      soundKey: (ayar['sound'] as String?) ?? 'uyari',
    );
  }

  static Future<void> _rescheduleRamazan(
      Map<String, dynamic> ayar, int imsakMinutes) async {
    await NotificationService.instance
        .cancelRange(ramazanBaseId, ramazanBaseId + ramazanMaxDays - 1);
    if (ayar['enabled'] != true) return;

    final window = await currentRamadanWindow();
    if (window == null) return;

    final offset = (ayar['offset'] as int?) ?? 60;
    final soundKey = (ayar['sound'] as String?) ?? 'uyari';
    final t = triggerTime(imsakMinutes, offset);

    var day = window.start;
    var index = 0;
    while (!day.isAfter(window.end) && index < ramazanMaxDays) {
      final dateTime =
          DateTime(day.year, day.month, day.day, t.hour, t.minute);
      await NotificationService.instance.scheduleOnce(
        id: ramazanBaseId + index,
        title: 'Ramazan Davulcusu',
        body: 'Sahur vakti! İmsağa yaklaşık $offset dakika kaldı.',
        dateTime: dateTime,
        soundKey: soundKey,
      );
      day = day.add(const Duration(days: 1));
      index++;
    }
  }

  /// `assets/json/dini_gunler.json` içinden içinde bulunulan/gelecek en
  /// yakın Ramazan aralığını döndürür. Yıl için veri yoksa (ör. birkaç
  /// yıl sonrası) null döner ve Ramazan hatırlatıcısı hiçbir şey planlamaz.
  static Future<({DateTime start, DateTime end})?> currentRamadanWindow(
      {DateTime? now}) async {
    try {
      final raw = await rootBundle.loadString('assets/json/dini_gunler.json');
      final List<dynamic> entries = json.decode(raw);
      return ramadanWindowFromEntries(
          entries.cast<Map<String, dynamic>>(), now ?? DateTime.now());
    } catch (_) {
      // JSON okunamazsa Ramazan hatırlatıcısı hiçbir şey planlamaz.
      return null;
    }
  }

  /// [currentRamadanWindow]'un asset okuma dışındaki saf hesaplama kısmı.
  /// Test edilebilir olması için public bırakıldı.
  static ({DateTime start, DateTime end})? ramadanWindowFromEntries(
      List<Map<String, dynamic>> entries, DateTime today) {
    DateTime? dateOf(Map<String, dynamic> entry) {
      final ay = _turkceAylar[entry['ay']];
      final gun = int.tryParse('${entry['gunNo']}');
      final yil = entry['yil'];
      if (ay == null || gun == null || yil == null) return null;
      return DateTime(yil is int ? yil : int.parse('$yil'), ay, gun);
    }

    final ramazanGirisleri =
        entries.where((e) => e['baslik'] == "Ramazan'ın İlk Günü");

    for (final giris in ramazanGirisleri) {
      final start = dateOf(giris);
      if (start == null) continue;
      final bayram = entries.where((e) =>
          e['baslik'] == 'Ramazan Bayramı' && e['yil'] == giris['yil']);
      final bayramTarihi = bayram.isEmpty ? null : dateOf(bayram.first);
      final end = (bayramTarihi ?? start.add(const Duration(days: 30)))
          .subtract(const Duration(days: 1));
      if (!today.isAfter(end)) {
        return (start: start, end: end);
      }
    }
    return null;
  }
}

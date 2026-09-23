import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../auth/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/vakit/vakit_modelleri.dart';
import '../../../core/vakit/vakit_servisi.dart';
import '../../../core/vakit/zaman_dilimi.dart';
import '../../../locator.dart';
import 'bildirim_girdisi.dart';

/// Kurulacak tek bir bildirim.
class PlanliBildirim {
  const PlanliBildirim(this.id, this.baslik, this.govde, this.an, this.ses);

  final int id;
  final String baslik;
  final String govde;

  /// Bildirimin çalacağı mutlak an (UTC).
  final DateTime an;
  final String ses;

  /// Bildirimin içeriğinin özeti; sistemdeki kayıtla aynıysa yeniden
  /// kurmaya gerek yoktur. İzin durumu da içindedir: tam zamanlı alarm izni
  /// sonradan verilirse bildirimler tam zamanlı olarak yeniden kurulur.
  String parmakIzi(bool tamZamanli) =>
      '${an.millisecondsSinceEpoch}|$baslik|$govde|$ses|$tamZamanli';
}

/// Hatırlatıcı ayarlarını (vakit ezanları, vaktinden önce uyarı, Vaktinde Kıl,
/// Cuma, oruç, Teheccüt, Ramazan) gerçek namaz vakitleriyle birleştirip
/// [NotificationService] üzerinden zamanlar.
///
/// Vakitler her gün 1-2 dakika kaydığı için hiçbir bildirim "her gün aynı
/// saatte" ya da "her hafta" diye tekrarlanmaz. Onun yerine önümüzdeki
/// [gunSayisi] günün her biri için, o günün gerçek vaktine göre ayrı bir tek
/// seferlik bildirim kurulur. Kural hesabı [planla]da (saf, testli), sisteme
/// kurma [uygula]dadır.
///
/// ponytail: bildirimler uygulama açıldıkça yenilenir; uygulama [gunSayisi]
/// gün hiç açılmazsa biter. Gerekirse arka plan yenilemesi (WorkManager)
/// eklenir.
class ReminderScheduler {
  ReminderScheduler._();

  /// Kaç gün ileriye bildirim kurulduğu. Tüm bildirim türleri açıkken en
  /// fazla ~315 alarm eder; Android'in uygulama başına 500 alarm sınırının
  /// altında. Yeni bildirim türü eklenirse bu sayı yeniden hesaplanmalı.
  static const gunSayisi = 14;

  // Her tür için id aralığı: taban + (vakit sırası * gunSayisi) + gün dilimi.
  // Gün dilimi = takvim gününün 14'e bölümünden kalan; bir bildirim yenilemeler
  // arasında hep aynı id'yi taşır, 14 ardışık günün id'leri çakışmaz.
  static const _ezanTaban = 1000; // 6 vakit x 14 = 1000-1083
  static const _onceTaban = 1100; // 6 x 14 = 1100-1183
  static const _kilTaban = 1200; // 4 vakit x 2 uyarı x 14 = 1200-1311
  static const _teheccutTaban = 1400; // 1400-1413
  static const _cumaTaban = 1420; // 1420-1433
  static const _orucTaban = 1440; // Pazartesi/Perşembe, 1440-1453
  static const _ramazanTaban = 200; // 200-213 (eski aralıkla aynı)

  static const vakitKeys = [
    'imsak',
    'sabah',
    'ogle',
    'ikindi',
    'aksam',
    'yatsi',
  ];

  /// Ayar anahtarlarının vakit çekirdeğindeki karşılığı. "Sabah" Güneş
  /// vaktidir.
  static const vakitOf = {
    'imsak': Vakit.imsak,
    'sabah': Vakit.gunes,
    'ogle': Vakit.ogle,
    'ikindi': Vakit.ikindi,
    'aksam': Vakit.aksam,
    'yatsi': Vakit.yatsi,
  };

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

  static Future<void>? _calisan;
  static bool _yenidenIstendi = false;

  /// Ayarlara ve seçili şehrin vakitlerine göre bildirimleri günceller.
  ///
  /// Ayar değişince ve uygulama öne gelince çağrılır. Aynı anda birden çok
  /// çağrı gelirse çalışan tur bitince güncel ayarlarla bir tur daha yapılır.
  static Future<void> rescheduleAll(AuthService authService) {
    final calisan = _calisan;
    if (calisan != null) {
      _yenidenIstendi = true;
      return calisan;
    }
    return _calisan = _turlariCalistir(authService);
  }

  static Future<void> _turlariCalistir(AuthService authService) async {
    try {
      do {
        _yenidenIstendi = false;
        await _kur(authService);
      } while (_yenidenIstendi);
    } finally {
      _calisan = null;
    }
  }

  static Future<void> _kur(AuthService authService) async {
    // Zaten hazırsa hemen döner; timezone verisinin yüklü olmasını da sağlar.
    await NotificationService.instance.initialize();

    final konum = authService.seciliSehir.konum;

    final hatirlaticilar = authService.hatirlaticiAyarlari;
    final girdi = BildirimGirdisi(
      konum: konum,
      tercih: authService.vakitTercihi,
      hatirlaticilar: hatirlaticilar,
      vakitEzanAyarlari: authService.vakitEzanAyarlari,
      vaktindeKilAyarlari: authService.vaktindeKilAyarlari,
      ramazan: _ayar(hatirlaticilar, 'ramazan')['enabled'] == true
          ? await currentRamadanWindow()
          : null,
      ertelemeBitisi: authService.bildirimErteleBitis,
    );
    // Arka plan görevi bu kayıttan çalışır (uygulama açılmasa da).
    await girdiyiKaydet(girdi);
    await girdiyiUygula(girdi, locator<VakitServisi>());
  }

  /// WorkManager görevinin adı (hem benzersiz ad hem görev adı).
  static const arkaPlanGorevi = 'bildirimYenile';
  static const _girdiAnahtari = 'bildirim_girdisi_v1';

  static Future<void> girdiyiKaydet(BildirimGirdisi girdi) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_girdiAnahtari, jsonEncode(girdi.toJson()));
    } catch (e) {
      debugPrint('Bildirim girdisi kaydedilemedi: $e');
    }
  }

  static Future<BildirimGirdisi?> girdiyiOku() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metin = prefs.getString(_girdiAnahtari);
      if (metin == null) return null;
      return BildirimGirdisi.fromJson(
          jsonDecode(metin) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Bildirim girdisi okunamadı: $e');
      return null;
    }
  }

  /// [girdi]ye göre vakitleri alır, planlar ve sisteme uygular. Vakit yoksa (ağ
  /// da önbellek de yok) null döner ve mevcut bildirimlere dokunmaz.
  static Future<({int kurulan, int iptal})?> girdiyiUygula(
      BildirimGirdisi girdi, VakitServisi servis) async {
    await NotificationService.instance.initialize();
    final List<GunlukVakit> gunler;
    try {
      gunler = await servis.vakitleriGetir(girdi.konum, girdi.tercih);
    } on VakitHatasi {
      return null;
    }
    final plan = planla(
      gunler: gunler,
      bugun: servis.bugun(girdi.konum),
      simdi: DateTime.now(),
      hatirlaticilar: girdi.hatirlaticilar,
      vakitEzanAyarlari: girdi.vakitEzanAyarlari,
      vaktindeKilAyarlari: girdi.vaktindeKilAyarlari,
      ramazan: girdi.ramazan,
      ertelemeBitisi: girdi.ertelemeBitisi,
    );
    return uygula(plan, girdi.konum);
  }

  /// WorkManager'ın periyodik görevi: uygulama açılmasa da bildirimleri yeni
  /// güne göre yeniler. Böylece uygulama günlerce açılmayan kullanıcıda ileriye
  /// kurulu bildirimler bitmez ([gunSayisi] ufku kayar).
  ///
  /// true: iş bitti (ya da yapacak bir şey yok, uygulama hiç planlamadı);
  /// false: vakit alınamadı, WorkManager daha sonra yeniden dener.
  static Future<bool> arkaPlandaYenile({VakitServisi? servis}) async {
    final girdi = await girdiyiOku();
    if (girdi == null) return true;
    final sonuc = await girdiyiUygula(girdi, servis ?? VakitServisi());
    if (sonuc == null) {
      debugPrint(
          'Arka plan bildirim yenilemesi: vakit alınamadı, tekrar denenecek.');
      return false;
    }
    debugPrint('Arka plan bildirim yenilemesi: '
        '${sonuc.kurulan} kuruldu, ${sonuc.iptal} iptal edildi.');
    return true;
  }

  /// Ayarlardan ve vakitlerden, kurulması gereken bütün bildirimleri hesaplar.
  ///
  /// [bugun], konumun takvimine göre bugündür (`DateTime.utc(y, a, g)`);
  /// yalnızca [bugun] ve sonraki [gunSayisi] - 1 gün için, ve yalnızca
  /// [simdi]den sonraki anlar için bildirim üretilir. [ertelemeBitisi]
  /// doluysa ("Bildirimleri Ertele") o andan önceki hiçbir bildirim
  /// üretilmez; sonrakiler normal kurulur, yani erteleme bitince bildirimler
  /// uygulama açılmasa bile kendiliğinden devam eder.
  static List<PlanliBildirim> planla({
    required List<GunlukVakit> gunler,
    required DateTime bugun,
    required DateTime simdi,
    required Map<String, dynamic> hatirlaticilar,
    required Map<String, dynamic> vakitEzanAyarlari,
    required Map<String, dynamic> vaktindeKilAyarlari,
    ({DateTime start, DateTime end})? ramazan,
    DateTime? ertelemeBitisi,
  }) {
    final plan = <PlanliBildirim>[];
    void ekle(int id, String baslik, String govde, DateTime an, String ses) {
      if (an.isAfter(simdi) &&
          (ertelemeBitisi == null || !an.isBefore(ertelemeBitisi))) {
        plan.add(PlanliBildirim(id, baslik, govde, an.toUtc(), ses));
      }
    }

    final cuma = _ayar(hatirlaticilar, 'cuma');
    final oruc = _ayar(hatirlaticilar, 'oruc');
    final teheccut = _ayar(hatirlaticilar, 'teheccut');
    final ramazanAyar = _ayar(hatirlaticilar, 'ramazan');

    for (final gun in gunler) {
      final fark = gun.tarih.difference(bugun).inDays;
      if (fark < 0 || fark >= gunSayisi) continue;
      final slot = gun.tarih.difference(DateTime.utc(1970)).inDays % gunSayisi;
      final imsak = gun.anlar[Vakit.imsak]!;
      final ogle = gun.anlar[Vakit.ogle]!;

      for (var i = 0; i < vakitKeys.length; i++) {
        final key = vakitKeys[i];
        final ayar = _ayar(vakitEzanAyarlari, key);
        final ad = vakitDisplayNames[key]!;
        final an = gun.anlar[vakitOf[key]!]!;

        if (ayar['enabled'] == true && _gunlerOf(ayar)[gun.tarih.weekday % 7]) {
          ekle(
              _ezanTaban + i * gunSayisi + slot,
              '$ad Ezanı',
              '$ad vakti girdi.',
              an,
              (ayar['sound'] as String?) ?? 'ezan_kisa');
        }
        if (ayar['onceEnabled'] == true) {
          final dakika = _dakika(ayar, 'onceDakika', 45);
          ekle(
              _onceTaban + i * gunSayisi + slot,
              '$ad Vaktine Yaklaşıyor',
              '$ad vaktine yaklaşık $dakika dakika kaldı.',
              an.subtract(Duration(minutes: dakika)),
              (ayar['onceSound'] as String?) ?? 'uyari');
        }
      }

      // Vakit girdikten ilkUyari dakika sonra "Haydi kalk!", siklik dakika
      // sonra da "Hatırlatma".
      for (var k = 0; k < vaktindeKilKeys.length; k++) {
        final key = vaktindeKilKeys[k];
        final ayar = _ayar(vaktindeKilAyarlari, key);
        if (ayar['enabled'] != true) continue;
        final ad = vakitDisplayNames[key]!;
        final an = gun.anlar[vakitOf[key]!]!;
        final ilk = _dakika(ayar, 'ilkUyariDakika', 30);
        final siklik = _dakika(ayar, 'siklikDakika', 10);
        final ses = (ayar['sound'] as String?) ?? 'melodi_19';
        ekle(
            _kilTaban + (k * 2) * gunSayisi + slot,
            'Haydi kalk!',
            'Vakit girdi, $ad namazını kıl.',
            an.add(Duration(minutes: ilk)),
            ses);
        ekle(
            _kilTaban + (k * 2 + 1) * gunSayisi + slot,
            'Hatırlatma',
            '$ad namazını henüz kılmadıysan vakit daralıyor.',
            an.add(Duration(minutes: ilk + siklik)),
            ses);
      }

      if (teheccut['enabled'] == true) {
        final dakika = _dakika(teheccut, 'offset', 45);
        ekle(
            _teheccutTaban + slot,
            'Teheccüt Vakti',
            'Teheccüt namazı için uyanma vakti, imsağa yaklaşık $dakika dakika var.',
            imsak.subtract(Duration(minutes: dakika)),
            (teheccut['sound'] as String?) ?? 'uyari');
      }

      if (cuma['enabled'] == true && gun.tarih.weekday == DateTime.friday) {
        final dakika = _dakika(cuma, 'offset', 60);
        ekle(
            _cumaTaban + slot,
            'Cuma Namazı Hatırlatması',
            'Cuma namazına yaklaşık $dakika dakika kaldı.',
            ogle.subtract(Duration(minutes: dakika)),
            (cuma['sound'] as String?) ?? 'uyari');
      }

      if (oruc['enabled'] == true &&
          (gun.tarih.weekday == DateTime.monday ||
              gun.tarih.weekday == DateTime.thursday)) {
        final dakika = _dakika(oruc, 'offset', 60);
        ekle(
            _orucTaban + slot,
            gun.tarih.weekday == DateTime.monday
                ? 'Pazartesi Orucu'
                : 'Perşembe Orucu',
            'Sahur vakti! İmsağa yaklaşık $dakika dakika kaldı.',
            imsak.subtract(Duration(minutes: dakika)),
            (oruc['sound'] as String?) ?? 'uyari');
      }

      if (ramazanAyar['enabled'] == true &&
          ramazan != null &&
          !gun.tarih.isBefore(_gunOf(ramazan.start)) &&
          !gun.tarih.isAfter(_gunOf(ramazan.end))) {
        final dakika = _dakika(ramazanAyar, 'offset', 60);
        ekle(
            _ramazanTaban + slot,
            'Ramazan Davulcusu',
            'Sahur vakti! İmsağa yaklaşık $dakika dakika kaldı.',
            imsak.subtract(Duration(minutes: dakika)),
            (ramazanAyar['sound'] as String?) ?? 'uyari');
      }
    }
    return plan;
  }

  /// Bu zamanlayıcının yönettiği id'ler: eski haftalık/günlük tekrarlar ve
  /// yenilerin aralıkları. Bunların dışındaki id'lere dokunulmaz.
  static bool _bizimId(int id) =>
      (id >= 101 && id <= 104) || // eski Cuma, oruç, Teheccüt
      (id >= 200 && id <= 229) || // Ramazan
      (id >= 300 && id <= 341) || // eski haftalık ezanlar
      (id >= 350 && id <= 355) || // eski "vaktine yaklaşıyor"
      (id >= 400 && id <= 407) || // eski Vaktinde Kıl
      (id >= 1000 && id < 1500); // yeni tek seferlik bildirimler

  /// Sistemde bekleyenlerle [plan] arasındaki farkı bulur: yalnızca eksik ya da
  /// değişmiş bildirimler kurulur, plandan çıkmış olanlar iptal edilir.
  ///
  /// [bekleyen]: sistemdeki bekleyen bildirimlerin id → payload (parmak izi)
  /// eşlemesi. Eski kurulumdan kalan tekrarlı bildirimlerin payload'ı yoktur;
  /// bu yüzden hiçbir plan girdisiyle eşleşmez ve id'leri plana girmediyse
  /// iptal edilir.
  static ({List<PlanliBildirim> kurulacak, List<int> iptal}) farkHesapla({
    required List<PlanliBildirim> plan,
    required Map<int, String?> bekleyen,
    required bool tamZamanli,
  }) {
    final planIdleri = {for (final b in plan) b.id};
    return (
      kurulacak: [
        for (final b in plan)
          if (bekleyen[b.id] != b.parmakIzi(tamZamanli)) b,
      ],
      iptal: [
        for (final id in bekleyen.keys)
          if (_bizimId(id) && !planIdleri.contains(id)) id,
      ],
    );
  }

  /// [plan]ı sisteme kurar. Ağır işlemdir (bildirim başına ~15-30 ms), bu
  /// yüzden yalnızca değişen bildirimlere dokunur ([farkHesapla]).
  static Future<({int kurulan, int iptal})> uygula(
      List<PlanliBildirim> plan, Konum konum) async {
    zamanDilimleriniHazirla();
    final servis = NotificationService.instance;
    final tamZamanli = await servis.tamZamanliBildirimIzniVar();
    final fark = farkHesapla(
        plan: plan,
        bekleyen: await servis.bekleyenler(),
        tamZamanli: tamZamanli);

    for (final id in fark.iptal) {
      await servis.cancel(id);
    }
    final dilim = tz.getLocation(konum.saatDilimi);
    for (final b in fark.kurulacak) {
      await servis.scheduleAt(
        id: b.id,
        title: b.baslik,
        body: b.govde,
        zaman: tz.TZDateTime.from(b.an, dilim),
        soundKey: b.ses,
        tamZamanli: tamZamanli,
        payload: b.parmakIzi(tamZamanli),
      );
    }
    return (kurulan: fark.kurulacak.length, iptal: fark.iptal.length);
  }

  static DateTime _gunOf(DateTime t) => DateTime.utc(t.year, t.month, t.day);

  static int _dakika(Map<String, dynamic> ayar, String key, int varsayilan) =>
      (ayar[key] as num?)?.toInt() ?? varsayilan;

  static Map<String, dynamic> _ayar(Map<String, dynamic> ayarlar, String key) =>
      Map<String, dynamic>.from(ayarlar[key] as Map? ?? const {});

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
      final bayram = entries.where(
          (e) => e['baslik'] == 'Ramazan Bayramı' && e['yil'] == giris['yil']);
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

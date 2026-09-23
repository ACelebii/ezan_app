// Bildirimlerin gerçek telefonda tam zamanında çıkıp çıkmadığını ölçer.
//
// Çalıştırmadan önce (uygulama telefona bir kez kurulduktan sonra) izinler
// verilmelidir; yoksa test bunu söyleyip durur:
//   adb shell pm grant com.acelebi.ezanvakti android.permission.POST_NOTIFICATIONS
//   adb shell appops set com.acelebi.ezanvakti SCHEDULE_EXACT_ALARM allow
//
// Test yaklaşık 1-5 dakika sürer (gerçek saati bekler). Telefonun ekranı açık
// ve USB bağlı kalmalıdır.
import 'package:ezan_vakti_uygulamasi/core/services/notification_service.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/il_kodlari.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_servisi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_tercihi.dart';
import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/bildirim_girdisi.dart';
import 'package:ezan_vakti_uygulamasi/main.dart' show callbackDispatcher;
import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/reminder_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

const _tamId = 9001;
const _yaklasikId = 9002;
const _iptalId = 9003;
const _ses = 'varsayilan';

/// [an]ı bir sonraki tam saniyeye yuvarlar. flutter_local_notifications zamanı
/// Android'e `toIso8601String().split('.')[0]` ile gönderir; kesirli saniye
/// atılır ve bildirim 0-1 sn erken çıkar. Gerçek vakitler tam dakikadır (saniye
/// 0), yani bu sapma üretimde oluşmaz; testte de aynı koşulu sağlıyoruz.
DateTime _tamSaniye(DateTime an) => DateTime.fromMillisecondsSinceEpoch(
    ((an.millisecondsSinceEpoch + 999) ~/ 1000) * 1000,
    isUtc: true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final servis = NotificationService.instance;
  final eklenti = FlutterLocalNotificationsPlugin();

  Future<Set<int>> ekrandakiler() async {
    final android = eklenti.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()!;
    return {
      for (final n in await android.getActiveNotifications())
        if (n.id != null) n.id!,
    };
  }

  Future<Set<int>> bekleyenler() async => {
        for (final n in await eklenti.pendingNotificationRequests()) n.id,
      };

  setUpAll(() async {
    await servis.initialize();
    expect(await Permission.notification.isGranted, isTrue,
        reason: 'Bildirim izni yok. Çalıştırın: adb shell pm grant '
            'com.acelebi.ezanvakti android.permission.POST_NOTIFICATIONS');
    expect(await servis.tamZamanliBildirimIzniVar(), isTrue,
        reason: 'Tam zamanlı alarm izni yok. Çalıştırın: adb shell appops set '
            'com.acelebi.ezanvakti SCHEDULE_EXACT_ALARM allow');
    for (final id in [_tamId, _yaklasikId, _iptalId]) {
      await servis.cancel(id);
    }
  });

  tearDownAll(() async {
    for (final id in [_tamId, _yaklasikId, _iptalId]) {
      await servis.cancel(id);
    }
  });

  test(
    'tam zamanlı bildirim, konumun saat dilimi telefonunkinden farklı olsa da '
    'dakikasında çıkar',
    () async {
      final an =
          _tamSaniye(DateTime.now().toUtc().add(const Duration(seconds: 40)));
      // Telefonun saat diliminden GERÇEKTEN farklı bir dilim seç (telefon
      // New York'ta olabilir, İstanbul'da da): yalnızca mutlak an önemli.
      final farkliDilim = DateTime.now().timeZoneOffset.inHours == 9
          ? 'Pacific/Honolulu'
          : 'Asia/Tokyo';
      debugPrint('ÖLÇÜM telefon: ${DateTime.now().timeZoneName} '
          '(UTC${DateTime.now().timeZoneOffset.inHours}), konum dilimi: $farkliDilim');
      await servis.scheduleAt(
        id: _tamId,
        title: 'Test: tam zamanlı',
        body: 'Saat dilimi: $farkliDilim',
        zaman: tz.TZDateTime.from(an, tz.getLocation(farkliDilim)),
        soundKey: _ses,
        tamZamanli: true,
      );
      // Karşılaştırma için aynı ana bir de "yaklaşık" bildirim.
      await servis.scheduleAt(
        id: _yaklasikId,
        title: 'Test: yaklaşık',
        body: 'inexactAllowWhileIdle',
        zaman: tz.TZDateTime.from(an, tz.getLocation('Europe/Istanbul')),
        soundKey: _ses,
        tamZamanli: false,
      );
      expect(await bekleyenler(), containsAll([_tamId, _yaklasikId]));

      final goruldu = <int, DateTime>{};
      final sinir = an.add(const Duration(minutes: 4));
      while (DateTime.now().isBefore(sinir) &&
          !(goruldu.containsKey(_tamId) && goruldu.containsKey(_yaklasikId))) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final simdi = DateTime.now();
        for (final id in await ekrandakiler()) {
          goruldu.putIfAbsent(id, () => simdi);
        }
        // Tam zamanlı geldiyse ve yaklaşık için 1 dakikadan fazla beklendiyse
        // döngüyü uzatma: yaklaşık gecikmesi bilgilendirme amaçlı.
        if (goruldu.containsKey(_tamId) &&
            simdi.isAfter(goruldu[_tamId]!.add(const Duration(minutes: 1)))) {
          break;
        }
      }

      double gecikme(int id) =>
          goruldu[id]!.difference(an).inMilliseconds / 1000;

      expect(goruldu, contains(_tamId), reason: 'Tam zamanlı bildirim çıkmadı.');
      debugPrint('ÖLÇÜM tam zamanlı gecikme: '
          '${gecikme(_tamId).toStringAsFixed(2)} sn');
      debugPrint(goruldu.containsKey(_yaklasikId)
          ? 'ÖLÇÜM yaklaşık gecikme: '
              '${gecikme(_yaklasikId).toStringAsFixed(2)} sn'
          : 'ÖLÇÜM yaklaşık: tam zamanlıdan sonra 1 dk içinde çıkmadı');

      // Erken çıkmamalı (250 ms yoklama payı), 5 saniyeden fazla da geç kalmamalı.
      expect(gecikme(_tamId), inInclusiveRange(-0.5, 5));
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );

  test('geçmiş bir an verilirse aynı id\'li bekleyen bildirim iptal edilir',
      () async {
    await servis.scheduleAt(
      id: _iptalId,
      title: 'Test: iptal',
      body: 'Bu bildirim iptal edilecek',
      zaman: tz.TZDateTime.from(
          DateTime.now().add(const Duration(minutes: 30)), tz.UTC),
      soundKey: _ses,
      tamZamanli: true,
    );
    expect(await bekleyenler(), contains(_iptalId));

    await servis.scheduleAt(
      id: _iptalId,
      title: 'Test: iptal',
      body: 'Geçmiş an',
      zaman: tz.TZDateTime.from(
          DateTime.now().subtract(const Duration(minutes: 1)), tz.UTC),
      soundKey: _ses,
      tamZamanli: true,
    );
    expect(await bekleyenler(), isNot(contains(_iptalId)));
  });

  test(
    'zamanlayıcı uçtan uca: eski kurulum temizlenir, ikinci tur değişiklik '
    'yapmaz, silinen bildirim geri gelir, ezan dakikasında çalar',
    () async {
      final konum = kayittanKonum({'isim': 'İstanbul'})!;
      final bugun = VakitServisi().bugun(konum);
      final simdi = DateTime.now().toUtc();
      final ogle0 = _tamSaniye(simdi.add(const Duration(seconds: 40)));

      // 16 gün: her gün, 0. günün vakitlerinin tam N gün sonrası.
      final gunler = [
        for (var i = 0; i < 16; i++)
          GunlukVakit(
            tarih: bugun.add(Duration(days: i)),
            kaynak: VakitKaynagi.diyanet,
            saatler: {for (final v in Vakit.values) v: '00:00'},
            anlar: {
              Vakit.imsak: simdi.subtract(const Duration(hours: 3)),
              Vakit.gunes: simdi.subtract(const Duration(hours: 2)),
              Vakit.ogle: ogle0,
              Vakit.ikindi: simdi.add(const Duration(hours: 3)),
              Vakit.aksam: simdi.add(const Duration(hours: 6)),
              Vakit.yatsi: simdi.add(const Duration(hours: 9)),
            }.map((v, an) => MapEntry(v, an.add(Duration(days: i)))),
          ),
      ];
      final plan = ReminderScheduler.planla(
        gunler: gunler,
        bugun: bugun,
        simdi: simdi,
        hatirlaticilar: const {},
        vakitEzanAyarlari: {
          'ogle': {'enabled': true, 'sound': _ses},
          'ikindi': {'onceEnabled': true, 'onceDakika': 30, 'onceSound': _ses},
        },
        vaktindeKilAyarlari: const {},
      );
      expect(plan, hasLength(28)); // 14 gün x (öğle ezanı + ikindi uyarısı)
      final planIdleri = {for (final b in plan) b.id};

      // Eski kurulumun bıraktığı bildirimleri taklit et (payload'sız).
      final eskiIdler = [101, 229, 300, 341, 355, 407];
      for (final id in eskiIdler) {
        await servis.scheduleAt(
          id: id,
          title: 'Eski tekrarlı bildirim',
          body: 'temizlenmeli',
          zaman: tz.TZDateTime.from(
              DateTime.now().add(const Duration(days: 3)), tz.UTC),
          soundKey: _ses,
          tamZamanli: true,
        );
      }
      expect(await bekleyenler(), containsAll(eskiIdler));

      // 1. tur: eskiler silinir, 28 bildirim kurulur.
      await ReminderScheduler.uygula(plan, konum);
      final birinci = await bekleyenler();
      expect(birinci.intersection(eskiIdler.toSet()), isEmpty,
          reason: 'Eski id numaraları iptal edilmedi.');
      expect(birinci.intersection(planIdleri), planIdleri);

      // 2. tur: hiçbir şey değişmedi, bildirimler aynı payload'la duruyor.
      final payload1 = await servis.bekleyenler();
      final sw = Stopwatch()..start();
      await ReminderScheduler.uygula(plan, konum);
      final ikinciSure = sw.elapsedMilliseconds;
      final payload2 = await servis.bekleyenler();
      expect(payload2, payload1);
      debugPrint('ÖLÇÜM 2. tur (değişiklik yok): $ikinciSure ms');
      expect(ikinciSure, lessThan(1500),
          reason: '28 bildirimi yeniden kurmuş gibi yavaş.');

      // Zorla durdurma gibi: bir bildirim sistemden silinir; 3. tur geri getirir.
      final silinen = plan[5].id;
      await servis.cancel(silinen);
      expect(await bekleyenler(), isNot(contains(silinen)));
      await ReminderScheduler.uygula(plan, konum);
      expect(await bekleyenler(), contains(silinen));

      // Bugünün öğle ezanı dakikasında çalmalı (plan.first = bugünün ezanı).
      final ezanId = plan.first.id;
      DateTime? goruldu;
      final sinir = ogle0.add(const Duration(seconds: 30));
      while (goruldu == null && DateTime.now().isBefore(sinir)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final t = DateTime.now();
        if ((await ekrandakiler()).contains(ezanId)) goruldu = t;
      }
      expect(goruldu, isNotNull, reason: 'Öğle ezanı çalmadı.');
      final gecikme = goruldu!.difference(ogle0).inMilliseconds / 1000;
      debugPrint('ÖLÇÜM zamanlayıcının kurduğu ezan gecikmesi: '
          '${gecikme.toStringAsFixed(2)} sn');
      expect(gecikme, inInclusiveRange(-0.5, 5));

      // Temizlik: plansız uygulama, yönetilen bütün bildirimleri iptal eder.
      await ReminderScheduler.uygula(const [], konum);
      expect((await bekleyenler()).intersection(planIdleri), isEmpty);
      await servis.cancel(ezanId);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'arka plan görevi (WorkManager): uygulama arayüzü olmadan, kayıtlı girdiden '
    'bildirimleri kurar',
    () async {
      // Pil tasarrufu açıksa (Ayarlar > Pil) WorkManager arka plan işlerini
      // bekletir ve bu test zaman aşımına uğrar.
      final konum = kayittanKonum({'isim': 'İstanbul'})!;
      Future<Set<int>> bizimkiler() async => (await bekleyenler())
          .where((id) => id >= 1000 && id < 1500)
          .toSet();

      // Temiz başla: yönetilen bütün bildirimler iptal.
      await ReminderScheduler.uygula(const [], konum);
      expect(await bizimkiler(), isEmpty);

      // Ön plan, girdi kaydını bırakır (gerçekte her planlamada yapılır):
      // yalnızca öğle ezanı açık.
      await ReminderScheduler.girdiyiKaydet(BildirimGirdisi(
        konum: konum,
        tercih: const VakitTercihi(),
        hatirlaticilar: const {},
        vakitEzanAyarlari: {
          'ogle': {'enabled': true, 'sound': _ses},
        },
        vaktindeKilAyarlari: const {},
      ));

      // Uygulamanın gerçek görev yönlendiricisiyle tek seferlik iş: WorkManager
      // bunu ayrı bir arka plan izolatında hemen çalıştırır.
      await Workmanager().initialize(callbackDispatcher);
      await Workmanager().registerOneOffTask(
        'bildirim-yenile-test',
        ReminderScheduler.arkaPlanGorevi,
        constraints: Constraints(networkType: NetworkType.connected),
      );

      final baslangic = DateTime.now();
      Set<int> kurulanlar = {};
      while (DateTime.now().difference(baslangic) <
          const Duration(seconds: 120)) {
        await Future<void>.delayed(const Duration(seconds: 2));
        kurulanlar = await bizimkiler();
        if (kurulanlar.isNotEmpty) break;
      }
      final sure = DateTime.now().difference(baslangic).inSeconds;
      debugPrint('ÖLÇÜM arka plan görevi ilk bildirimi $sure sn içinde kurdu: '
          '${kurulanlar.length} bildirim');

      expect(kurulanlar, isNotEmpty, reason: 'Arka plan görevi bildirim kurmadı.');
      // Öğle ezanı: 1000 + 2*14 + gün dilimi = 1028..1041; hepsi bu aralıkta.
      expect(kurulanlar.every((id) => id >= 1028 && id <= 1041), isTrue,
          reason: '$kurulanlar');
      expect(kurulanlar.length, inInclusiveRange(12, 14));

      // Temizlik.
      await ReminderScheduler.uygula(const [], konum);
      await Workmanager().cancelByUniqueName('bildirim-yenile-test');
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

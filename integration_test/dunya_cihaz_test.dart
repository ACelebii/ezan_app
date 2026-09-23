// Dünya şehri (Los Angeles) uçtan uca, gerçek telefonda ve gerçek internetle.
//
// Amaç: telefonun saat dilimi ne olursa olsun (test telefonu New York'ta),
// seçilen yerin vakitleri, geri sayımı ve bildirimleri O YERİN saatine göre
// olmalı. Beklenen değerler kodun kendi hesabından değil, Diyanet'in
// yayınladığı "HH:mm" metinlerinden bağımsız olarak türetilir.
//
// Bildirim izni gerekir (bkz. bildirim_cihaz_test.dart).
import 'package:ezan_vakti_uygulamasi/core/services/notification_service.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/diyanet_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_servisi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_tercihi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/yer_bulucu.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/zaman_dilimi.dart';
import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/bildirim_girdisi.dart';
import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/reminder_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/timezone.dart' as tz;

String _hhmm(tz.TZDateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Konum konum;
  late List<GunlukVakit> gunler;
  late tz.Location la;
  final servis = VakitServisi();

  setUpAll(() async {
    zamanDilimleriniHazirla();
    la = tz.getLocation('America/Los_Angeles');

    // Ülke → eyalet → ilçe: uygulamadaki seçim akışının aynısı, adlara göre.
    final diyanet = DiyanetKaynagi();
    final ulke = (await diyanet.ulkeler())
        .firstWhere((u) => u.adEn.trim() == 'UNITED STATES');
    final eyalet = (await diyanet.sehirler(ulke.id))
        .firstWhere((s) => s.adEn.trim() == 'CALIFORNIA');
    final ilce = (await diyanet.ilceler(eyalet.id))
        .firstWhere((i) => i.adEn.trim() == 'LOS ANGELES');

    konum = await YerBulucu().bul(ulke: ulke, sehir: eyalet, ilce: ilce);
    gunler = await servis.vakitleriGetir(konum);
  });

  test('konum: koordinat ve saat dilimi Los Angeles\'a ait', () {
    debugPrint('ÖLÇÜM konum: ${konum.ad}, ${konum.ulke}, ${konum.saatDilimi}, '
        '${konum.enlem}, ${konum.boylam}, Diyanet ilçe ${konum.diyanetIlceId}');
    expect(konum.saatDilimi, 'America/Los_Angeles');
    expect(konum.enlem, inInclusiveRange(33.5, 34.5));
    expect(konum.boylam, inInclusiveRange(-118.8, -117.8));
    expect(gunler.first.kaynak, VakitKaynagi.diyanet);
  });

  test('vakit anları, Diyanet\'in yerel "HH:mm" metniyle Los Angeles saatinde birebir',
      () {
    final simdi = DateTime.now();
    debugPrint('ÖLÇÜM telefonun saat dilimi: ${simdi.timeZoneName} '
        '(UTC${simdi.timeZoneOffset.inMinutes / 60}); '
        'Los Angeles: ${tz.TZDateTime.now(la).timeZoneName}');

    for (final gun in gunler) {
      for (final v in Vakit.values) {
        expect(_hhmm(tz.TZDateTime.from(gun.anlar[v]!, la)), gun.saatler[v],
            reason: '${gun.tarih} ${v.ad}');
      }
    }
    final bugun = gunler.firstWhere((g) => g.tarih == servis.bugun(konum));
    debugPrint('ÖLÇÜM Los Angeles bugün (${bugun.tarih.toString().substring(0, 10)}): '
        '${Vakit.values.map((v) => '${v.ad} ${bugun.saatler[v]}').join('  ')}');
  });

  test('geri sayım: sıradaki vakit, Los Angeles saatinde bağımsız hesapla aynı', () {
    final simdi = DateTime.now().toUtc();
    final durum = vakitDurumu(gunler, simdi)!;

    // Bağımsız hesap: Diyanet'in HH:mm metinlerini Los Angeles saatinde an yap.
    DateTime? beklenen;
    Vakit? beklenenVakit;
    for (final gun in gunler) {
      for (final v in Vakit.values) {
        final s = saatDakikaCoz(gun.saatler[v]!)!;
        final an = tz.TZDateTime(
                la, gun.tarih.year, gun.tarih.month, gun.tarih.day, s.saat, s.dakika)
            .toUtc();
        if (an.isAfter(simdi) && (beklenen == null || an.isBefore(beklenen))) {
          beklenen = an;
          beklenenVakit = v;
        }
      }
    }
    final kalan = durum.siradakiAn.difference(simdi);
    debugPrint('ÖLÇÜM Los Angeles\'ta şu an ${_hhmm(tz.TZDateTime.now(la))}; '
        'sıradaki ${durum.siradaki.ad}, kalan ${kalan.inMinutes} dk');
    expect(durum.siradaki, beklenenVakit);
    expect(durum.siradakiAn, beklenen);
    expect(kalan, greaterThan(Duration.zero));
    expect(kalan, lessThan(const Duration(hours: 24)));
  });

  test('bildirimler: 14 günün öğle ezanı, her biri Los Angeles öğle saatinde kurulur',
      () async {
    await NotificationService.instance.initialize();
    final girdi = BildirimGirdisi(
      konum: konum,
      tercih: const VakitTercihi(),
      hatirlaticilar: const {},
      vakitEzanAyarlari: {
        'ogle': {'enabled': true, 'sound': 'varsayilan'},
      },
      vaktindeKilAyarlari: const {},
    );
    try {
      await ReminderScheduler.girdiyiUygula(girdi, servis);
      final bekleyen = await NotificationService.instance.bekleyenler();
      // Öğle ezanı: 1000 + 2*14 + gün dilimi.
      final ogleler = [
        for (final e in bekleyen.entries)
          if (e.key >= 1028 && e.key <= 1041) e.value!,
      ];
      expect(ogleler.length, inInclusiveRange(12, 14));

      for (final payload in ogleler) {
        final an = tz.TZDateTime.fromMillisecondsSinceEpoch(
            la, int.parse(payload.split('|').first));
        final gun = gunler.firstWhere(
            (g) => g.tarih == DateTime.utc(an.year, an.month, an.day),
            orElse: () => throw StateError('Vakit listesinde ${an.toString().substring(0, 10)} yok'));
        expect(_hhmm(an), gun.saatler[Vakit.ogle],
            reason: 'Bildirim ${an.toString().substring(0, 16)} (LA) için Diyanet '
                'öğle saati ${gun.saatler[Vakit.ogle]}');
      }
      debugPrint('ÖLÇÜM ${ogleler.length} öğle bildirimi, hepsi Diyanet\'in '
          'Los Angeles öğle saatinde kuruldu.');
    } finally {
      await ReminderScheduler.uygula(const [], konum); // temizlik
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}

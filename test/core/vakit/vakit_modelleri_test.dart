import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';

/// İstanbul (UTC+3) için test günü oluşturur. Saatler "HH:mm" olarak verilir,
/// gerçek anlar UTC'ye çevrilerek hesaplanır.
GunlukVakit _gun(int yil, int ay, int gun, List<String> saatler) {
  return GunlukVakit(
    tarih: DateTime.utc(yil, ay, gun),
    kaynak: VakitKaynagi.diyanet,
    saatler: {
      for (var i = 0; i < Vakit.values.length; i++) Vakit.values[i]: saatler[i]
    },
    anlar: {
      for (var i = 0; i < Vakit.values.length; i++)
        Vakit.values[i]: DateTime.utc(
                yil,
                ay,
                gun,
                int.parse(saatler[i].substring(0, 2)),
                int.parse(saatler[i].substring(3, 5)))
            .subtract(const Duration(hours: 3)),
    },
  );
}

void main() {
  // Diyanet, İstanbul, 19 ve 20 Eylül 2026.
  final gun19 =
      _gun(2026, 9, 19, ['05:15', '06:41', '13:03', '16:31', '19:15', '20:35']);
  final gun20 =
      _gun(2026, 9, 20, ['05:17', '06:42', '13:03', '16:29', '19:13', '20:33']);

  // İstanbul saatiyle bir anı UTC olarak verir.
  DateTime ist(int ay, int gun, int saat, int dakika, [int saniye = 0]) =>
      DateTime.utc(2026, ay, gun, saat, dakika, saniye)
          .subtract(const Duration(hours: 3));

  group('saatDakikaCoz', () {
    test('Diyanet ve Aladhan biçimlerini okur', () {
      expect(saatDakikaCoz('05:15'), (saat: 5, dakika: 15));
      expect(saatDakikaCoz('05:15 (+03)'), (saat: 5, dakika: 15));
      expect(saatDakikaCoz('0:07'), (saat: 0, dakika: 7));
      expect(saatDakikaCoz('23:59'), (saat: 23, dakika: 59));
    });

    test('geçersiz metinlerde null döner', () {
      expect(saatDakikaCoz('24:00'), isNull);
      expect(saatDakikaCoz('12:60'), isNull);
      expect(saatDakikaCoz('--:--'), isNull);
      expect(saatDakikaCoz(''), isNull);
    });
  });

  group('gunAnahtari', () {
    test('iki yöne de çevrilir', () {
      expect(gunAnahtari(DateTime.utc(2026, 9, 5)), '2026-09-05');
      expect(gunAnahtariniCoz('2026-09-05'), DateTime.utc(2026, 9, 5));
    });

    test('taşan ya da bozuk tarihleri reddeder', () {
      expect(gunAnahtariniCoz('2026-02-31'), isNull);
      expect(gunAnahtariniCoz('19.09.2026'), isNull);
    });
  });

  group('vakitDurumu', () {
    test('öğle ile ikindi arasında sıradaki ikindidir', () {
      final durum = vakitDurumu([gun19, gun20], ist(9, 19, 15, 47, 20))!;
      expect(durum.simdiki, Vakit.ogle);
      expect(durum.siradaki, Vakit.ikindi);
      expect(durum.kalan(ist(9, 19, 15, 47, 20)),
          const Duration(minutes: 43, seconds: 40));
    });

    test('yatsıdan sonra sıradaki, ertesi günün imsakidir', () {
      final durum = vakitDurumu([gun19, gun20], ist(9, 19, 23, 0))!;
      expect(durum.simdiki, Vakit.yatsi);
      expect(durum.siradaki, Vakit.imsak);
      expect(durum.siradakiAn, ist(9, 20, 5, 17));
    });

    test('gece yarısından sonra hâlâ önceki günün yatsısındayız', () {
      final durum = vakitDurumu([gun19, gun20], ist(9, 20, 1, 30))!;
      expect(durum.simdiki, Vakit.yatsi);
      expect(durum.simdikiBaslangic, ist(9, 19, 20, 35));
      expect(durum.siradaki, Vakit.imsak);
    });

    test('günler karışık sırayla verilse de doğru çalışır', () {
      final durum = vakitDurumu([gun20, gun19], ist(9, 19, 12, 0))!;
      expect(durum.simdiki, Vakit.gunes);
      expect(durum.siradaki, Vakit.ogle);
    });

    test('tam vakit anında sıradaki bir sonraki vakittir', () {
      final durum = vakitDurumu([gun19], ist(9, 19, 13, 3))!;
      expect(durum.simdiki, Vakit.ogle);
      expect(durum.siradaki, Vakit.ikindi);
    });

    test('veri yetmezse null döner', () {
      expect(vakitDurumu([gun19], ist(9, 19, 22, 0)), isNull);
      expect(vakitDurumu(const [], ist(9, 19, 12, 0)), isNull);
    });

    test('ilerleme 0 ile 1 arasında kalır', () {
      final durum = vakitDurumu([gun19], ist(9, 19, 14, 47))!;
      // Öğle 13:03 → İkindi 16:31 (208 dk); 14:47'de 104 dk geçmiş = yarısı.
      expect(durum.ilerleme(ist(9, 19, 14, 47)), closeTo(0.5, 0.0001));
      expect(durum.ilerleme(ist(9, 19, 12, 0)), 0);
      expect(durum.ilerleme(ist(9, 19, 17, 0)), 1);
    });
  });

  group('JSON', () {
    test('GunlukVakit kaydedilip aynen geri okunur', () {
      final okunan = GunlukVakit.fromJson(gun19.toJson());
      expect(okunan.tarih, gun19.tarih);
      expect(okunan.kaynak, gun19.kaynak);
      expect(okunan.saatler, gun19.saatler);
      expect(okunan.anlar, gun19.anlar);
    });

    test('Konum kaydedilip aynen geri okunur', () {
      const konum = Konum(
          ad: 'İstanbul', saatDilimi: 'Europe/Istanbul', diyanetIlceId: 9541);
      final okunan = Konum.fromJson(konum.toJson());
      expect(okunan.ad, 'İstanbul');
      expect(okunan.ulke, 'Türkiye');
      expect(okunan.diyanetIlceId, 9541);
      expect(okunan.koordinatVar, isFalse);
      expect(okunan.anahtar, 'diyanet-9541');
    });

    test('koordinatlı konumun anahtarı koordinattan oluşur', () {
      const konum = Konum(
          ad: 'Atlanta',
          ulke: 'ABD',
          saatDilimi: 'America/New_York',
          enlem: 33.7490,
          boylam: -84.3880);
      expect(konum.anahtar, 'koordinat-33.749,-84.388');
    });
  });

  group('GunlukVakit.duzelt / vakitiAl', () {
    test('duzelt: saat metni ve gerçek an aynı miktarda kayar', () {
      final duzeltilmis = gun19.duzelt({Vakit.aksam: 1, Vakit.ogle: -3});

      expect(duzeltilmis.saatler[Vakit.aksam], '19:16');
      expect(duzeltilmis.saatler[Vakit.ogle], '13:00');
      expect(duzeltilmis.anlar[Vakit.aksam],
          gun19.anlar[Vakit.aksam]!.add(const Duration(minutes: 1)));
      expect(duzeltilmis.anlar[Vakit.ogle],
          gun19.anlar[Vakit.ogle]!.subtract(const Duration(minutes: 3)));
      // Dokunulmayanlar aynı; tarih ve kaynak korunur.
      expect(duzeltilmis.saatler[Vakit.imsak], '05:15');
      expect(duzeltilmis.anlar[Vakit.imsak], gun19.anlar[Vakit.imsak]);
      expect(duzeltilmis.tarih, gun19.tarih);
      expect(duzeltilmis.kaynak, gun19.kaynak);
    });

    test('duzelt: sıfır ya da boş düzeltme aynı nesneyi döner', () {
      expect(identical(gun19.duzelt({}), gun19), isTrue);
      expect(identical(gun19.duzelt({Vakit.aksam: 0}), gun19), isTrue);
    });

    test('duzelt: gece yarısını geçince saat metni 24 saate sarar', () {
      final gec = _gun(
          2026, 9, 19, ['05:15', '06:41', '13:03', '16:31', '19:15', '23:50']);

      expect(gec.duzelt({Vakit.yatsi: 15}).saatler[Vakit.yatsi], '00:05');
      expect(
          _gun(2026, 9, 19, [
            '00:05',
            '06:41',
            '13:03',
            '16:31',
            '19:15',
            '20:35'
          ]).duzelt({Vakit.imsak: -10}).saatler[Vakit.imsak],
          '23:55');
    });

    test('vakitiAl: yalnızca istenen vakit değişir', () {
      final hanefi = _gun(
          2026, 9, 19, ['09:99', '09:99', '09:99', '17:23', '09:99', '09:99']);

      final sonuc = gun19.vakitiAl(Vakit.ikindi, hanefi);

      expect(sonuc.saatler[Vakit.ikindi], '17:23');
      expect(sonuc.anlar[Vakit.ikindi], hanefi.anlar[Vakit.ikindi]);
      for (final v in Vakit.values.where((v) => v != Vakit.ikindi)) {
        expect(sonuc.saatler[v], gun19.saatler[v], reason: v.name);
        expect(sonuc.anlar[v], gun19.anlar[v], reason: v.name);
      }
    });
  });
}

import 'package:ezan_vakti_uygulamasi/core/models/city_list.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/il_kodlari.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('tablo, uygulamanın şehir listesindeki 81 ilin tamamını içerir', () {
    expect(diyanetIlceKodlari, hasLength(81));
    expect(diyanetIlceKodlari.keys.toSet(), CityData.allCities.toSet());
  });

  test('ilçe kodları benzersizdir', () {
    expect(diyanetIlceKodlari.values.toSet(), hasLength(81));
  });

  test('bilinen kodlar planla uyuşur', () {
    expect(diyanetIlceKodlari['İstanbul'], 9541);
    expect(diyanetIlceKodlari['Ankara'], 9206);
    expect(diyanetIlceKodlari['Hatay'], 20089); // tek 5 haneli kod
    expect(diyanetIlceKodlari['Iğdır'], 9522); // noktasız ı
  });

  group('kayittanKonum', () {
    test('şehir seçim ekranının yazdığı kayıt (koordinatsız)', () {
      final konum = kayittanKonum({
        'isim': 'Şanlıurfa',
        'sehir': 'Türkiye',
        'tur': 'Diyanet Takvimi',
        'secili': 'true',
      })!;

      expect(konum.ad, 'Şanlıurfa');
      expect(konum.ulke, 'Türkiye');
      expect(konum.saatDilimi, 'Europe/Istanbul');
      expect(konum.diyanetIlceId, 9831);
      expect(konum.koordinatVar, isFalse);
      expect(konum.anahtar, 'diyanet-9831');
    });

    test('varsayılan İstanbul kaydı koordinatını korur', () {
      final konum = kayittanKonum({
        'isim': 'İstanbul',
        'sehir': 'Türkiye',
        'lat': 41.0082,
        'lon': 28.9784,
        'secili': 'true',
      })!;

      expect(konum.diyanetIlceId, 9541);
      expect((konum.enlem, konum.boylam), (41.0082, 28.9784));
      // Önbellek anahtarı koordinatın olup olmamasından etkilenmez.
      expect(konum.anahtar, 'diyanet-9541');
    });

    test('tam sayı koordinat da kabul edilir', () {
      final konum = kayittanKonum({'isim': 'Van', 'lat': 39, 'lon': 43})!;

      expect((konum.enlem, konum.boylam), (39.0, 43.0));
    });

    test('yalnızca biri varsa koordinat kullanılmaz', () {
      final konum = kayittanKonum({'isim': 'Van', 'lat': 39.0})!;

      expect(konum.koordinatVar, isFalse);
    });

    test('dünya listesinden eklenen kayıt: tam konum önceliklidir', () {
      const los = Konum(
          ad: 'Los Angeles',
          ulke: 'Amerika Birleşik Devletleri',
          saatDilimi: 'America/Los_Angeles',
          diyanetIlceId: 8626,
          enlem: 34.05,
          boylam: -118.24);
      // JSON gidiş-dönüşü (misafir ayarları / Firestore) sonrası da çalışır.
      final kayit = {'isim': 'Los Angeles', 'konum': los.toJson()};

      final konum = kayittanKonum(kayit)!;

      expect(konum.saatDilimi, 'America/Los_Angeles');
      expect(konum.diyanetIlceId, 8626);
      expect(konum.anahtar, los.anahtar);
    });

    test(
        'yabancı yerin adı Türkiye tablosundaki bir ille aynı olsa da tablo değil kayıt kullanılır',
        () {
      const van = Konum(
          ad: 'Van',
          ulke: 'Bir Ülke',
          saatDilimi: 'Europe/Berlin',
          diyanetIlceId: 1,
          enlem: 1,
          boylam: 1);

      final konum = kayittanKonum({'isim': 'Van', 'konum': van.toJson()})!;

      expect(konum.diyanetIlceId, 1);
      expect(konum.saatDilimi, 'Europe/Berlin');
    });

    test('bozuk konum kaydı (geçersiz saat dilimi, eksik alan) null döner', () {
      expect(
          kayittanKonum({
            'isim': 'X',
            'konum': {
              'ad': 'X',
              'saatDilimi': 'Mars/Olympus',
              'diyanetIlceId': 1
            }
          }),
          isNull);
      expect(
          kayittanKonum({
            'isim': 'X',
            'konum': {'ad': 'X'}
          }),
          isNull);
      expect(kayittanKonum({'isim': 'İstanbul', 'konum': 'bozuk'}), isNotNull,
          reason: 'Map olmayan konum yok sayılır, il tablosuna düşülür');
    });

    test('bilinmeyen ya da bozuk kayıt null döner', () {
      expect(kayittanKonum({'isim': 'Atlantis'}), isNull);
      expect(kayittanKonum({'isim': 'istanbul'}), isNull); // büyük/küçük harf
      expect(kayittanKonum({'isim': 42}), isNull);
      expect(kayittanKonum({}), isNull);
    });

    test('81 ilin hepsi için geçerli bir Konum ve saat dilimi çıkar', () {
      tz_data.initializeTimeZones();
      for (final il in CityData.allCities) {
        final konum = kayittanKonum({'isim': il});
        expect(konum, isNotNull, reason: il);
        expect(() => tz.getLocation(konum!.saatDilimi), returnsNormally);
      }
    });
  });
}

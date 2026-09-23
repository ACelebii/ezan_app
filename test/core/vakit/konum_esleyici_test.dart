import 'package:ezan_vakti_uygulamasi/core/vakit/diyanet_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/konum_esleyici.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/yer_bulucu.dart';
import 'package:flutter_test/flutter_test.dart';

DiyanetYeri _y(int id, String ad, [String? adEn]) =>
    DiyanetYeri(id: id, ad: ad, adEn: adEn ?? ad);

/// Diyanet listelerinin küçük bir kesiti (adlar gerçek yazımlarıyla).
class _SahteDiyanet extends Fake implements DiyanetKaynagi {
  bool hataVer = false;

  final _ulkeler = [
    _y(2, 'TÜRKİYE'),
    _y(13, 'ALMANYA', 'GERMANY'),
    _y(33, 'AMERİKA BİRLEŞİK DEVLETLERİ', 'UNITED STATES'),
    _y(116, 'JAPONYA', 'JAPAN'),
    _y(60, 'BİRLEŞİK KRALLIK', 'UNITED KINGDOM'),
    _y(70, 'GİNE', 'GUINEA'),
    _y(71, 'GİNE BİSSAU', 'GUINEA-BISSAU'),
  ];

  @override
  Future<List<DiyanetYeri>> ulkeler() async {
    if (hataVer) throw DiyanetHatasi('kapalı');
    return _ulkeler;
  }

  @override
  Future<List<DiyanetYeri>> sehirler(int ulkeId) async => switch (ulkeId) {
        2 => [
            _y(539, 'İSTANBUL', 'ISTANBUL'),
            _y(506, 'ANKARA'),
            _y(520, 'IĞDIR', 'IGDIR')
          ],
        13 => [_y(130, 'BERLIN'), _y(131, 'BADEN WURTTEMBERG')],
        33 => [_y(585, 'CALIFORNIA'), _y(586, 'ALABAMA')],
        116 => [_y(1160, 'JAPAN')],
        60 => [_y(600, 'UNITED KINGDOM')],
        70 => [_y(700, 'GUINEA')],
        _ => [],
      };

  @override
  Future<List<DiyanetYeri>> ilceler(int sehirId) async => switch (sehirId) {
        539 => [
            _y(9540, 'KADIKÖY', 'KADIKOY'),
            _y(9542, 'ŞİŞLİ', 'SISLI'),
            _y(9541, 'İSTANBUL', 'ISTANBUL')
          ],
        506 => [
            _y(9206, 'ANKARA')
          ], // Çankaya listede yok: il merkezi kullanılmalı
        520 => [_y(9522, 'IĞDIR', 'IGDIR'), _y(9523, 'ARALIK', 'ARALIK')],
        130 => [_y(13001, 'BERLIN')],
        585 => [_y(8626, 'LOS ANGELES'), _y(8627, 'SAN DIEGO')],
        1160 => [_y(14707, 'ADACHI-KU'), _y(14708, 'ADA')],
        600 => [_y(6001, 'LONDON'), _y(6002, 'MANCHESTER')],
        _ => [],
      };
}

class _SahteYerBulucu extends Fake implements YerBulucu {
  _SahteYerBulucu(this.adres, {this.saatDilimi = 'Asia/Tokyo'});

  final Map<String, String> adres;
  final String saatDilimi;
  int saatDilimiSorgusu = 0;

  @override
  Future<Map<String, String>> adresBul(double enlem, double boylam) async =>
      adres;

  @override
  Future<String> saatDilimiBul(double enlem, double boylam) async {
    saatDilimiSorgusu++;
    return saatDilimi;
  }
}

Future<(dynamic, _SahteYerBulucu)> _bul(Map<String, String> adres,
    {String saatDilimi = 'Asia/Tokyo', _SahteDiyanet? diyanet}) async {
  final yer = _SahteYerBulucu(adres, saatDilimi: saatDilimi);
  final konum =
      await KonumEsleyici(yerBulucu: yer, diyanet: diyanet ?? _SahteDiyanet())
          .bul(35.0, 139.0);
  return (konum, yer);
}

void main() {
  group('Diyanet ilçesiyle eşleşenler (Diyanet saati)', () {
    test('Türkiye, ilçe var: Kadıköy → Diyanet ilçesi, saat dilimi sabit',
        () async {
      // Nominatim'in Kadıköy için döndürdüğü gerçek adres alanları (20.09.2026).
      final (konum, yer) = await _bul({
        'country': 'Turkey',
        'country_code': 'tr',
        'province': 'Istanbul',
        'region': 'Marmara Region',
        'town': 'Kadıköy',
        'suburb': 'Osmanağa Mahallesi',
      });

      expect(konum.ad, 'Kadıköy');
      expect(konum.diyanetIlceId, 9540);
      expect(konum.ulke, 'Türkiye');
      expect(konum.saatDilimi, 'Europe/Istanbul');
      // Koordinat GPS'in kendisi.
      expect((konum.enlem, konum.boylam), (35.0, 139.0));
      expect(yer.saatDilimiSorgusu, 0,
          reason: 'Türkiye için saat dilimi sorulmaz');
    });

    test('Türkiye, ilçe listede yoksa il merkezi (Çankaya → Ankara)', () async {
      final (konum, _) = await _bul({
        'country': 'Turkey',
        'country_code': 'tr',
        'province': 'Ankara',
        'city': 'Ankara',
        'town': 'Çankaya',
        'suburb': 'Remzi Oğuz Arık Mahallesi',
      });

      expect(konum.diyanetIlceId, 9206);
      expect(konum.ad, 'Ankara');
    });

    test(
        'Türkçe harf farkı: "Iğdır" (Nominatim) ↔ IĞDIR, "Istanbul" ↔ İSTANBUL',
        () async {
      final (konum, _) = await _bul({
        'country': 'Turkey',
        'country_code': 'tr',
        'province': 'Iğdır',
        'city': 'Iğdır',
        'city_district': 'Bağlar Mahallesi',
      });
      expect(konum.diyanetIlceId, 9522);
      expect(konum.ad, 'Iğdır');
    });

    test('ABD: eyalet + şehir tam eşleşir, saat dilimi Aladhan\'dan', () async {
      final (konum, yer) = await _bul({
        'country': 'United States',
        'country_code': 'us',
        'state': 'California',
        'county': 'Los Angeles County',
        'city': 'Los Angeles',
        'suburb': 'Downtown',
      }, saatDilimi: 'America/Los_Angeles');

      expect(konum.ad, 'Los Angeles');
      expect(konum.diyanetIlceId, 8626);
      expect(konum.ulke, 'Amerika Birleşik Devletleri');
      expect(konum.saatDilimi, 'America/Los_Angeles');
      expect(yer.saatDilimiSorgusu, 1);
    });

    test('Japonya: tek şehirli ülke, önek eşleşmesi ("Adachi" ↔ ADACHI-KU)',
        () async {
      final (konum, _) = await _bul({
        'country': 'Japan',
        'country_code': 'jp',
        'city': 'Adachi',
        'quarter': 'Chūōhonchō',
      });

      expect(konum.diyanetIlceId, 14707);
      expect(konum.ad, 'Adachi-Ku');
    });

    test('şehir devleti: şehir adı eyalet olarak da denenir (Berlin)',
        () async {
      final (konum, _) = await _bul({
        'country': 'Germany',
        'country_code': 'de',
        'city': 'Berlin',
        'suburb': 'Mitte',
      }, saatDilimi: 'Europe/Berlin');

      expect(konum.diyanetIlceId, 13001);
      expect(konum.saatDilimi, 'Europe/Berlin');
    });
  });

  group('eşleşme yok: yalnızca koordinat (Aladhan hesabı), tahmin yok', () {
    test('Diyanet listesinde adı olmayan yer (Londra: "City of Westminster")',
        () async {
      final (konum, _) = await _bul({
        'country': 'United Kingdom',
        'country_code': 'gb',
        'state': 'England',
        'city': 'City of Westminster',
        'suburb': 'Millbank',
      }, saatDilimi: 'Europe/London');

      expect(konum.diyanetIlceId, isNull);
      expect(konum.koordinatVar, isTrue);
      expect(konum.ad, 'City of Westminster');
      // Ülke Diyanet listesinde var: koordinatla bulunan yerin ülkesi de Türkçe.
      expect(konum.ulke, 'Birleşik Krallık');
      expect(konum.saatDilimi, 'Europe/London');
    });

    test('Diyanet\'in tanımadığı ülke', () async {
      final (konum, _) = await _bul({
        'country': 'Czechia',
        'country_code': 'cz',
        'city': 'Prague',
      }, saatDilimi: 'Europe/Prague');

      expect(konum.diyanetIlceId, isNull);
      expect(konum.ulke, 'Czechia',
          reason: 'Diyanet ülkeyi tanımıyorsa Nominatim\'in adı');
      expect(konum.ad, 'Prague');
      expect(konum.saatDilimi, 'Europe/Prague');
    });

    test('ülke eşleşmesi tam olmalı: "Guinea", "GUINEA-BISSAU" ile karışmaz',
        () async {
      final (konum, _) = await _bul({
        'country': 'Guinea',
        'country_code': 'gn',
        'city': 'Conakry',
      }, saatDilimi: 'Africa/Conakry');

      // Ülke doğru (GİNE) bulunur; ilçe listesi boş olduğundan yine de koordinat.
      expect(konum.ulke, 'Gine');
      expect(konum.diyanetIlceId, isNull);
    });

    test('önek yalnızca sözcük bütününde: "Ada" ↔ ADACHI-KU eşleşmez, ADA olur',
        () async {
      final (konum, _) = await _bul({
        'country': 'Japan',
        'country_code': 'jp',
        'city': 'Ada',
      });

      expect(konum.diyanetIlceId, 14708); // tam eşleşme (ADA), ADACHI-KU değil
    });

    test(
        'yalnızca koordinat konumunda Türkiye tanınır (ilçe/il yoksa bile saat dilimi sabit)',
        () async {
      final (konum, yer) = await _bul({
        'country': 'Turkey',
        'country_code': 'tr',
        'province': 'Bilinmeyen',
        'town': 'Köy',
      });

      expect(konum.diyanetIlceId, isNull);
      expect(konum.ulke, 'Türkiye');
      expect(konum.saatDilimi, 'Europe/Istanbul');
      expect(yer.saatDilimiSorgusu, 0);
    });
  });

  group('hatalar', () {
    test('adres boşsa (okyanus gibi) hata, uydurma ad yok', () async {
      expect(_bul({}), throwsA(isA<YerBulucuHatasi>()));
    });

    test('yalnızca ülke bilinip hiçbir yer adı yoksa hata', () async {
      expect(_bul({'country': 'Japan', 'country_code': 'jp'}),
          throwsA(isA<YerBulucuHatasi>()));
    });

    test('Diyanet\'e ulaşılamazsa hesaplanmış vakite SESSİZCE düşülmez',
        () async {
      final diyanet = _SahteDiyanet()..hataVer = true;

      expect(
          _bul({'country': 'Turkey', 'country_code': 'tr', 'town': 'Kadıköy'},
              diyanet: diyanet),
          throwsA(isA<YerBulucuHatasi>()));
    });
  });
}

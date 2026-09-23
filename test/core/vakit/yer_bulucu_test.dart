import 'package:ezan_vakti_uygulamasi/core/vakit/diyanet_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/yer_bulucu.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _abd = DiyanetYeri(
    id: 33, ad: 'AMERİKA BİRLEŞİK DEVLETLERİ', adEn: 'UNITED STATES');
const _kaliforniya = DiyanetYeri(id: 585, ad: 'CALIFORNIA', adEn: 'CALIFORNIA');
const _la = DiyanetYeri(id: 8626, ad: 'LOS ANGELES', adEn: 'LOS ANGELES');

const _turkiye = DiyanetYeri(id: 2, ad: 'TÜRKİYE', adEn: 'TÜRKİYE');
const _istanbul = DiyanetYeri(id: 539, ad: 'İSTANBUL', adEn: 'ISTANBUL');
const _kadikoy = DiyanetYeri(id: 9541, ad: 'KADIKÖY', adEn: 'KADIKOY');

// Gerçek yanıtlardan (20.09.2026): Nominatim Los Angeles, Aladhan meta.
const _laNominatim =
    '[{"lat":"34.0536909","lon":"-118.242766","display_name":"Los Angeles"}]';
String _aladhan(String tz) =>
    '{"code":200,"status":"OK","data":{"meta":{"timezone":"$tz"}}}';

/// İstek adreslerini kaydeden sahte istemci. [yanitlar]: (adres parçası → yanıt).
class _Sahte {
  _Sahte(this.yanitlar);
  final Map<String, http.Response Function(Uri)> yanitlar;
  final istekler = <Uri>[];
  final basliklar = <Map<String, String>>[];

  MockClient get istemci => MockClient((istek) async {
        istekler.add(istek.url);
        basliklar.add(istek.headers);
        for (final e in yanitlar.entries) {
          if (istek.url.toString().contains(e.key)) return e.value(istek.url);
        }
        return http.Response('bulunamadı', 404);
      });
}

http.Response _tamam(String govde) => http.Response(govde, 200);

YerBulucu _bulucu(_Sahte s) =>
    YerBulucu(istemci: s.istemci, denemeAraligi: Duration.zero);

void main() {
  group('baslikYaz', () {
    test('yabancı adlar', () {
      expect(baslikYaz('LOS ANGELES'), 'Los Angeles');
      expect(baslikYaz('ADACHI-KU'), 'Adachi-Ku');
      expect(baslikYaz("COTE D'IVOIRE"), "Cote D'Ivoire");
      expect(baslikYaz(' UNITED STATES '), 'United States');
    });

    test('bağlaçlar küçük kalır, ilk kelime hep büyük', () {
      expect(
          baslikYaz('ANTİGUA VE BARBUDA', turkce: true), 'Antigua ve Barbuda');
      expect(baslikYaz('BOSNIA AND HERZEGOVINA'), 'Bosnia and Herzegovina');
      expect(baslikYaz('SAINT VINCENT AND THE GRENADINES'),
          'Saint Vincent and the Grenadines');
      expect(baslikYaz('THE HAGUE'), 'The Hague');
      expect(baslikYaz('ANDORRA'),
          'Andorra'); // kelimenin içindeki "And" bağlaç değil
      expect(baslikYaz('OFFENBACH'), 'Offenbach');
    });

    test('Türkçe kuralı: İ/I doğru küçülür ve büyür', () {
      expect(baslikYaz('İSTANBUL', turkce: true), 'İstanbul');
      expect(baslikYaz('IĞDIR', turkce: true), 'Iğdır');
      expect(baslikYaz('AMERİKA BİRLEŞİK DEVLETLERİ', turkce: true),
          'Amerika Birleşik Devletleri');
      expect(baslikYaz('TÜRKİYE'), 'Türkiye'); // İngilizce kuralda da bozulmaz
    });
  });

  group('YerBulucu.bul', () {
    test('Los Angeles: koordinat Nominatim\'den, saat dilimi Aladhan\'dan',
        () async {
      final sahte = _Sahte({
        'nominatim': (_) => _tamam(_laNominatim),
        'aladhan': (_) => _tamam(_aladhan('America/Los_Angeles')),
      });

      final konum =
          await _bulucu(sahte).bul(ulke: _abd, sehir: _kaliforniya, ilce: _la);

      expect(konum.ad, 'Los Angeles');
      expect(konum.ulke, 'Amerika Birleşik Devletleri');
      expect(konum.saatDilimi, 'America/Los_Angeles');
      expect(konum.diyanetIlceId, 8626);
      expect(konum.enlem, closeTo(34.0537, 1e-4));
      expect(konum.boylam, closeTo(-118.2428, 1e-4));

      // İlk sorgu ilçe, eyalet, ülke; kullanım koşulu gereği kimlik başlığı var.
      expect(sahte.istekler.first.queryParameters['q'],
          'Los Angeles, California, United States');
      expect(sahte.basliklar.first['User-Agent'],
          contains('ezan_vakti_uygulamasi'));
      // Saat dilimi, Nominatim'in koordinatıyla sorulur.
      expect(sahte.istekler.last.queryParameters['latitude'], '34.0536909');
      expect(sahte.istekler.last.queryParameters['longitude'], '-118.242766');
    });

    test('şehir, ülkeyle aynıysa sorguda tekrarlanmaz', () async {
      final sahte = _Sahte({
        'nominatim': (_) => _tamam(_laNominatim),
        'aladhan': (_) => _tamam(_aladhan('Europe/Amsterdam')),
      });
      const hollanda = DiyanetYeri(id: 1, ad: 'HOLLANDA', adEn: 'NETHERLANDS');

      await _bulucu(sahte).bul(
          ulke: hollanda,
          sehir:
              const DiyanetYeri(id: 2, ad: 'NETHERLANDS', adEn: 'NETHERLANDS'),
          ilce: const DiyanetYeri(id: 3, ad: 'ABCOUDE', adEn: 'ABCOUDE'));

      expect(sahte.istekler.first.queryParameters['q'], 'Abcoude, Netherlands');
    });

    test('ilk sorgu boşsa "İlçe, Ülke" denenir', () async {
      var sayac = 0;
      final sahte = _Sahte({
        'nominatim': (_) => _tamam(++sayac == 1 ? '[]' : _laNominatim),
        'aladhan': (_) => _tamam(_aladhan('America/Los_Angeles')),
      });

      final konum =
          await _bulucu(sahte).bul(ulke: _abd, sehir: _kaliforniya, ilce: _la);

      expect(konum.saatDilimi, 'America/Los_Angeles');
      final sorgular = sahte.istekler
          .where((u) => u.host.contains('nominatim'))
          .map((u) => u.queryParameters['q'])
          .toList();
      expect(sorgular, [
        'Los Angeles, California, United States',
        'Los Angeles, United States'
      ]);
    });

    test('hiçbir sorgu sonuç vermezse hata (tahmin yürütülmez)', () async {
      final sahte = _Sahte({'nominatim': (_) => _tamam('[]')});

      expect(_bulucu(sahte).bul(ulke: _abd, sehir: _kaliforniya, ilce: _la),
          throwsA(isA<YerBulucuHatasi>()));
    });

    test('Türkiye: saat dilimi sabit, Aladhan\'a gidilmez', () async {
      final sahte = _Sahte({'nominatim': (_) => _tamam(_laNominatim)});

      final konum = await _bulucu(sahte)
          .bul(ulke: _turkiye, sehir: _istanbul, ilce: _kadikoy);

      expect(konum.saatDilimi, 'Europe/Istanbul');
      expect(konum.ad, 'Kadıköy');
      expect(konum.ulke, 'Türkiye');
      expect(sahte.istekler.any((u) => u.host.contains('aladhan')), isFalse);
    });

    test('Aladhan bilinmeyen saat dilimi verirse hata', () async {
      final sahte = _Sahte({
        'nominatim': (_) => _tamam(_laNominatim),
        'aladhan': (_) => _tamam(_aladhan('Mars/Olympus')),
      });

      expect(_bulucu(sahte).bul(ulke: _abd, sehir: _kaliforniya, ilce: _la),
          throwsA(isA<YerBulucuHatasi>()));
    });

    test('Aladhan hata yanıtı verirse hata', () async {
      final sahte = _Sahte({
        'nominatim': (_) => _tamam(_laNominatim),
        'aladhan': (_) => http.Response(
            '{"code":503,"data":"Geocoding is temporarily unavailable."}', 503),
      });

      expect(_bulucu(sahte).bul(ulke: _abd, sehir: _kaliforniya, ilce: _la),
          throwsA(isA<YerBulucuHatasi>()));
    });

    test('aralık dışı ya da bozuk koordinat sonuç sayılmaz', () async {
      final sahte = _Sahte({
        'nominatim': (_) => _tamam('[{"lat":"123","lon":"-118"}]'),
      });

      expect(_bulucu(sahte).bul(ulke: _abd, sehir: _kaliforniya, ilce: _la),
          throwsA(isA<YerBulucuHatasi>()));
    });

    test('ağ hatası YerBulucuHatasi olur', () async {
      final istemci =
          MockClient((_) async => throw http.ClientException('bağlantı yok'));

      expect(
          YerBulucu(istemci: istemci, denemeAraligi: Duration.zero)
              .bul(ulke: _abd, sehir: _kaliforniya, ilce: _la),
          throwsA(isA<YerBulucuHatasi>()));
    });
  });
}

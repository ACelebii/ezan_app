import 'dart:convert';

import 'package:ezan_vakti_uygulamasi/core/vakit/diyanet_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _istanbul =
    Konum(ad: 'İstanbul', saatDilimi: 'Europe/Istanbul', diyanetIlceId: 9541);
const _newYork = Konum(
    ad: 'New York',
    ulke: 'ABD',
    saatDilimi: 'America/New_York',
    diyanetIlceId: 1234);

/// API'nin gerçek satır biçimi (İstanbul, 19.09.2026, planda doğrulanmış).
const _ornekSatir = '''
{"HicriTarihKisa":"8.4.1448","HicriTarihUzun":"8 Rebiulahir 1448",
 "MiladiTarihKisa":"19.09.2026","MiladiTarihUzun":"19 Eylül 2026 Cumartesi",
 "GreenwichOrtalamaZamani":3.0,"Imsak":"05:15","Gunes":"06:41",
 "GunesBatis":"19:08","GunesDogus":"06:48","Ogle":"13:03","Ikindi":"16:31",
 "Aksam":"19:15","Yatsi":"20:35"}''';

/// Verilen tarih ve imsak saatiyle bir satır üretir, diğer alanlar sabit.
String _satir(String tarih, {String imsak = '05:15'}) => '''
{"MiladiTarihKisa":"$tarih","GreenwichOrtalamaZamani":3.0,"Imsak":"$imsak",
 "Gunes":"06:41","Ogle":"13:03","Ikindi":"16:31","Aksam":"19:15",
 "Yatsi":"20:35"}''';

void main() {
  // Bilerek saat dilimi veritabanını burada yüklemiyoruz: servis/kaynak kendisi
  // hazırlamalı (ana ekranın ilk çizimde yaşadığı hata buydu).
  group('DiyanetKaynagi.coz', () {
    test('örnek satırı okur', () {
      final gunler = DiyanetKaynagi.coz('[$_ornekSatir]', _istanbul);

      expect(gunler, hasLength(1));
      final gun = gunler.single;
      expect(gun.tarih, DateTime.utc(2026, 9, 19));
      expect(gun.kaynak, VakitKaynagi.diyanet);
      expect(gun.hicriTarih, '8 Rebiulahir 1448');
      expect(gun.saatler, {
        Vakit.imsak: '05:15',
        Vakit.gunes: '06:41',
        Vakit.ogle: '13:03',
        Vakit.ikindi: '16:31',
        Vakit.aksam: '19:15',
        Vakit.yatsi: '20:35',
      });
    });

    test('İstanbul anları UTC+3 olarak hesaplanır', () {
      final gun = DiyanetKaynagi.coz('[$_ornekSatir]', _istanbul).single;

      expect(gun.anlar[Vakit.imsak], DateTime.utc(2026, 9, 19, 2, 15));
      expect(gun.anlar[Vakit.aksam], DateTime.utc(2026, 9, 19, 16, 15));
      expect(gun.anlar[Vakit.yatsi], DateTime.utc(2026, 9, 19, 17, 35));
    });

    test('yaz saati geçişinde aynı saat metni farklı ana denk gelir', () {
      // New York'ta 01.11.2026 02:00'de saatler geri alınır (UTC-4 → UTC-5).
      // API'nin GreenwichOrtalamaZamani alanı (hep 3.0) yok sayılmalı.
      final gunler = DiyanetKaynagi.coz(
          '[${_satir('31.10.2026', imsak: '05:30')},'
          '${_satir('01.11.2026', imsak: '05:30')}]',
          _newYork);

      final cumartesi = gunler[0].anlar[Vakit.imsak]!;
      final pazar = gunler[1].anlar[Vakit.imsak]!;
      expect(cumartesi, DateTime.utc(2026, 10, 31, 9, 30)); // UTC-4
      expect(pazar, DateTime.utc(2026, 11, 1, 10, 30)); // UTC-5
      expect(pazar.difference(cumartesi), const Duration(hours: 25));
      expect(gunler[1].saatler[Vakit.imsak], '05:30');
    });

    test('bozuk satırları atlar, geçerli olanları korur', () {
      final gunler = DiyanetKaynagi.coz(
          '[${_satir('31.02.2026')},' // olmayan tarih
          '${_satir('19.09.2026', imsak: '25:99')},' // olmayan saat
          '${_satir('bugun')},' // tarih değil
          '{"MiladiTarihKisa":"19.09.2026"},' // vakitler eksik
          '"metin",null,' // nesne değil
          '${_satir('20.09.2026', imsak: '05:17')}]',
          _istanbul);

      expect(gunler, hasLength(1));
      expect(gunler.single.tarih, DateTime.utc(2026, 9, 20));
      expect(gunler.single.saatler[Vakit.imsak], '05:17');
    });

    test('tek haneli saat "05:07" biçimine getirilir', () {
      final gun = DiyanetKaynagi.coz(
              '[${_satir('19.09.2026', imsak: '5:07')}]', _istanbul)
          .single;

      expect(gun.saatler[Vakit.imsak], '05:07');
    });

    test('hiç geçerli satır yoksa DiyanetHatasi fırlatır', () {
      for (final yanit in [
        '[]',
        '[{}]',
        '{"hata":"yok"}', // liste değil
        'Bad Gateway', // JSON değil
        '',
      ]) {
        expect(() => DiyanetKaynagi.coz(yanit, _istanbul),
            throwsA(isA<DiyanetHatasi>()),
            reason: 'yanıt: "$yanit"');
      }
    });
  });

  group('DiyanetKaynagi ağ istekleri', () {
    // Türkçe harfli yanıt; başlıkta charset yok (latin1 sanılmamalı).
    DiyanetKaynagi kaynak(http.Response Function(http.Request) yanit,
            [List<Uri>? istekler]) =>
        DiyanetKaynagi(istemci: MockClient((istek) async {
          istekler?.add(istek.url);
          return yanit(istek);
        }));

    http.Response yanitla(String govde, [int kod = 200]) =>
        http.Response.bytes(utf8.encode(govde), kod);

    test('vakitleriGetir doğru adrese gider', () async {
      final istekler = <Uri>[];
      final gunler = await kaynak((_) => yanitla('[$_ornekSatir]'), istekler)
          .vakitleriGetir(_istanbul);

      expect(istekler.single.toString(),
          'https://ezanvakti.emushaf.net/vakitler/9541');
      expect(gunler.single.saatler[Vakit.aksam], '19:15');
    });

    test('200 dışındaki yanıt DiyanetHatasi olur', () {
      expect(
          kaynak((_) => yanitla('Bad Gateway', 502)).vakitleriGetir(_istanbul),
          throwsA(isA<DiyanetHatasi>()));
    });

    test('bağlantı hatası DiyanetHatasi olur', () {
      final bozuk = DiyanetKaynagi(
          istemci: MockClient((_) async => throw http.ClientException('yok')));

      expect(bozuk.vakitleriGetir(_istanbul), throwsA(isA<DiyanetHatasi>()));
    });

    test('ilçe kodu olmayan konum için istek atmadan hata verir', () {
      const koordinatli = Konum(
          ad: 'Sidney',
          ulke: 'Avustralya',
          saatDilimi: 'Australia/Sydney',
          enlem: -33.87,
          boylam: 151.21);
      final istekler = <Uri>[];

      expect(kaynak((_) => yanitla('[]'), istekler).vakitleriGetir(koordinatli),
          throwsA(isA<DiyanetHatasi>()));
      expect(istekler, isEmpty);
    });

    test('ülke listesi: ID metinden sayıya çevrilir, Türkçe harfler bozulmaz',
        () async {
      final ulkeler = await kaynak((_) =>
          yanitla('[{"UlkeAdi":"TÜRKİYE","UlkeAdiEn":"TÜRKİYE","UlkeID":"2"},'
              '{"UlkeAdi":"ABD","UlkeAdiEn":"USA","UlkeID":"33"}]')).ulkeler();

      expect(ulkeler.map((u) => u.id), [2, 33]);
      expect(ulkeler.first.ad, 'TÜRKİYE');
      expect(ulkeler.last.adEn, 'USA');
    });

    test('şehir ve ilçe listeleri doğru adrese gider ve okunur', () async {
      final istekler = <Uri>[];
      final k = kaynak((istek) {
        final sehir = istek.url.path.startsWith('/sehirler');
        return yanitla(sehir
            ? '[{"SehirAdi":"AFYONKARAHİSAR","SehirAdiEn":"AFYONKARAHISAR",'
                '"SehirID":"502"}]'
            : '[{"IlceAdi":"BAŞAKŞEHİR","IlceAdiEn":"BASAKSEHIR",'
                '"IlceID":"17866"}]');
      }, istekler);

      final sehirler = await k.sehirler(2);
      final ilceler = await k.ilceler(539);

      expect(istekler.map((u) => u.path), ['/sehirler/2', '/ilceler/539']);
      expect((sehirler.single.id, sehirler.single.ad), (502, 'AFYONKARAHİSAR'));
      expect((ilceler.single.id, ilceler.single.adEn), (17866, 'BASAKSEHIR'));
    });

    test('yer listeleri saklanır: aynı liste ikinci kez ağa gitmez', () async {
      final istekler = <Uri>[];
      final k = kaynak(
          (_) => yanitla(
              '[{"UlkeAdi":"TÜRKİYE","UlkeAdiEn":"TÜRKİYE","UlkeID":"2"}]'),
          istekler);

      final ilk = await k.ulkeler();
      final ikinci = await k.ulkeler();

      expect(istekler, hasLength(1));
      expect(identical(ilk, ikinci), isTrue);
    });

    test('farklı listeler ayrı saklanır (sehirler/2 ile sehirler/33 karışmaz)',
        () async {
      final istekler = <Uri>[];
      final k = kaynak(
          (i) => yanitla(
              '[{"SehirAdi":"X${i.url.pathSegments.last}","SehirAdiEn":"X","SehirID":"${i.url.pathSegments.last}"}]'),
          istekler);

      final a = await k.sehirler(2);
      final b = await k.sehirler(33);
      await k.sehirler(2);

      expect(istekler.map((u) => u.path), ['/sehirler/2', '/sehirler/33']);
      expect((a.single.id, b.single.id), (2, 33));
    });

    test('hata saklanmaz: sonraki çağrı yeniden dener', () async {
      var cagri = 0;
      final k = kaynak((_) => ++cagri == 1
          ? yanitla('kapalı', 502)
          : yanitla(
              '[{"UlkeAdi":"TÜRKİYE","UlkeAdiEn":"TÜRKİYE","UlkeID":"2"}]'));

      await expectLater(k.ulkeler(), throwsA(isA<DiyanetHatasi>()));
      expect(await k.ulkeler(), hasLength(1));
    });

    test('yer listesinde bozuk satırlar atlanır, boşsa hata verilir', () async {
      final ilceler = await kaynak((_) => yanitla(
              '[{"IlceAdi":"X","IlceID":"abc"},{"IlceAdi":"Y","IlceID":"7"},1]'))
          .ilceler(1);
      expect(ilceler.map((i) => i.id), [7]);
      expect(ilceler.single.adEn, 'Y'); // AdEn yoksa Ad kullanılır

      expect(kaynak((_) => yanitla('[]')).ilceler(1),
          throwsA(isA<DiyanetHatasi>()));
    });
  });

  group('yerleriSuz', () {
    const yerler = [
      DiyanetYeri(id: 1, ad: 'IĞDIR', adEn: 'IGDIR'),
      DiyanetYeri(id: 2, ad: 'İZMİR', adEn: 'IZMIR'),
      DiyanetYeri(id: 3, ad: 'ALMANYA', adEn: 'GERMANY'),
      DiyanetYeri(
          id: 4, ad: 'AMERİKA BİRLEŞİK DEVLETLERİ', adEn: 'UNITED STATES'),
    ];
    List<int> ids(String arama) =>
        yerleriSuz(yerler, arama).map((y) => y.id).toList();

    test('Türkçe harfler ve büyük/küçük harf fark etmez', () {
      expect(ids('izmir'), [2]);
      expect(ids('İZM'), [2]);
      expect(ids('ığdır'), [1]);
      expect(ids('igdir'), [1]);
      expect(ids('birleşik'), [4]);
    });

    test('Latin (İngilizce) adla da bulunur', () {
      expect(ids('germany'), [3]);
      expect(ids('united'), [4]);
    });

    test('boş arama hepsini, eşleşmeyen arama hiçbirini döndürür', () {
      expect(ids(''), [1, 2, 3, 4]);
      expect(ids('  '), [1, 2, 3, 4]);
      expect(ids('xyz'), isEmpty);
    });
  });
}

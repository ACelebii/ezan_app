import 'dart:convert';

import 'package:ezan_vakti_uygulamasi/core/vakit/aladhan_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _istanbul =
    Konum(ad: 'İstanbul', saatDilimi: 'Europe/Istanbul', diyanetIlceId: 9541);
const _sidney = Konum(
    ad: 'Sidney',
    ulke: 'Avustralya',
    saatDilimi: 'Australia/Sydney',
    enlem: -33.87,
    boylam: 151.21);

/// Aladhan `calendar` yanıtındaki bir gün. Saatler, 20.09.2026'da gerçek
/// API'den ölçülen İstanbul değerleridir (Fajr 05:15 … Isha 20:34); `Imsak`
/// alanı Aladhan'ın kendi Fajr−10 dk değeridir.
/// [tarih] "19-09-2026" biçimindedir; ofset "+03:00" gibi.
String _gun(String tarih, {String ofset = '+03:00', String fajr = '05:15'}) {
  final iso = tarih.split('-').reversed.join('-');
  String z(String saat) => '"${iso}T$saat:00$ofset"';
  return '{"timings":{"Fajr":${z(fajr)},"Sunrise":${z('06:41')},'
      '"Dhuhr":${z('13:03')},"Asr":${z('16:31')},"Sunset":${z('19:14')},'
      '"Maghrib":${z('19:14')},"Isha":${z('20:34')},"Imsak":${z('05:05')}},'
      '"date":{"gregorian":{"date":"$tarih"}}}';
}

String _yanit(List<String> gunler) =>
    '{"code":200,"status":"OK","data":[${gunler.join(',')}]}';

void main() {
  group('AladhanKaynagi.coz', () {
    test('İstanbul gününü okur; Aladhan\'ın Imsak alanı yok sayılır', () {
      final gun = AladhanKaynagi.coz(_yanit([_gun('19-09-2026')])).single;

      expect(gun.tarih, DateTime.utc(2026, 9, 19));
      expect(gun.kaynak, VakitKaynagi.aladhan);
      expect(gun.hicriTarih, isNull);
      expect(gun.saatler, {
        Vakit.imsak: '05:15', // Fajr, "Imsak" alanındaki 05:05 değil
        Vakit.gunes: '06:41',
        Vakit.ogle: '13:03',
        Vakit.ikindi: '16:31',
        Vakit.aksam: '19:14',
        Vakit.yatsi: '20:34',
      });
    });

    test('anlar ofsetten hesaplanır (UTC+3)', () {
      final gun = AladhanKaynagi.coz(_yanit([_gun('19-09-2026')])).single;

      expect(gun.anlar[Vakit.imsak], DateTime.utc(2026, 9, 19, 2, 15));
      expect(gun.anlar[Vakit.aksam], DateTime.utc(2026, 9, 19, 16, 14));
      expect(gun.anlar[Vakit.yatsi], DateTime.utc(2026, 9, 19, 17, 34));
    });

    test('yaz saati geçişinde saat metni aynı kalır, an kayar (Sidney)', () {
      // Sidney'de 04.10.2026 02:00'de saatler ileri alınır (+10 → +11).
      final gunler = AladhanKaynagi.coz(_yanit([
        _gun('03-10-2026', ofset: '+10:00', fajr: '04:30'),
        _gun('04-10-2026', ofset: '+11:00', fajr: '04:30'),
      ]));

      expect(gunler.map((g) => g.saatler[Vakit.imsak]), ['04:30', '04:30']);
      expect(gunler[0].anlar[Vakit.imsak], DateTime.utc(2026, 10, 2, 18, 30));
      expect(gunler[1].anlar[Vakit.imsak], DateTime.utc(2026, 10, 3, 17, 30));
    });

    test('bozuk günleri atlar, geçerli olanları korur', () {
      final gunler = AladhanKaynagi.coz(_yanit([
        _gun('31-02-2026'), // olmayan tarih
        _gun('19-09-2026').replaceAll('"Isha"', '"Yok"'), // vakit eksik
        _gun('19-09-2026').replaceFirst(
            '"2026-09-19T05:15:00+03:00"', '"05:15 (+03)"'), // ISO değil
        '{"timings":{}}', // tarih yok
        '"metin"',
        'null',
        _gun('20-09-2026', fajr: '05:17'),
      ]));

      expect(gunler, hasLength(1));
      expect(gunler.single.tarih, DateTime.utc(2026, 9, 20));
      expect(gunler.single.saatler[Vakit.imsak], '05:17');
    });

    test('hiç geçerli gün yoksa AladhanHatasi fırlatır', () {
      for (final yanit in [
        '',
        'Bad Gateway', // JSON değil
        '[]', // nesne değil
        '{"code":500,"status":"SERVER_ERROR","data":"An unexpected error"}',
        '{"code":200,"data":[]}',
        '{"code":200,"data":[{}]}',
      ]) {
        expect(() => AladhanKaynagi.coz(yanit), throwsA(isA<AladhanHatasi>()),
            reason: 'yanıt: "$yanit"');
      }
    });
  });

  group('AladhanKaynagi ağ istekleri', () {
    // İstekleri kaydeder; her isteğe, isteğin ayına göre bir gün döndürür.
    AladhanKaynagi kaynak(List<Uri> istekler, {int Function(Uri)? durum}) {
      return AladhanKaynagi(istemci: MockClient((istek) async {
        istekler.add(istek.url);
        final kod = durum?.call(istek.url) ?? 200;
        final ay = istek.url.pathSegments.last.padLeft(2, '0');
        return http.Response.bytes(
            utf8.encode(_yanit([_gun('15-$ay-2026')])), kod);
      }));
    }

    test('koordinatlı konum: calendar adresi, bu ay ve sonraki ay', () async {
      final istekler = <Uri>[];
      final gunler =
          await kaynak(istekler).vakitleriGetir(_sidney, DateTime(2026, 9, 19));

      expect(istekler.map((u) => u.path).toSet(),
          {'/v1/calendar/2026/9', '/v1/calendar/2026/10'});
      expect(istekler.first.host, 'api.aladhan.com');
      expect(istekler.first.queryParameters, {
        'method': '13',
        'iso8601': 'true',
        'timezonestring': 'Australia/Sydney',
        'latitude': '-33.87',
        'longitude': '151.21',
      });
      expect(gunler.map((g) => g.tarih),
          [DateTime.utc(2026, 9, 15), DateTime.utc(2026, 10, 15)]);
    });

    test('koordinatsız konum: şehir adı ASCII olur, Türkiye Turkey olur',
        () async {
      final istekler = <Uri>[];
      await kaynak(istekler).vakitleriGetir(_istanbul, DateTime(2026, 9, 19));

      expect(istekler.first.path, startsWith('/v1/calendarByCity/2026/'));
      expect(istekler.first.queryParameters['city'], 'Istanbul');
      expect(istekler.first.queryParameters['country'], 'Turkey');
      expect(
          istekler.first.queryParameters['timezonestring'], 'Europe/Istanbul');
      expect(istekler.first.queryParameters.containsKey('latitude'), isFalse);
    });

    test('Diyanet yazımıyla büyük harfli ad da çevrilir', () async {
      final istekler = <Uri>[];
      const urfa = Konum(
          ad: 'ŞANLIURFA',
          ulke: 'TÜRKİYE',
          saatDilimi: 'Europe/Istanbul',
          diyanetIlceId: 9831);
      await kaynak(istekler).vakitleriGetir(urfa, DateTime(2026, 9, 19));

      expect(istekler.first.queryParameters['city'], 'SANLIURFA');
      expect(istekler.first.queryParameters['country'], 'Turkey');
    });

    test('aralık ayında sonraki ay, gelecek yılın ocağıdır', () async {
      final istekler = <Uri>[];
      await kaynak(istekler).vakitleriGetir(_sidney, DateTime(2026, 12, 15));

      expect(istekler.map((u) => u.path).toSet(),
          {'/v1/calendar/2026/12', '/v1/calendar/2027/1'});
    });

    test('sonraki ay alınamazsa yalnızca bu ay döner', () async {
      final gunler =
          await kaynak([], durum: (u) => u.path.endsWith('/10') ? 503 : 200)
              .vakitleriGetir(_sidney, DateTime(2026, 9, 19));

      expect(gunler.map((g) => g.tarih), [DateTime.utc(2026, 9, 15)]);
    });

    test('bu ay alınamazsa AladhanHatasi fırlatır', () {
      final k = kaynak([], durum: (u) => u.path.endsWith('/9') ? 503 : 200);

      expect(k.vakitleriGetir(_sidney, DateTime(2026, 9, 19)),
          throwsA(isA<AladhanHatasi>()));
    });

    test('bağlantı hatası AladhanHatasi olur', () {
      final bozuk = AladhanKaynagi(
          istemci: MockClient((_) async => throw http.ClientException('yok')));

      expect(bozuk.vakitleriGetir(_sidney, DateTime(2026, 9, 19)),
          throwsA(isA<AladhanHatasi>()));
    });
  });

  group('AladhanKaynagi yöntem ve okul', () {
    AladhanKaynagi kaynak(List<Uri> istekler) =>
        AladhanKaynagi(istemci: MockClient((istek) async {
          istekler.add(istek.url);
          return http.Response.bytes(
              utf8.encode(_yanit([_gun('15-09-2026')])), 200);
        }));

    test('varsayılan: method=13, school yok', () async {
      final istekler = <Uri>[];

      await kaynak(istekler).ayiGetir(_istanbul, 2026, 9);

      expect(istekler.single.queryParameters['method'], '13');
      expect(istekler.single.queryParameters.containsKey('school'), isFalse);
    });

    test('yöntem ve Hanefi adrese yansır', () async {
      final istekler = <Uri>[];
      final k = kaynak(istekler);

      await k.ayiGetir(_istanbul, 2026, 9, yontem: 3, hanefi: true);
      await k.vakitleriGetir(_istanbul, DateTime(2026, 9, 19), yontem: 5);

      expect(istekler.first.queryParameters['method'], '3');
      expect(istekler.first.queryParameters['school'], '1');
      // vakitleriGetir iki ay ister; ikisinde de yöntem geçer, Hanefi yok.
      for (final u in istekler.skip(1)) {
        expect(u.queryParameters['method'], '5');
        expect(u.queryParameters.containsKey('school'), isFalse);
      }
    });
  });
}

import 'dart:convert';

import 'package:ezan_vakti_uygulamasi/core/vakit/aladhan_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/diyanet_kaynagi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_servisi.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_tercihi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _istanbul =
    Konum(ad: 'İstanbul', saatDilimi: 'Europe/Istanbul', diyanetIlceId: 9541);
const _newYork = Konum(
    ad: 'New York',
    ulke: 'ABD',
    saatDilimi: 'America/New_York',
    diyanetIlceId: 1234);
const _sidney = Konum(
    ad: 'Sydney',
    ulke: 'Australia',
    saatDilimi: 'Australia/Sydney',
    enlem: -33.87,
    boylam: 151.21);

String _iki(int sayi) => sayi.toString().padLeft(2, '0');

/// Diyanet yanıtı: 14.09.2026'dan başlayan [gunSayisi] gün (gerçek API de
/// haftanın başından başlayıp yaklaşık 32 gün verir).
String _diyanetYaniti(int gunSayisi) {
  final satirlar = [
    for (var i = 0; i < gunSayisi; i++)
      () {
        final g = DateTime.utc(2026, 9, 14 + i);
        return '{"MiladiTarihKisa":"${_iki(g.day)}.${_iki(g.month)}.${g.year}",'
            '"Imsak":"05:15","Gunes":"06:41","Ogle":"13:03","Ikindi":"16:31",'
            '"Aksam":"19:15","Yatsi":"20:35"}';
      }(),
  ];
  return '[${satirlar.join(',')}]';
}

/// Aladhan yanıtı: verilen ayın tüm günleri (İstanbul, +03:00). [hanefi]
/// true ise ikindi asr-ı sanidir (gerçek API: 16:31 yerine 17:23).
String _aladhanAyi(int yil, int ay, {bool hanefi = false}) {
  final gunSayisi = DateTime.utc(yil, ay + 1, 0).day;
  final gunler = [
    for (var gun = 1; gun <= gunSayisi; gun++)
      () {
        final iso = '$yil-${_iki(ay)}-${_iki(gun)}';
        String z(String saat) => '"${iso}T$saat:00+03:00"';
        return '{"timings":{"Fajr":${z('05:15')},"Sunrise":${z('06:41')},'
            '"Dhuhr":${z('13:03')},"Asr":${z(hanefi ? '17:23' : '16:31')},"Maghrib":${z('19:14')},'
            '"Isha":${z('20:34')}},'
            '"date":{"gregorian":{"date":"${_iki(gun)}-${_iki(ay)}-$yil"}}}';
      }(),
  ];
  return '{"code":200,"status":"OK","data":[${gunler.join(',')}]}';
}

/// İki servisi de taklit eden sahte sunucu; istekleri sayar.
class _Sunucu {
  bool diyanetCokuk = false;
  bool aladhanCokuk = false;
  int diyanetGunSayisi = 32; // 14.09 → 15.10

  final istekler = <Uri>[];
  int get diyanetIstegi =>
      istekler.where((u) => u.host == 'ezanvakti.emushaf.net').length;
  int get aladhanIstegi =>
      istekler.where((u) => u.host == 'api.aladhan.com').length;

  late final istemci = MockClient((istek) async {
    istekler.add(istek.url);
    final diyanet = istek.url.host == 'ezanvakti.emushaf.net';
    if (diyanet ? diyanetCokuk : aladhanCokuk) {
      return http.Response('Bad Gateway', 502);
    }
    final govde = diyanet
        ? _diyanetYaniti(diyanetGunSayisi)
        : _aladhanAyi(int.parse(istek.url.pathSegments[2]),
            int.parse(istek.url.pathSegments[3]),
            hanefi: istek.url.queryParameters['school'] == '1');
    return http.Response.bytes(utf8.encode(govde), 200);
  });
}

void main() {
  // Bilerek saat dilimi veritabanını burada yüklemiyoruz: servis/kaynak kendisi
  // hazırlamalı (ana ekranın ilk çizimde yaşadığı hata buydu).
  late _Sunucu sunucu;
  late DateTime simdi;
  late VakitServisi servis;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sunucu = _Sunucu();
    simdi = DateTime.utc(2026, 9, 20, 7); // İstanbul'da 20.09.2026 10:00
    servis = VakitServisi(
      diyanet: DiyanetKaynagi(istemci: sunucu.istemci),
      aladhan: AladhanKaynagi(istemci: sunucu.istemci),
      simdi: () => simdi,
    );
  });

  test('önbellek boşken Diyanet\'ten alır, dünden itibaren verir', () async {
    final gunler = await servis.vakitleriGetir(_istanbul);

    expect(gunler.first.tarih, DateTime.utc(2026, 9, 19)); // dün
    expect(gunler.last.tarih, DateTime.utc(2026, 10, 15));
    expect(gunler, hasLength(27));
    expect(gunler.every((g) => g.kaynak == VakitKaynagi.diyanet), isTrue);
    expect((sunucu.diyanetIstegi, sunucu.aladhanIstegi), (1, 0));
  });

  test('ikinci çağrı ağa gitmez, önbellekten aynı veriyi verir', () async {
    final ilk = await servis.vakitleriGetir(_istanbul);
    final ikinci = await servis.vakitleriGetir(_istanbul);

    expect(sunucu.istekler, hasLength(1));
    expect(ikinci.map((g) => g.toJson()), ilk.map((g) => g.toJson()));
  });

  test('Diyanet çökerse Aladhan\'a geçer', () async {
    sunucu.diyanetCokuk = true;
    final gunler = await servis.vakitleriGetir(_istanbul);

    expect(gunler.first.tarih, DateTime.utc(2026, 9, 19));
    expect(gunler.every((g) => g.kaynak == VakitKaynagi.aladhan), isTrue);
    expect((sunucu.diyanetIstegi, sunucu.aladhanIstegi), (1, 2)); // 2 ay
  });

  test('Diyanet yetersiz veri verirse Aladhan\'a geçer', () async {
    sunucu.diyanetGunSayisi = 8; // 14.09 → 21.09: bugünden sonra 2 gün
    final gunler = await servis.vakitleriGetir(_istanbul);

    expect(gunler.first.kaynak, VakitKaynagi.aladhan);
    expect(sunucu.aladhanIstegi, 2);
  });

  test('yedek önbellek aynı gün taze, ertesi gün Diyanet yeniden denenir',
      () async {
    sunucu.diyanetCokuk = true;
    await servis.vakitleriGetir(_istanbul);

    await servis.vakitleriGetir(_istanbul); // aynı gün
    expect(sunucu.istekler, hasLength(3)); // 1 Diyanet + 2 Aladhan, yeni yok

    sunucu.diyanetCokuk = false;
    simdi = DateTime.utc(2026, 9, 21, 7);
    final gunler = await servis.vakitleriGetir(_istanbul);

    expect(sunucu.diyanetIstegi, 2);
    expect(gunler.first.kaynak, VakitKaynagi.diyanet);
  });

  test('ilçe kodu olmayan konum Diyanet\'i denemeden Aladhan\'a gider',
      () async {
    final gunler = await servis.vakitleriGetir(_sidney);

    expect((sunucu.diyanetIstegi, sunucu.aladhanIstegi), (0, 2));
    expect(gunler.first.kaynak, VakitKaynagi.aladhan);
  });

  test('ikisi de çökerse ve önbellek yoksa VakitHatasi fırlatır', () {
    sunucu
      ..diyanetCokuk = true
      ..aladhanCokuk = true;

    expect(servis.vakitleriGetir(_istanbul), throwsA(isA<VakitHatasi>()));
  });

  test('ikisi de çökerse eldeki bayat veriyi verir', () async {
    await servis.vakitleriGetir(_istanbul);
    sunucu
      ..diyanetCokuk = true
      ..aladhanCokuk = true;
    simdi = DateTime.utc(2026, 10, 10, 7); // veri 15.10'da bitiyor: 6 gün kaldı

    final gunler = await servis.vakitleriGetir(_istanbul);

    expect(gunler.first.tarih, DateTime.utc(2026, 10, 9)); // dün
    expect(gunler.last.tarih, DateTime.utc(2026, 10, 15));
  });

  test('aynı anda gelen iki istek tek ağ isteği atar', () async {
    final sonuc = await Future.wait([
      servis.vakitleriGetir(_istanbul),
      servis.vakitleriGetir(_istanbul),
    ]);

    expect(sunucu.diyanetIstegi, 1);
    expect(sonuc[0].length, sonuc[1].length);
  });

  test('bozuk önbellek yok sayılır ve yenisiyle değiştirilir', () async {
    SharedPreferences.setMockInitialValues(
        {'vakit_onbellek_diyanet-9541': 'bozuk{'});

    final gunler = await servis.vakitleriGetir(_istanbul);
    await servis.vakitleriGetir(_istanbul);

    expect(gunler, hasLength(27));
    expect(sunucu.istekler, hasLength(1)); // ikinci çağrı önbellekten
  });

  test('bugün, telefonun değil konumun saat dilimine göre bulunur', () async {
    // 20.09 22:00 UTC: İstanbul'da 21.09 01:00, New York'ta 20.09 18:00.
    simdi = DateTime.utc(2026, 9, 20, 22);

    final istanbul = await servis.vakitleriGetir(_istanbul);
    final newYork = await servis.vakitleriGetir(_newYork);

    expect(istanbul.first.tarih, DateTime.utc(2026, 9, 20)); // dün = 20.09
    expect(newYork.first.tarih, DateTime.utc(2026, 9, 19)); // dün = 19.09
  });

  group('ayVakitleri', () {
    test('Diyanet\'in elindeki günler Diyanet, ayın geri kalanı Aladhan',
        () async {
      // Diyanet 19.09 (dün) - 15.10; Eylül'ün 1-18'i onda yok.
      final gunler = await servis.ayVakitleri(_istanbul, 2026, 9);

      expect(gunler, hasLength(30));
      expect(gunler.first.tarih, DateTime.utc(2026, 9, 1));
      expect(gunler.last.tarih, DateTime.utc(2026, 9, 30));
      for (final gun in gunler) {
        expect(gun.kaynak,
            gun.tarih.day >= 19 ? VakitKaynagi.diyanet : VakitKaynagi.aladhan,
            reason: '${gun.tarih}');
      }
      expect(sunucu.aladhanIstegi, 1); // yalnızca Eylül
    });

    test('ay tamamen Diyanet\'teyse Aladhan\'a hiç gidilmez', () async {
      sunucu.diyanetGunSayisi = 60; // 14.09 → 12.11: Ekim'in tamamı içinde

      final gunler = await servis.ayVakitleri(_istanbul, 2026, 10);

      expect(gunler, hasLength(31));
      expect(gunler.every((g) => g.kaynak == VakitKaynagi.diyanet), isTrue);
      expect(sunucu.aladhanIstegi, 0);
    });

    test('Diyanet\'te hiç olmayan ay (geçmiş) tamamen Aladhan', () async {
      final gunler = await servis.ayVakitleri(_istanbul, 2026, 7);

      expect(gunler, hasLength(31));
      expect(gunler.every((g) => g.kaynak == VakitKaynagi.aladhan), isTrue);
    });

    test('Aladhan ayı süresiz önbelleğe alınır', () async {
      await servis.ayVakitleri(_istanbul, 2026, 7);
      final ilkSayi = sunucu.aladhanIstegi;
      await servis.ayVakitleri(_istanbul, 2026, 7);

      expect(sunucu.aladhanIstegi, ilkSayi);
    });

    test('Aladhan çökerse Diyanet\'in günleri döner, hata fırlatılmaz',
        () async {
      sunucu.aladhanCokuk = true;

      final gunler = await servis.ayVakitleri(_istanbul, 2026, 9);

      expect(gunler.first.tarih, DateTime.utc(2026, 9, 19));
      expect(gunler, hasLength(12)); // 19.09 - 30.09
    });

    test('hiçbir kaynaktan gün yoksa VakitHatasi fırlatır', () {
      sunucu
        ..diyanetCokuk = true
        ..aladhanCokuk = true;

      expect(
          servis.ayVakitleri(_istanbul, 2026, 7), throwsA(isA<VakitHatasi>()));
    });
  });

  group('tercih (Ayarlar)', () {
    Iterable<Uri> aladhanIstekleri() =>
        sunucu.istekler.where((u) => u.host == 'api.aladhan.com');

    test(
        'seçilen hesap yöntemi: Diyanet\'e gidilmez, yöntem Aladhan\'a iletilir',
        () async {
      const mwl = VakitTercihi(aladhanYontemi: 3);

      final gunler = await servis.vakitleriGetir(_istanbul, mwl);

      expect(sunucu.diyanetIstegi, 0);
      expect(
          aladhanIstekleri().every((u) => u.queryParameters['method'] == '3'),
          isTrue);
      expect(gunler.every((g) => g.kaynak == VakitKaynagi.aladhan), isTrue);
    });

    test('seçilen yöntemin önbelleği taze sayılır (Diyanet yeniden denenmez)',
        () async {
      const mwl = VakitTercihi(aladhanYontemi: 3);
      await servis.vakitleriGetir(_istanbul, mwl);
      final ilkSayi = sunucu.istekler.length;

      simdi = DateTime.utc(2026, 9, 21, 7); // ertesi gün
      await servis.vakitleriGetir(_istanbul, mwl);

      expect(sunucu.istekler.length, ilkSayi);
    });

    test('her tercihin önbelleği ayrıdır', () async {
      await servis.vakitleriGetir(_istanbul); // Diyanet
      await servis.vakitleriGetir(
          _istanbul, const VakitTercihi(aladhanYontemi: 3));
      final tekrarDiyanet = await servis.vakitleriGetir(_istanbul);

      expect(sunucu.diyanetIstegi, 1); // Diyanet önbelleği bozulmadı
      expect(tekrarDiyanet.first.kaynak, VakitKaynagi.diyanet);
    });

    test('Hanefi: vakitler Diyanet\'ten, yalnızca ikindi asr-ı sani (school=1)',
        () async {
      const hanefi = VakitTercihi(hanefiIkindi: true);

      final gunler = await servis.vakitleriGetir(_istanbul, hanefi);
      final bugun =
          gunler.firstWhere((g) => g.tarih == DateTime.utc(2026, 9, 20));

      expect(bugun.kaynak, VakitKaynagi.diyanet);
      expect(bugun.saatler[Vakit.ikindi], '17:23'); // Şafi 16:31 değil
      expect(bugun.saatler[Vakit.imsak], '05:15'); // Diyanet
      expect(bugun.saatler[Vakit.aksam], '19:15'); // Diyanet (Aladhan'da 19:14)
      expect(
          aladhanIstekleri().every((u) => u.queryParameters['school'] == '1'),
          isTrue);
    });

    test('Hanefi: Aladhan alınamazsa Diyanet ikindisi döner, önbelleğe alınmaz',
        () async {
      const hanefi = VakitTercihi(hanefiIkindi: true);
      sunucu.aladhanCokuk = true;

      final ilk = await servis.vakitleriGetir(_istanbul, hanefi);
      expect(ilk.firstWhere((g) => g.tarih.day == 20).saatler[Vakit.ikindi],
          '16:31');

      sunucu.aladhanCokuk = false; // düzeldi: bir sonraki çağrı yeniden dener
      final ikinci = await servis.vakitleriGetir(_istanbul, hanefi);
      expect(ikinci.firstWhere((g) => g.tarih.day == 20).saatler[Vakit.ikindi],
          '17:23');
    });

    test(
        'temkin düzeltmesi: dönen saatler kayar, önbellekteki ham veri değişmez',
        () async {
      const temkinli = VakitTercihi(duzeltme: {Vakit.aksam: 1, Vakit.ogle: -2});

      final duzeltilmis = await servis.vakitleriGetir(_istanbul, temkinli);
      final ham = await servis.vakitleriGetir(_istanbul); // aynı önbellek

      final d = duzeltilmis.firstWhere((g) => g.tarih.day == 20);
      final h = ham.firstWhere((g) => g.tarih.day == 20);
      expect(h.saatler[Vakit.aksam], '19:15');
      expect(d.saatler[Vakit.aksam], '19:16');
      expect(d.saatler[Vakit.ogle], '13:01');
      expect(d.anlar[Vakit.aksam],
          h.anlar[Vakit.aksam]!.add(const Duration(minutes: 1)));
      expect(sunucu.istekler, hasLength(1)); // ham veri paylaşıldı
    });

    test('ayVakitleri de düzeltmeyi ve Aladhan yöntemini uygular', () async {
      const tercih =
          VakitTercihi(aladhanYontemi: 2, duzeltme: {Vakit.imsak: 3});

      final gunler = await servis.ayVakitleri(_istanbul, 2026, 7, tercih);

      expect(gunler, hasLength(31));
      expect(gunler.first.saatler[Vakit.imsak], '05:18'); // 05:15 + 3
      expect(
          aladhanIstekleri().every((u) => u.queryParameters['method'] == '2'),
          isTrue);
    });
  });
}

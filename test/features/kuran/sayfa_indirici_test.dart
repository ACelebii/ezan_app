import 'dart:io';
import 'dart:typed_data';

import 'package:ezan_vakti_uygulamasi/features/kuran/data/sayfa_indirici.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// PNG imzasıyla başlayan sahte görsel.
Uint8List png(int sayfa) =>
    Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, sayfa % 256, 1, 2, 3]);

class BellekKayitlari implements SayfaKayitlari {
  final kayit = <int, String>{};

  @override
  Future<Map<int, String>> indirilenler() async => Map.of(kayit);

  @override
  Future<void> kaydet(int sayfa, String yol) async => kayit[sayfa] = yol;
}

void main() {
  late Directory klasor;
  late BellekKayitlari kayitlar;
  late List<Uri> istekler;

  setUp(() async {
    klasor = await Directory.systemTemp.createTemp('sayfa_indirici_');
    kayitlar = BellekKayitlari();
    istekler = [];
  });

  tearDown(() async {
    if (await klasor.exists()) await klasor.delete(recursive: true);
  });

  int sayfaNo(Uri u) => int.parse(RegExp(r'page(\d+)\.png').firstMatch(u.path)![1]!);

  /// Her sayfaya PNG döndüren sahte istemci; [yanit] verilirse onu kullanır.
  SayfaIndirici kur({
    int toplam = 10,
    int paralel = 3,
    http.Response Function(http.Request r)? yanit,
    Future<void> Function()? gecikme,
  }) {
    final istemci = MockClient((r) async {
      istekler.add(r.url);
      if (gecikme != null) await gecikme();
      return yanit != null ? yanit(r) : http.Response.bytes(png(sayfaNo(r.url)), 200);
    });
    return SayfaIndirici(
        istemci: istemci,
        klasor: () async => klasor,
        kayitlar: kayitlar,
        paralel: paralel,
        toplam: toplam);
  }

  group('indir', () {
    test('doğru adresten indirir, dosyaya yazar, kaydeder ve geçici dosya bırakmaz', () async {
      final i = kur();

      await i.indir(7);

      expect(istekler.single.toString(), 'https://android.quran.com/data/width_1024/page007.png');
      final yol = kayitlar.kayit[7]!;
      expect(File(yol).readAsBytesSync(), png(7));
      expect(File('$yol.tmp').existsSync(), isFalse);
    });

    test('adres verilirse onu kullanır', () async {
      final i = kur();

      await i.indir(3, adres: 'https://ornek.test/page003.png');

      expect(istekler.single.toString(), 'https://ornek.test/page003.png');
    });

    test('200 ile dönen HTML (ağ geçidi/captive portal) görsel diye kaydedilmez', () async {
      final i = kur(yanit: (_) => http.Response('<html>Login required</html>', 200));

      await expectLater(i.indir(2), throwsA(isA<SayfaIndirmeHatasi>()));

      expect(kayitlar.kayit, isEmpty);
      expect(klasor.listSync(), isEmpty, reason: 'dosya da bırakılmaz');
    });

    test('200 dışı yanıt hata olur ve kayıt yazılmaz', () async {
      final i = kur(yanit: (_) => http.Response('yok', 404));

      await expectLater(i.indir(2), throwsA(isA<SayfaIndirmeHatasi>()));

      expect(kayitlar.kayit, isEmpty);
    });

    test('yeniden indirme mevcut dosyanın üzerine yazar', () async {
      final i = kur();
      await i.indir(4);
      final yol = kayitlar.kayit[4]!;
      File(yol).writeAsBytesSync([1, 2, 3]);

      await i.indir(4);

      expect(File(yol).readAsBytesSync(), png(4));
    });
  });

  group('eksikleriIndir: [sayfalar] verilirse yalnız o alt küme (ör. açık sure)', () {
    test('yalnız istenen sayfalardan eksik olanlar indirilir, kitabın geri kalanına dokunulmaz', () async {
      final i = kur(toplam: 20);

      await i.eksikleriIndir(sayfalar: [3, 4, 5]);

      expect(istekler.map(sayfaNo).toSet(), {3, 4, 5});
      expect(kayitlar.kayit.keys.toSet(), {3, 4, 5});
      expect(await i.indirilenSayisi(), 3);
    });

    test('istenenlerden zaten sağlam olanlara istek atılmaz', () async {
      final i = kur(toplam: 20);
      await i.indir(4);
      istekler.clear();

      await i.eksikleriIndir(sayfalar: [3, 4, 5]);

      expect(istekler.map(sayfaNo).toSet(), {3, 5});
      expect(kayitlar.kayit.keys.toSet(), {3, 4, 5});
    });

    test('istenenlerin hepsi zaten cihazdaysa hiç istek atmaz (hızlı no-op)', () async {
      final i = kur(toplam: 20);
      await i.indir(3);
      await i.indir(4);
      istekler.clear();

      await i.eksikleriIndir(sayfalar: [3, 4]);

      expect(istekler, isEmpty);
    });

    test('ilerleme KİTABIN TAMAMINDAKİ sağlam sayıyı bildirir, alt kümenin uzunluğunu değil', () async {
      final i = kur(toplam: 20);
      await i.indir(10); // hedef dışında, kitapta zaten sağlam
      final gelenler = <(int, int)>[];

      await i.eksikleriIndir(sayfalar: [3, 4, 5], ilerleme: (b, t) => gelenler.add((b, t)));

      expect(gelenler.first, (1, 20), reason: 'yalnız 10. sayfa sağlamdı');
      expect(gelenler.last, (4, 20), reason: '10 + yeni inen 3 sayfa');
    });

    test('istenen sayfalar tekrarlı ya da sırasız olsa da doğru indirilir', () async {
      final i = kur(toplam: 20);

      await i.eksikleriIndir(sayfalar: [5, 3, 5, 4]);

      expect(kayitlar.kayit.keys.toSet(), {3, 4, 5});
    });

    test('hedefte hata olursa fırlatır; tekrar çağrılınca yalnız o hedefin kalanı sürer', () async {
      var bozuk = true;
      final i = kur(toplam: 20, paralel: 1,
          yanit: (r) => bozuk && sayfaNo(r.url) == 4
              ? http.Response('hata', 500)
              : http.Response.bytes(png(sayfaNo(r.url)), 200));

      await expectLater(i.eksikleriIndir(sayfalar: [3, 4, 5]), throwsA(isA<SayfaIndirmeHatasi>()));
      expect(kayitlar.kayit.keys.toSet(), {3});

      bozuk = false;
      await i.eksikleriIndir(sayfalar: [3, 4, 5]);
      expect(kayitlar.kayit.keys.toSet(), {3, 4, 5});
    });

    test('tüm kitap isteğiyle karışmaz: önce alt küme, sonra tüm kitap istenirse geri kalan da iner', () async {
      final i = kur(toplam: 6);
      await i.eksikleriIndir(sayfalar: [2, 3]);
      istekler.clear();

      await i.eksikleriIndir();

      expect(istekler.map(sayfaNo).toSet(), {1, 4, 5, 6});
      expect(await i.indirilenSayisi(), 6);
    });
  });

  group('eksikleriIndir', () {
    test('yalnız eksik sayfaları indirir; sağlam olanlara istek atmaz', () async {
      final i = kur(toplam: 5);
      await i.indir(2);
      await i.indir(4);
      istekler.clear();

      await i.eksikleriIndir();

      expect(istekler.map(sayfaNo).toSet(), {1, 3, 5});
      expect(kayitlar.kayit.keys.toSet(), {1, 2, 3, 4, 5});
      expect(await i.indirilenSayisi(), 5);
    });

    test('ilerleme başlangıçta mevcut sayıyı bildirir, artarak toplama ulaşır', () async {
      final i = kur(toplam: 6);
      await i.indir(1);
      final gelenler = <(int, int)>[];

      await i.eksikleriIndir(ilerleme: (b, t) => gelenler.add((b, t)));

      expect(gelenler.first, (1, 6), reason: 'zaten cihazdaki 1 sayfa');
      expect(gelenler.last, (6, 6));
      final sayilar = gelenler.map((g) => g.$1).toList();
      expect(sayilar, [...sayilar]..sort(), reason: 'geriye gitmez');
      expect(gelenler.every((g) => g.$2 == 6), isTrue);
    });

    test('aynı anda en çok "paralel" kadar istek gider', () async {
      var acik = 0, enFazla = 0;
      final i = kur(
          toplam: 12,
          paralel: 3,
          gecikme: () async {
            acik++;
            if (acik > enFazla) enFazla = acik;
            await Future<void>.delayed(const Duration(milliseconds: 5));
            acik--;
          });

      await i.eksikleriIndir();

      expect(enFazla, 3);
      expect(istekler.length, 12);
    });

    test('ilk hatada durur ve fırlatır; tekrar çağrılınca kalandan sürer', () async {
      var bozuk = true;
      final i = kur(
          toplam: 8,
          paralel: 1,
          yanit: (r) => bozuk && sayfaNo(r.url) == 4
              ? http.Response('hata', 500)
              : http.Response.bytes(png(sayfaNo(r.url)), 200));

      await expectLater(i.eksikleriIndir(), throwsA(isA<SayfaIndirmeHatasi>()));

      expect(kayitlar.kayit.keys.toSet(), {1, 2, 3}, reason: '4. sayfada durdu, sonrası denenmedi');
      expect(istekler.map(sayfaNo), [1, 2, 3, 4]);

      bozuk = false;
      istekler.clear();
      await i.eksikleriIndir();

      expect(istekler.map(sayfaNo), [4, 5, 6, 7, 8], reason: '1-3 tekrar indirilmez');
      expect(await i.indirilenSayisi(), 8);
    });

    test('iptalMi true olunca hata vermeden durur; kalanlar eksik kalır', () async {
      final i = kur(toplam: 10, paralel: 1);
      var say = 0;

      await i.eksikleriIndir(
          ilerleme: (b, t) => say = b, iptalMi: () => say >= 3);

      expect(await i.indirilenSayisi(), 3);
      expect(istekler.length, 3);
    });

    test('bozuk (boş) dosya eksik sayılır ve yeniden indirilir', () async {
      final i = kur(toplam: 3);
      await i.eksikleriIndir();
      File(kayitlar.kayit[2]!).writeAsBytesSync([]);
      expect(await i.indirilenSayisi(), 2);
      istekler.clear();

      await i.eksikleriIndir();

      expect(istekler.map(sayfaNo), [2]);
      expect(await i.indirilenSayisi(), 3);
    });

    test('kayıtlı ama dosyası silinmiş sayfa eksik sayılır', () async {
      final i = kur(toplam: 3);
      await i.eksikleriIndir();
      File(kayitlar.kayit[3]!).deleteSync();

      expect(await i.indirilenSayisi(), 2);
    });
  });

  group('yenile (periyodik senkron)', () {
    test('sağlam sayfalara hiç istek atmaz (eskiden hepsi baştan iniyordu)', () async {
      final i = kur(toplam: 6);
      await i.eksikleriIndir();
      istekler.clear();

      await i.yenile();

      expect(istekler, isEmpty);
    });

    test('dosyası silinmiş kayıtlı sayfayı yeniden indirir, diğerlerine dokunmaz', () async {
      final i = kur(toplam: 5);
      await i.eksikleriIndir();
      File(kayitlar.kayit[2]!).deleteSync();
      istekler.clear();

      await i.yenile();

      expect(istekler.map(sayfaNo), [2]);
      expect(File(kayitlar.kayit[2]!).existsSync(), isTrue);
    });

    test('kayıtta olmayan sayfayı indirmez (yalnız cihazdakini korur)', () async {
      final i = kur(toplam: 5);
      await i.indir(1);
      istekler.clear();

      await i.yenile();

      expect(istekler, isEmpty);
    });

    test('yeniden indirme başarısız olursa hata fırlatmaz', () async {
      final i = kur(toplam: 3, yanit: (_) => http.Response('yok', 503));
      kayitlar.kayit[1] = '${klasor.path}/yok.png';

      await i.yenile();

      expect(istekler.length, 1);
    });
  });
}

import 'dart:convert';

import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikir.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikirmatik_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Zikir.fromJson (eski Map biçimiyle uyumlu)', () {
    test('eski uygulamanın yazdığı tam kayıt okunur', () {
      // Eski sürüm 'loop' ve 'isDefault' anahtarlarını yazıyordu.
      final z = Zikir.fromJson({
        'id': '1758400000000',
        'ad': 'Salavat',
        'sayi': 12,
        'hedef': 100,
        'imame': 25,
        'loop': 3,
        'arapca': 'ا',
        'okunusu': 'o',
        'anlami': 'a',
        'isDefault': false,
      })!;

      expect((z.id, z.ad, z.sayi, z.hedef, z.imame, z.tur),
          ('1758400000000', 'Salavat', 12, 100, 25, 3));
      expect((z.arapca, z.okunusu, z.anlami, z.varsayilan),
          ('ا', 'o', 'a', false));
      expect(z.kendiEkledigim, isTrue);
    });

    test('varsayılan sayaç: id yok, imame 33, isDefault true', () {
      final z = Zikir.fromJson({
        'ad': 'Zikirmatik',
        'sayi': 0,
        'hedef': 99,
        'imame': 33,
        'isDefault': true,
      })!;

      expect((z.varsayilan, z.kendiEkledigim, z.imame), (true, false, 33));
    });

    test('toJson eski anahtar adlarını korur ve fromJson ile gidip gelir', () {
      final z = Zikir(
          id: '7', ad: 'x', hedef: 33, sayi: 5, tur: 2, imame: 11, arapca: 'a');
      final j = z.toJson();

      expect(j.keys.toSet(), {
        'id',
        'ad',
        'sayi',
        'hedef',
        'loop',
        'imame',
        'arapca',
        'okunusu',
        'anlami',
        'isDefault'
      });
      final geri = Zikir.fromJson(json.decode(json.encode(j)))!;
      expect(geri.toJson(), j);
    });

    test('id ve imame yoksa yazılmaz (hazır zikirlerin eski biçimi)', () {
      final j = Zikir(ad: 'x', hedef: 10).toJson();

      expect(j.containsKey('id'), isFalse);
      expect(j.containsKey('imame'), isFalse);
    });

    test('bozuk değerler güvenli varsayılana döner', () {
      final z = Zikir.fromJson(
          {'ad': ' x ', 'sayi': -5, 'hedef': 0, 'imame': -1, 'loop': -2})!;
      expect((z.ad, z.sayi, z.hedef, z.imame, z.tur), ('x', 0, 99, null, 0));

      final tasan = Zikir.fromJson({'ad': 'x', 'sayi': 50, 'hedef': 10})!;
      expect((tasan.sayi, tasan.hedef), (0, 10),
          reason: 'sayaç hedefin altında olmalı');

      final metin =
          Zikir.fromJson({'ad': 'x', 'sayi': '7', 'hedef': '20', 'loop': 4.0})!;
      expect((metin.sayi, metin.hedef, metin.tur), (7, 20, 4));
    });

    test('ad yoksa ya da kayıt Map değilse null (atlanır)', () {
      expect(Zikir.fromJson({'sayi': 1}), isNull);
      expect(Zikir.fromJson({'ad': '  '}), isNull);
      expect(Zikir.fromJson('x'), isNull);
      expect(Zikir.fromJson(null), isNull);
      expect(Zikir.fromJson(5), isNull);
    });

    test('metniVar: yalnız boşluk metin sayılmaz', () {
      expect(Zikir(ad: 'x', hedef: 1, arapca: '  ').metniVar, isFalse);
      expect(Zikir(ad: 'x', hedef: 1, anlami: 'a').metniVar, isTrue);
    });
  });

  group('ZikirmatikProvider: kayıtlı veri', () {
    test('eski biçimde kaydedilmiş zikirler okunur; bozuk kayıt atlanır',
        () async {
      SharedPreferences.setMockInitialValues({
        'zikirmatik_aktif_zikirler': json.encode([
          {
            'ad': 'Zikirmatik',
            'sayi': 4,
            'hedef': 99,
            'imame': 33,
            'isDefault': true
          },
          {
            'id': '9',
            'ad': 'Benim',
            'sayi': 2,
            'hedef': 10,
            'loop': 6,
            'isDefault': false
          },
          {'sayi': 1},
          'bozuk',
          7,
        ]),
        'zikirmatik_hazir_zikirler': json.encode([
          {
            'ad': 'Salavat',
            'sayi': 0,
            'hedef': 100,
            'imame': 25,
            'isDefault': false
          },
        ]),
      });
      final p = ZikirmatikProvider();
      await pumpEventQueue();

      expect(p.aktifZikirler.map((z) => (z.ad, z.sayi, z.tur)),
          [('Zikirmatik', 4, 0), ('Benim', 2, 6)]);
      expect(p.hazirZikirler.map((z) => z.ad), ['Salavat']);
    });

    test('kayıtta varsayılan sayaç yoksa başa eklenir (silinemez kuralı)',
        () async {
      SharedPreferences.setMockInitialValues({
        'zikirmatik_aktif_zikirler': json.encode([
          {'id': '9', 'ad': 'Benim', 'sayi': 0, 'hedef': 10},
        ]),
      });
      final p = ZikirmatikProvider();
      await pumpEventQueue();

      expect(p.aktifZikirler.map((z) => z.ad), ['Zikirmatik', 'Benim']);
      expect(p.aktifZikirler.first.varsayilan, isTrue);
    });

    test('tamamen bozuk JSON varsayılanlarla devam eder (çökmez)', () async {
      SharedPreferences.setMockInitialValues(
          {'zikirmatik_aktif_zikirler': 'json değil'});
      final p = ZikirmatikProvider();
      await pumpEventQueue();

      expect(p.yuklendi, isTrue);
      expect(p.aktifZikirler.single.ad, 'Zikirmatik');
    });

    test('kaydedilen veri eski uygulamanın okuyabileceği anahtarlarla yazılır',
        () async {
      SharedPreferences.setMockInitialValues({});
      final p = ZikirmatikProvider();
      await pumpEventQueue();
      p.zikirEkle(Zikir(id: '5', ad: 'Yeni', hedef: 33, imame: 11));
      p.sayaciGuncelle(p.aktifZikirler.last, 3, tur: 2);
      await pumpEventQueue();

      final ham = (await SharedPreferences.getInstance())
          .getString('zikirmatik_aktif_zikirler')!;
      final liste = (json.decode(ham) as List).cast<Map>();
      expect(liste.last['ad'], 'Yeni');
      expect((liste.last['sayi'], liste.last['loop'], liste.last['id']),
          (3, 2, '5'));
      expect(liste.first['isDefault'], true);
    });

    test(
        'zikirGuncelle: hedef sayının altına düşerse sayaç sıfırlanır, tur korunur',
        () async {
      SharedPreferences.setMockInitialValues({});
      final p = ZikirmatikProvider();
      await pumpEventQueue();
      p.zikirEkle(Zikir(id: '5', ad: 'Yeni', hedef: 100));
      final eski = p.aktifZikirler.last;
      p.sayaciGuncelle(eski, 60, tur: 3);

      p.zikirGuncelle(eski, Zikir(id: '5', ad: 'Yeni', hedef: 50));

      expect((p.aktifZikirler.last.sayi, p.aktifZikirler.last.tur), (0, 3));
    });
  });
}

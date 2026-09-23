import 'dart:ui' show Color;

import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/features/vakitler/gokyuzu_hesabi.dart';
import 'package:flutter_test/flutter_test.dart';

// İstanbul, 20-21 Eylül 2026 (UTC+3). 20.09 saatleri telefondan okunan Diyanet
// değerleri; 21.09 için yakın örnek değerler.
GunlukVakit _gun(int gun, List<String> saatler) {
  final anlar = <Vakit, DateTime>{};
  final metinler = <Vakit, String>{};
  for (var i = 0; i < Vakit.values.length; i++) {
    final s = saatler[i].split(':').map(int.parse).toList();
    anlar[Vakit.values[i]] = DateTime.utc(2026, 9, gun, s[0] - 3, s[1]);
    metinler[Vakit.values[i]] = saatler[i];
  }
  return GunlukVakit(
      tarih: DateTime.utc(2026, 9, gun),
      kaynak: VakitKaynagi.diyanet,
      saatler: metinler,
      anlar: anlar);
}

final _gunler = [
  _gun(20, ['05:17', '06:42', '13:03', '16:29', '19:13', '20:33']),
  _gun(21, ['05:18', '06:43', '13:03', '16:28', '19:11', '20:31']),
];

/// İstanbul yerel saatinden an.
DateTime _an(int gun, int saat, int dakika, [int saniye = 0]) =>
    DateTime.utc(2026, 9, gun, saat - 3, dakika, saniye);

int _dk(int s1, int d1, int s2, int d2) => (s2 * 60 + d2) - (s1 * 60 + d1);

bool _yakin(Color a, Color b, {int tolerans = 2}) =>
    (a.r * 255 - b.r * 255).abs() <= tolerans &&
    (a.g * 255 - b.g * 255).abs() <= tolerans &&
    (a.b * 255 - b.b * 255).abs() <= tolerans;

void main() {
  group('yay (güneş ve ay)', () {
    test('gün doğumunda güneş yayın başında, öğlede tam ortasına yakın', () {
      final dogus = gokyuzuDurumu(_gunler, _an(20, 6, 42));
      expect(dogus.gunduz, isTrue);
      expect(dogus.ilerleme, 0.0);

      final ogle = gokyuzuDurumu(_gunler, _an(20, 13, 3));
      expect(ogle.gunduz, isTrue);
      // (13:03-06:42) / (19:13-06:42) = 381/751
      expect(
          ogle.ilerleme, closeTo(_dk(6, 42, 13, 3) / _dk(6, 42, 19, 13), 1e-9));
      expect(ogle.ilerleme, closeTo(0.5, 0.01));
    });

    test('gün batımında gündüz yayı biter, ay yayı başlar', () {
      final oncesi = gokyuzuDurumu(_gunler, _an(20, 19, 12, 59));
      expect(oncesi.gunduz, isTrue);
      expect(oncesi.ilerleme, closeTo(1.0, 0.001));

      final batis = gokyuzuDurumu(_gunler, _an(20, 19, 13));
      expect(batis.gunduz, isFalse);
      expect(batis.ilerleme, 0.0);
    });

    test('akşamdan sonra ay, ertesi günün gün doğumuna doğru ilerler', () {
      final s = gokyuzuDurumu(_gunler, _an(20, 20, 0));
      expect(s.gunduz, isFalse);
      // (20:00-19:13) / (ertesi 06:43 - 19:13 = 11 sa 30 dk)
      expect(s.ilerleme, closeTo(47 / 690, 1e-9));
    });

    test('gece yarısından sonra dünün akşamından başlayan yay sürer', () {
      final s = gokyuzuDurumu(_gunler, _an(21, 1, 0));
      expect(s.gunduz, isFalse);
      // 19:13 -> 01:00 = 5 sa 47 dk = 347 dk
      expect(s.ilerleme, closeTo(347 / 690, 1e-9));
    });

    test('yay, kaynağın telefonun saat diliminden bağımsız bir ana bağlı', () {
      // Aynı an, yalnızca yerel/UTC gösterimi farklı: sonuç aynı.
      final a = gokyuzuDurumu(_gunler, _an(20, 10, 0));
      final b = gokyuzuDurumu(_gunler, _an(20, 10, 0).toLocal());
      expect(b.ilerleme, a.ilerleme);
    });
  });

  group('renk', () {
    test('vakit anında o vaktin tablosundaki renk', () {
      for (final v in Vakit.values) {
        final gun = _gunler.first;
        final s = gokyuzuDurumu(_gunler, gun.anlar[v]!);
        expect(_yakin(s.ust, gokyuzuRenkleri[v]!.$1), isTrue, reason: v.ad);
        expect(_yakin(s.ufuk, gokyuzuRenkleri[v]!.$2), isTrue, reason: v.ad);
      }
    });

    test('iki vaktin tam ortasında iki rengin ortası', () {
      final ortasi = _an(20, 6, 42)
          .add(_an(20, 13, 3).difference(_an(20, 6, 42)) ~/ 2); // Güneş-Öğle
      final s = gokyuzuDurumu(_gunler, ortasi);
      final beklenen = Color.lerp(gokyuzuRenkleri[Vakit.gunes]!.$2,
          gokyuzuRenkleri[Vakit.ogle]!.$2, 0.5)!;
      expect(_yakin(s.ufuk, beklenen), isTrue);
    });

    test('vakit sınırında renk sıçramaz (bir saniye önce ve sonra aynı)', () {
      final sinirlar = [
        for (final gun in _gunler)
          for (final v in Vakit.values) gun.anlar[v]!,
      ];
      for (final an in sinirlar.skip(1)) {
        final once =
            gokyuzuDurumu(_gunler, an.subtract(const Duration(seconds: 1)));
        final sonra = gokyuzuDurumu(_gunler, an);
        expect(_yakin(once.ust, sonra.ust, tolerans: 1), isTrue, reason: '$an');
        expect(_yakin(once.ufuk, sonra.ufuk, tolerans: 1), isTrue,
            reason: '$an');
      }
    });
  });

  group('eksik veri', () {
    test('vakit hiç yoksa çökmez: gece renkleri, bilinmeyen yay', () {
      final s = gokyuzuDurumu(const [], _an(20, 12, 0));
      expect(s.ilerleme, isNull);
      expect(_yakin(s.ust, gokyuzuRenkleri[Vakit.yatsi]!.$1), isTrue);
    });

    test(
        'ilk günden önce: komşu gün bir gün kaydırılarak yaklaşıklanır, yay kaybolmaz',
        () {
      // Veri 20.09'da başlıyor; 20.09 03:00'te dünün akşamı verilerde yok.
      final s = gokyuzuDurumu(_gunler, _an(20, 3, 0));
      expect(s.gunduz, isFalse);
      // Yaklaşık akşam: 19.09 19:13 (20.09'un 19:13'ü - 1 gün); gün doğumu 20.09 06:42.
      // (03:00 - 19:13) / (06:42 - 19:13) = 467 / 689 dk
      expect(s.ilerleme, closeTo(467 / 689, 1e-9));
      expect(
          _yakin(s.ust, gokyuzuRenkleri[Vakit.yatsi]!.$1, tolerans: 12), isTrue,
          reason: 'yatsı ile imsak arasında, ikisi de gece renkleri');
    });

    test(
        'son günden sonra: sonraki gün doğumu bir gün kaydırılarak yaklaşıklanır',
        () {
      final s = gokyuzuDurumu(_gunler, _an(21, 23, 0)); // son vakit 20:31
      expect(s.gunduz, isFalse);
      // (23:00 - 19:11) / (22.09 06:43 - 21.09 19:11) = 229 / 692 dk
      expect(s.ilerleme, closeTo(229 / 692, 1e-9));
    });

    test('yaklaşıklama, verinin içindeki gerçek olayları değiştirmez', () {
      final gercek = gokyuzuDurumu(_gunler, _an(20, 13, 3));
      expect(gercek.ilerleme,
          closeTo(_dk(6, 42, 13, 3) / _dk(6, 42, 19, 13), 1e-9));
    });
  });
}

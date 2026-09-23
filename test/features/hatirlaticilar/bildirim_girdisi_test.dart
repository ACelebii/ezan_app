import 'dart:convert';

import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_tercihi.dart';
import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/bildirim_girdisi.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kaydı diske yazılıp okunmuş gibi (JSON metni üzerinden) gidiş-dönüş yapar.
BildirimGirdisi gidisDonus(BildirimGirdisi girdi) => BildirimGirdisi.fromJson(
    jsonDecode(jsonEncode(girdi.toJson())) as Map<String, dynamic>);

void main() {
  const istanbul = Konum(
      ad: 'İstanbul',
      saatDilimi: 'Europe/Istanbul',
      diyanetIlceId: 9541,
      enlem: 41.0082,
      boylam: 28.9784);

  group('VakitTercihi JSON', () {
    test('varsayılan tercih gidiş-dönüşte aynı kalır', () {
      final geri = VakitTercihi.fromJson(
          jsonDecode(jsonEncode(const VakitTercihi().toJson()))
              as Map<String, dynamic>);

      expect(geri.aladhanYontemi, isNull);
      expect(geri.hanefiIkindi, isFalse);
      expect(geri.duzeltme, isEmpty);
      expect(geri.ozet, const VakitTercihi().ozet);
    });

    test('yöntem, Hanefi ve düzeltme korunur', () {
      const tercih = VakitTercihi(
          aladhanYontemi: 3,
          hanefiIkindi: true,
          duzeltme: {Vakit.aksam: 1, Vakit.ogle: -2});

      final geri = VakitTercihi.fromJson(
          jsonDecode(jsonEncode(tercih.toJson())) as Map<String, dynamic>);

      expect(geri.aladhanYontemi, 3);
      expect(geri.hanefiIkindi, isTrue);
      expect(geri.duzeltme, {Vakit.aksam: 1, Vakit.ogle: -2});
      expect(geri.ozet, tercih.ozet);
    });

    test('bilinmeyen vakit adı ve eksik alanlar yok sayılır', () {
      final geri = VakitTercihi.fromJson({
        'duzeltme': {'aksam': 2, 'yok_boyle_vakit': 9},
      });

      expect(geri.duzeltme, {Vakit.aksam: 2});
      expect(geri.aladhanYontemi, isNull);
      expect(geri.hanefiIkindi, isFalse);
    });
  });

  group('BildirimGirdisi JSON', () {
    test('her alan gidiş-dönüşte korunur', () {
      final girdi = BildirimGirdisi(
        konum: istanbul,
        tercih:
            const VakitTercihi(aladhanYontemi: 2, duzeltme: {Vakit.imsak: -1}),
        hatirlaticilar: {
          'cuma': {'enabled': true, 'offset': 60, 'sound': 'ezan_kisa'},
          'ramazan': {'enabled': true},
        },
        vakitEzanAyarlari: {
          'ogle': {
            'enabled': true,
            'gunler': [true, false, true, true, true, true, true],
            'onceDakika': 30.0,
          },
        },
        vaktindeKilAyarlari: {
          'yatsi': {'enabled': true, 'ilkUyariDakika': 30},
        },
        ramazan: (start: DateTime(2027, 2, 8), end: DateTime(2027, 3, 8)),
        ertelemeBitisi: DateTime.utc(2026, 9, 21, 12),
      );

      final geri = gidisDonus(girdi);

      expect(geri.konum.ad, 'İstanbul');
      expect(geri.konum.diyanetIlceId, 9541);
      expect((geri.konum.enlem, geri.konum.boylam), (41.0082, 28.9784));
      expect(geri.konum.saatDilimi, 'Europe/Istanbul');
      expect(geri.tercih.ozet, girdi.tercih.ozet);
      expect(geri.hatirlaticilar, girdi.hatirlaticilar);
      expect(geri.vakitEzanAyarlari, girdi.vakitEzanAyarlari);
      expect(geri.vaktindeKilAyarlari, girdi.vaktindeKilAyarlari);
      expect(geri.ramazan!.start, DateTime.utc(2027, 2, 8));
      expect(geri.ramazan!.end, DateTime.utc(2027, 3, 8));
      expect(geri.ertelemeBitisi, DateTime.utc(2026, 9, 21, 12));
    });

    test('isteğe bağlı alanlar yoksa null kalır', () {
      final geri = gidisDonus(const BildirimGirdisi(
        konum: istanbul,
        tercih: VakitTercihi(),
        hatirlaticilar: {},
        vakitEzanAyarlari: {},
        vaktindeKilAyarlari: {},
      ));

      expect(geri.ramazan, isNull);
      expect(geri.ertelemeBitisi, isNull);
    });

    test('bozuk kayıt hata fırlatır (okuyucu bunu yakalayıp null sayar)', () {
      expect(() => BildirimGirdisi.fromJson({'konum': 'metin'}),
          throwsA(isA<TypeError>()));
      expect(() => BildirimGirdisi.fromJson({}), throwsA(isA<TypeError>()));
    });
  });
}

import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_modelleri.dart';
import 'package:ezan_vakti_uygulamasi/core/vakit/vakit_tercihi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('varsayılan tercih: Diyanet, Şafi ikindi, düzeltme yok', () {
    const t = VakitTercihi();

    expect(t.aladhanYontemi, isNull);
    expect(
        t.aladhanParametresi, 13); // Aladhan'a gidilirse Diyanet parametreleri
    expect(t.hamAnahtar, ''); // eski önbellekler geçerli kalır
  });

  test('hamAnahtar yöntem ve Hanefi\'yi ayırır, düzeltmeyi içermez', () {
    expect(const VakitTercihi(aladhanYontemi: 3).hamAnahtar, '_m3');
    expect(const VakitTercihi(hanefiIkindi: true).hamAnahtar, '_hanefi');
    expect(const VakitTercihi(aladhanYontemi: 2, hanefiIkindi: true).hamAnahtar,
        '_m2_hanefi');
    expect(const VakitTercihi(duzeltme: {Vakit.aksam: 1}).hamAnahtar, '');
  });

  test('ozet düzeltmeyi de kapsar, sıradan bağımsızdır, sıfırları yok sayar',
      () {
    const a = VakitTercihi(duzeltme: {Vakit.aksam: 1, Vakit.ogle: -2});
    const b = VakitTercihi(duzeltme: {Vakit.ogle: -2, Vakit.aksam: 1});
    const c = VakitTercihi(
        duzeltme: {Vakit.aksam: 1, Vakit.ogle: -2, Vakit.imsak: 0});

    expect(a.ozet, b.ozet);
    expect(a.ozet, c.ozet);
    expect(a.ozet, isNot(const VakitTercihi().ozet));
  });

  group('VakitTercihi.ayarlardan', () {
    const varsayilan = {
      'İmsak': 0,
      'Güneş': -7,
      'Öğle': 5,
      'İkindi': 4,
      'Akşam': 7,
      'Yatsı': 0,
    };

    VakitTercihi tercih({
      String yontem = 'Diyanet Takvimi',
      String ikindi = 'Şafi, Maliki, Hanbeli, Türkiye',
      Map<String, int> temkin = varsayilan,
    }) =>
        VakitTercihi.ayarlardan(
            yontem: yontem,
            ikindiHesabi: ikindi,
            temkin: temkin,
            varsayilanTemkin: varsayilan);

    test('varsayılan ayarlar varsayılan tercihi verir (Diyanet birebir)', () {
      final t = tercih();

      expect(t.aladhanYontemi, isNull);
      expect(t.hanefiIkindi, isFalse);
      expect(t.duzeltme, isEmpty);
      expect(t.ozet, const VakitTercihi().ozet);
    });

    test('9 hesaplama yöntemi Aladhan numaralarına eşlenir', () {
      const beklenen = {
        'Ummül Kurra': 4,
        'Kuzey Amerika (ISNA)': 2,
        'Müslim World Lig': 3,
        'Mısır': 5,
        'Karaçi İslami İlimler Üniversitesi': 1,
        'Tahran Üniversitesi': 7,
        'ITNA Ashari, Caferi': 0,
        'UOIF Fransa İslam Organizasyon Birliği': 12,
        'JAKIM (Malezya)': 17,
      };
      for (final e in beklenen.entries) {
        expect(tercih(yontem: e.key).aladhanYontemi, e.value, reason: e.key);
      }
    });

    test('bilinmeyen ve kaldırılmış yöntemler Diyanet\'e düşer', () {
      for (final yontem in [
        'Diyanet Takvimi',
        'Mısır (BIS)', // listeden kaldırıldı
        'Temkinli Takvim', // listeden kaldırıldı
        'bilinmeyen',
      ]) {
        expect(tercih(yontem: yontem).aladhanYontemi, isNull, reason: yontem);
      }
    });

    test('yalnızca "Hanefi" asr-ı sani yapar', () {
      expect(tercih(ikindi: 'Hanefi').hanefiIkindi, isTrue);
      expect(tercih(ikindi: 'Şafi, Maliki, Hanbeli, Türkiye').hanefiIkindi,
          isFalse);
    });

    test('temkin varsayılandan FARK olarak uygulanır', () {
      final t = tercih(temkin: {...varsayilan, 'Akşam': 8, 'Öğle': 3});

      expect(t.duzeltme, {Vakit.aksam: 1, Vakit.ogle: -2});
    });

    test('eksik temkin anahtarı varsayılan sayılır (düzeltme yok)', () {
      expect(tercih(temkin: {'Akşam': 7}).duzeltme, isEmpty);
      expect(tercih(temkin: {}).duzeltme, isEmpty);
    });
  });
}

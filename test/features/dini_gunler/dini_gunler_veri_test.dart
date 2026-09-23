// Gerçek veri dosyasını (assets/json/dini_gunler.json) sınar. Beklenen tarihler,
// Diyanet'in resmi Dini Günler Listesi'nden (vakithesaplama.diyanet.gov.tr,
// 21.09.2026'da okundu) alınmıştır; kod çıktısından türetilmemiştir.
import 'dart:io';

import 'package:ezan_vakti_uygulamasi/features/dini_gunler/dini_gunler_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<DiniGunlerModel> hepsi;

  setUpAll(() {
    hepsi = DiniGunlerModel.listeCoz(
        File('assets/json/dini_gunler.json').readAsStringSync());
  });

  List<DiniGunlerModel> turu(String tur) =>
      hepsi.where((g) => g.tur == tur).toList();

  DateTime gun(int y, int m, int d) => DateTime.utc(y, m, d);

  test('2024-2027 yılları var; 2027 dahil', () {
    expect(hepsi.map((g) => g.yil).toSet().toList()..sort(),
        [2024, 2025, 2026, 2027]);
  });

  test(
      'taslak metin kalmadı: her günün gerçek Türkçe ve İngilizce açıklaması var',
      () {
    for (final g in hepsi) {
      expect(g.baslik, isNotEmpty, reason: g.tur);
      expect(g.baslikEn, isNotEmpty, reason: g.tur);
      expect(g.detay.length, greaterThan(60),
          reason: '${g.tur} Türkçe açıklama');
      expect(g.detayEn.length, greaterThan(60),
          reason: '${g.tur} İngilizce açıklama');
      expect(g.detay.contains('...'), isFalse, reason: g.tur);
    }
  });

  test('Diyanet 2027 listesi (resmi tarihler)', () {
    expect(turu('miraç').where((g) => g.yil == 2027).map((g) => g.tarih),
        [gun(2027, 1, 4), gun(2027, 12, 24)]);
    expect(turu('berat').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 1, 22));
    expect(turu('ramazan').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 2, 8));
    expect(
        turu('kadir').singleWhere((g) => g.yil == 2027).tarih, gun(2027, 3, 5));
    expect(turu('arefe_ramazan').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 3, 8));
    expect(turu('ramazan_bayrami_1').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 3, 9));
    expect(turu('arefe_kurban').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 5, 15));
    expect(turu('kurban_bayrami_1').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 5, 16));
    expect(turu('kurban_bayrami_4').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 5, 19));
    expect(turu('hicri_yilbasi').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 6, 6));
    expect(turu('asure').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 6, 15));
    expect(turu('mevlid').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 8, 13));
    expect(turu('uc_aylar').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 11, 29));
    expect(turu('regaib').singleWhere((g) => g.yil == 2027).tarih,
        gun(2027, 12, 2));
  });

  test('eski uygulama verisindeki iki hata düzeltildi (2026)', () {
    // Eski veri Ramazan başlangıcını 18 Şubat, Mevlid'in hicri gününü 12 yazıyordu.
    expect(turu('ramazan').singleWhere((g) => g.yil == 2026).tarih,
        gun(2026, 2, 19));
    expect(turu('mevlid').singleWhere((g) => g.yil == 2026).hicri,
        '11 Rebiülevvel 1448');
    // 2026 listesinde eskiden hiç olmayan Regaib Kandili (Diyanet: 10 Aralık 2026).
    expect(turu('regaib').singleWhere((g) => g.yil == 2026).tarih,
        gun(2026, 12, 10));
  });

  test(
      'yıl yıl: bayramlar ardışık, kandiller kendi hicri gününde, sıra tarihe göre',
      () {
    for (final yil in [2024, 2025, 2026, 2027]) {
      final o = hepsi.where((g) => g.yil == yil).toList();
      final ramazanBayrami =
          o.where((g) => g.tur.startsWith('ramazan_bayrami_')).toList();
      final kurban =
          o.where((g) => g.tur.startsWith('kurban_bayrami_')).toList();
      expect(ramazanBayrami, hasLength(3), reason: '$yil');
      expect(kurban, hasLength(4), reason: '$yil');
      for (final grup in [ramazanBayrami, kurban]) {
        for (var i = 1; i < grup.length; i++) {
          expect(grup[i].tarih.difference(grup[i - 1].tarih).inDays, 1,
              reason: '$yil');
        }
      }
      for (final g in o) {
        if (g.tur == 'berat') {
          expect(g.hicri, startsWith('14 Şaban'), reason: '$yil');
        }
        if (g.tur == 'kadir') {
          expect(g.hicri, startsWith('26 Ramazan'), reason: '$yil');
        }
        if (g.tur == 'mevlid') {
          expect(g.hicri, startsWith('11 Rebiülevvel'), reason: '$yil');
        }
        if (g.tur == 'regaib') {
          expect(g.tarih.weekday, DateTime.thursday, reason: '$yil');
        }
      }
      final tarihler = o.map((g) => g.tarih).toList();
      expect(tarihler, [...tarihler]..sort(), reason: '$yil sıralı');
    }
  });

  test('numaralı günlerin başlığı: Türkçe "(2. Gün)", İngilizce "(Day 2)"', () {
    final g = turu('kurban_bayrami_2').first;
    expect(g.baslik, 'Kurban Bayramı (2. Gün)');
    expect(g.baslikEn, 'Eid al-Adha (Day 2)');
    expect(turu('regaib').first.baslik, 'Regaib Kandili'); // numarasız
  });

  test('gösterim: ay, hafta günü ve hicri iki dilde', () {
    final g = turu('miraç').firstWhere((g) => g.tarih == gun(2027, 1, 4));
    expect(g.gunNo, '04');
    expect((g.ayFor(false), g.haftaGunuFor(false)), ('Ocak', 'Pazartesi'));
    expect((g.ayFor(true), g.haftaGunuFor(true)), ('January', 'Monday'));
    expect(g.hicriFor(false), '26 Recep 1448');
    expect(g.hicriFor(true), '26 Rajab 1448');
    expect(DiniGunlerModel.ayAdi('Eylül', true), 'September');
    expect(DiniGunlerModel.ayAdi('Eylül', false), 'Eylül');
  });

  test(
      'ayrıntı sayfası: tam tarih iki dilde; yalnızca kandil/gece günlerinde akşam notu',
      () {
    final mirac = turu('miraç').firstWhere((g) => g.tarih == gun(2027, 1, 4));
    expect(mirac.tarihFor(false), '4 Ocak 2027, Pazartesi');
    expect(mirac.tarihFor(true), 'Monday, January 4, 2027');
    expect(mirac.kandil, isTrue);
    expect(mirac.geceNotu(false), 'Gece, bu günün akşamı başlar.');
    expect(
        mirac.geceNotu(true), 'The night begins on the evening of this day.');

    // Bayram, Aşure, Hicri Yılbaşı, Ramazan başlangıcı, Arefe ve Üç Aylar gece değildir.
    for (final tur in [
      'kurban_bayrami_1',
      'ramazan_bayrami_1',
      'asure',
      'hicri_yilbasi',
      'ramazan',
      'arefe_kurban',
      'arefe_ramazan',
      'uc_aylar'
    ]) {
      expect(turu(tur).first.kandil, isFalse, reason: tur);
      expect(turu(tur).first.geceNotu(false), isNull, reason: tur);
    }
    // Beş gece günü de işaretli.
    for (final tur in ['regaib', 'miraç', 'berat', 'kadir', 'mevlid']) {
      expect(turu(tur).every((g) => g.kandil), isTrue, reason: tur);
    }
  });

  test('bilinmeyen tür sessizce atlanmaz, veri hatası olarak fırlatılır', () {
    const bozuk =
        '{"tanimlar": {}, "gunler": [{"tarih": "2027-01-01", "tur": "yok", "hicri": "1 Recep 1448"}]}';
    expect(() => DiniGunlerModel.listeCoz(bozuk), throwsFormatException);
  });
}

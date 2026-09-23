import 'package:ezan_vakti_uygulamasi/features/hatirlaticilar/data/erteleme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final simdi = DateTime.utc(2026, 9, 20, 12);

  group('ertelemeBitisi', () {
    test('saat seçenekleri şimdiden itibaren', () {
      expect(ertelemeBitisi('1 saat', simdi, saatDilimi: 'Europe/Istanbul'),
          DateTime.utc(2026, 9, 20, 13));
      expect(ertelemeBitisi('2 saat', simdi, saatDilimi: 'Europe/Istanbul'),
          DateTime.utc(2026, 9, 20, 14));
      expect(ertelemeBitisi('4 saat', simdi, saatDilimi: 'Europe/Istanbul'),
          DateTime.utc(2026, 9, 20, 16));
      expect(ertelemeBitisi('8 saat', simdi, saatDilimi: 'Europe/Istanbul'),
          DateTime.utc(2026, 9, 20, 20));
    });

    test('gün seçenekleri şimdiden itibaren', () {
      expect(ertelemeBitisi('1 Gün', simdi, saatDilimi: 'Europe/Istanbul'),
          DateTime.utc(2026, 9, 21, 12));
      expect(ertelemeBitisi('7 Gün', simdi, saatDilimi: 'Europe/Istanbul'),
          DateTime.utc(2026, 9, 27, 12));
      expect(ertelemeBitisi('10 Gün', simdi, saatDilimi: 'Europe/Istanbul'),
          DateTime.utc(2026, 9, 30, 12));
    });

    test(
        'tarih seçici: o günün başı, SEÇİLİ ŞEHRİN saat diliminde (cihazınki değil)',
        () {
      // İstanbul hep UTC+3 (DST yok): 7 Ekim 00:00 +03:00 = 6 Ekim 21:00 UTC.
      final istanbul =
          ertelemeBitisi('7/10/2026', simdi, saatDilimi: 'Europe/Istanbul')!;
      expect(istanbul, DateTime.utc(2026, 10, 6, 21));
      expect(istanbul.isUtc, isTrue);

      // Aynı tarih, aynı "şimdi", yalnız KONUM farklı (New York, Ekim'de
      // hâlâ UTC-4): 7 Ekim 00:00 -04:00 = 7 Ekim 04:00 UTC. Sonuç İstanbul'a
      // göre 7 saat farklı çıkmalı — asıl düzeltmenin kanıtı bu: eski kod
      // (`DateTime(yil, ay, gun)`, cihazın yerel saati) test ortamının kendi
      // saat dilimine (burada UTC) göre TEK bir sonuç üretir, konuma göre hiç
      // değişmezdi.
      final newYork =
          ertelemeBitisi('7/10/2026', simdi, saatDilimi: 'America/New_York')!;
      expect(newYork, DateTime.utc(2026, 10, 7, 4));
      expect(istanbul, isNot(equals(newYork)));
    });

    test('Kapalı, tanınmayan ve geçmiş tarih: erteleme yok', () {
      expect(ertelemeBitisi('Kapalı', simdi, saatDilimi: 'Europe/Istanbul'),
          isNull);
      expect(ertelemeBitisi('bilinmeyen', simdi, saatDilimi: 'Europe/Istanbul'),
          isNull);
      expect(
          ertelemeBitisi('', simdi, saatDilimi: 'Europe/Istanbul'), isNull);
      expect(ertelemeBitisi('1/1/2020', simdi, saatDilimi: 'Europe/Istanbul'),
          isNull); // geçmiş
      expect(
          ertelemeBitisi('31/2/2027', simdi, saatDilimi: 'Europe/Istanbul'),
          isNull); // olmayan tarih
    });
  });
}

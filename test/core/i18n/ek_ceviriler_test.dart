import 'package:ezan_vakti_uygulamasi/core/i18n/ek_ceviriler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sayı ve ad içeren kalıplar', () {
    const beklenen = {
      '1 Ayet': '1 Verse',
      '286 Ayet': '286 Verses',
      '1 ayet': '1 verse',
      '7 ayet': '7 verses',
      '30. Cüz': 'Juz 30',
      '12. Sayfa': 'Page 12',
      'Sayfa 604': 'Page 604',
      '5. sure': 'Surah 5',
      '3 / 5 sure okundu': '3 / 5 surahs read',
      'Al-Baqarah 2:4 için not': 'Note for Al-Baqarah 2:4',
      'Yer İmi (Surah Al-Baqarah)': 'Bookmark (Surah Al-Baqarah)',
      'Ezberleme  ·  Surah Al-Baqarah': 'Memorization  ·  Surah Al-Baqarah',
      '5 ayet x 3 = 15 çalma': '5 verses x 3 = 15 plays',
    };
    for (final e in beklenen.entries) {
      test('"${e.key}" -> "${e.value}"',
          () => expect(ekCeviriEn(e.key), e.value));
    }
  });

  group('sağlayıcı ve depo iletileri', () {
    test('depo: ağ ve sunucu hatası iletileri', () {
      expect(
          ekCeviriEn(
              'Sure ayetleri yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'),
          'Could not load the surah verses. Check your internet connection and try again.');
      expect(
          ekCeviriEn(
              'Cüz ayetleri yüklenemedi (sunucu yanıtı: 503). Lütfen daha sonra tekrar deneyin.'),
          'Could not load the juz verses (server response: 503). Please try again later.');
    });

    test('ezber: çok büyük aralık iletisi', () {
      expect(
          ekCeviriEn(
              'Aralık ve tekrar sayısı çok büyük (6 ayet x 60 = 360 çalma; en çok 300). Aralığı daraltın ya da tekrarı azaltın.'),
          'The range and repeat count are too large (6 verses x 60 = 360 plays; at most 300). Narrow the range or reduce the repeats.');
    });
  });

  test('bilinmeyen metin null döner (olduğu gibi kalır)', () {
    expect(ekCeviriEn('Bu bir cümle'), isNull);
    expect(ekCeviriEn(''), isNull);
  });

  test('sabit sözlükte boş ya da Türkçe kalan çeviri yok', () {
    // Örnekler: her giriş var ve İngilizce harf içerir.
    for (final k in [
      'Sureler',
      'Fihrist',
      'Notlarım',
      'Ezberlemeyi Bitir',
      'Südais',
      'Mekke'
    ]) {
      final c = ekCeviriEn(k);
      expect(c, isNotNull, reason: k);
      expect(c, isNot(equals(k)), reason: '$k çevrilmemiş');
    }
  });
}

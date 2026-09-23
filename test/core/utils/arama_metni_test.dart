import 'package:ezan_vakti_uygulamasi/core/utils/arama_metni.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Türkçe harfler ve büyük/küçük harf', () {
    expect(aramaMetni('İSTANBUL'), 'istanbul');
    expect(aramaMetni('Istanbul'), 'istanbul');
    expect(aramaMetni('ığdır'), 'igdir');
    expect(aramaMetni('Iğdır'), 'igdir');
    expect(aramaMetni('ŞANLIURFA'), 'sanliurfa');
  });

  test('düzeltme işaretliler (sure adları) işaretsiz yazımla eşleşir', () {
    expect(aramaMetni('Fâtiha'), 'fatiha');
    expect(aramaMetni('Âl-i İmrân'), 'al-i imran');
    expect(aramaMetni('Nisâ'), 'nisa');
    expect(aramaMetni('En\'âm'), 'en\'am');
    expect(aramaMetni('RÛM'), 'rum');
    expect(aramaMetni('Nûr'), 'nur');
  });

  test('boşluklar kırpılır, boş metin boş kalır', () {
    expect(aramaMetni('  Bakara '), 'bakara');
    expect(aramaMetni(''), '');
  });

  group('aramaEslesmeleri (vurgu aralıkları)', () {
    String kes(String metin, List<(int, int)> a) => a.map((r) => metin.substring(r.$1, r.$2)).join('|');

    test('özgün metindeki yazımı korur: Türkçe harf ve büyük harf', () {
      const m = 'Sabırlı olun; SABIR ve Sabrı';
      final a = aramaEslesmeleri(m, ['sabir', 'sabr']);

      expect(kes(m, a), 'Sabır|SABIR|Sabr');
    });

    test('atılan harfler (ʿ ʾ) konumu kaydırmaz', () {
      const m = 'ʿAlī ve ʿAli ile ʾayet';
      final a = aramaEslesmeleri(m, ['ali']);

      expect(kes(m, a), 'Alī|Ali');
      expect(a.first.$1, 1, reason: 'baştaki ʿ atlanır, eşleşme A harfinde başlar');
    });

    test('atılan harf eşleşmenin içindeyse aralığa dahil olur', () {
      const m = 'Meʿal';

      expect(kes(m, aramaEslesmeleri(m, ['meal'])), 'Meʿal');
    });

    test('çakışan ve bitişik aralıklar birleşir; eşleşmeyen terim boş bırakır', () {
      const m = 'sabırlarından';

      expect(kes(m, aramaEslesmeleri(m, ['sabir', 'abirl', 'sabirlar'])), 'sabırlar');
      expect(aramaEslesmeleri(m, ['xyz']), isEmpty);
      expect(aramaEslesmeleri(m, ['']), isEmpty);
      expect(aramaEslesmeleri('', ['a']), isEmpty);
    });

    test('bir terimin her geçtiği yer bulunur', () {
      const m = 'iman edenler ve iman etmeyenler';

      expect(aramaEslesmeleri(m, ['iman']).map((r) => r.$1), [0, 16]);
    });

    test('İ ve I: büyük harfli Türkçe metin', () {
      const m = 'İMAN ve Iman';

      expect(kes(m, aramaEslesmeleri(m, ['iman'])), 'İMAN|Iman');
    });
  });
}

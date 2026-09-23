import 'package:ezan_vakti_uygulamasi/features/kuran/data/arama_vurgusu.dart';
import 'package:flutter_test/flutter_test.dart';

String vurgulananlar(VurguluMeal v) => v.aralar.map((a) => v.metin.substring(a.$1, a.$2)).join('|');

void main() {
  group('vurguluMeal', () {
    test('kısa metin olduğu gibi kalır, eşleşmeler işaretlenir', () {
      final v = vurguluMeal('Sabır ve namazla yardım dileyin.', ['sabir', 'sabr']);

      expect(v.metin, 'Sabır ve namazla yardım dileyin.');
      expect(vurgulananlar(v), 'Sabır');
    });

    test('eşleşme yoksa metin aynı, aralık boş', () {
      final v = vurguluMeal('Rahman ve Rahim', ['sabir']);

      expect(v.metin, 'Rahman ve Rahim');
      expect(v.aralar, isEmpty);
    });

    test('ilk eşleşme geç başlıyorsa parça eşleşmeden biraz önce başlar ve "…" ile işaretlenir', () {
      final uzun = '${'kelime ' * 40}sabırlı olun ve sabrı bırakmayın';

      final v = vurguluMeal(uzun, ['sabir', 'sabr']);

      expect(v.metin.startsWith('…'), isTrue);
      expect(v.metin.length, lessThan(uzun.length), reason: 'baştaki kısım atıldı');
      expect(v.metin, endsWith('sabırlı olun ve sabrı bırakmayın'));
      expect(vurgulananlar(v), 'sabır|sabr', reason: 'aralıklar kesilen parçaya göre kaydı');
      expect(v.aralar.first.$1, lessThan(60), reason: 'eşleşme parçanın başına yakın, görünür');
    });

    test('parça sözcük ortasından başlamaz', () {
      final uzun = '${'abcdefghij ' * 20}sabır';

      final v = vurguluMeal(uzun, ['sabir']);

      expect(v.metin.substring(1).startsWith('abcdefghij'), isTrue, reason: 'tam sözcükle başlar');
    });

    test('eşik sınırı: eşleşme eşikte başlıyorsa kesilmez, bir sonrasında kesilir', () {
      final tam = '${'x' * 90}sabır'; // eşleşme 90. karakterde
      final bir = '${'x' * 91}sabır';

      expect(vurguluMeal(tam, ['sabir']).metin, tam);
      expect(vurguluMeal(bir, ['sabir']).metin.startsWith('…'), isTrue);
    });

    test('boşluksuz uzun metinde de aralıklar doğru kalır', () {
      final uzun = '${'x' * 200}sabır';

      final v = vurguluMeal(uzun, ['sabir']);

      expect(vurgulananlar(v), 'sabır');
    });
  });
}

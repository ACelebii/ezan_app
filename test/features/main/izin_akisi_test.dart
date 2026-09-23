import 'package:ezan_vakti_uygulamasi/features/main/izin_akisi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('izinDiyaloguGerekli', () {
    bool karar({
      required bool bildirim,
      required bool tamZamanli,
      required bool soruldu,
    }) =>
        izinDiyaloguGerekli(
            bildirimVar: bildirim,
            tamZamanliVar: tamZamanli,
            dahaOnceSoruldu: soruldu);

    test('temiz kurulumda (hiç izin yok) sorulur', () {
      expect(karar(bildirim: false, tamZamanli: false, soruldu: false), isTrue);
    });

    test('yalnızca biri eksikse de sorulur (güncelleyen kullanıcı)', () {
      // Bildirim izni var, tam zamanlı alarm izni yok: en sık durum.
      expect(karar(bildirim: true, tamZamanli: false, soruldu: false), isTrue);
      expect(karar(bildirim: false, tamZamanli: true, soruldu: false), isTrue);
    });

    test('ikisi de varsa hiç sorulmaz', () {
      expect(karar(bildirim: true, tamZamanli: true, soruldu: false), isFalse);
    });

    test('bir kez sorulduysa, izin eksik olsa da tekrar sorulmaz', () {
      expect(karar(bildirim: false, tamZamanli: false, soruldu: true), isFalse);
      expect(karar(bildirim: true, tamZamanli: false, soruldu: true), isFalse);
    });
  });
}

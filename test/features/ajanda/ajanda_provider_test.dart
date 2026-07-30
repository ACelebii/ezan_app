import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/features/ajanda/ajanda_provider.dart';

void main() {
  group('AjandaProvider', () {
    test('starts on today', () {
      final provider = AjandaProvider();

      expect(provider.isBugun, isTrue);
    });

    test('sonrakiGun moves the selected date forward by one day', () {
      final provider = AjandaProvider();
      final today = provider.seciliTarih;

      provider.sonrakiGun();

      expect(provider.seciliTarih.difference(today).inDays, 1);
      expect(provider.isBugun, isFalse);
    });

    test('oncekiGun moves the selected date backward by one day', () {
      final provider = AjandaProvider();
      final today = provider.seciliTarih;

      provider.oncekiGun();

      expect(today.difference(provider.seciliTarih).inDays, 1);
      expect(provider.isBugun, isFalse);
    });

    test('buguneDon resets the selected date back to today', () {
      final provider = AjandaProvider();
      provider.sonrakiGun();
      provider.sonrakiGun();
      expect(provider.isBugun, isFalse);

      provider.buguneDon();

      expect(provider.isBugun, isTrue);
    });
  });
}

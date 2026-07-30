import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_vakti_uygulamasi/features/Kazalar/kazalar_provider.dart';

Future<KazalarProvider> _createLoadedProvider() async {
  final provider = KazalarProvider();
  await pumpEventQueue();
  return provider;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('KazalarProvider', () {
    test('starts with zero counts for every vakit', () async {
      final provider = await _createLoadedProvider();

      for (final count in provider.kazaSayilari.values) {
        expect(count, 0);
      }
      expect(provider.ikondaGoster, isFalse);
    });

    test('artir increments the given vakit and records a timestamp',
        () async {
      final provider = await _createLoadedProvider();

      provider.artir("Sabah");

      expect(provider.kazaSayilari["Sabah"], 1);
      expect(provider.sonKayitTarihleri["Sabah"], isNotEmpty);
    });

    test('artir only affects the targeted vakit', () async {
      final provider = await _createLoadedProvider();

      provider.artir("Öğle");

      expect(provider.kazaSayilari["Öğle"], 1);
      expect(provider.kazaSayilari["Sabah"], 0);
    });

    test('azalt decrements but never goes below zero', () async {
      final provider = await _createLoadedProvider();

      provider.azalt("Sabah");
      expect(provider.kazaSayilari["Sabah"], 0);

      provider.artir("Sabah");
      provider.artir("Sabah");
      provider.azalt("Sabah");
      expect(provider.kazaSayilari["Sabah"], 1);
    });

    test('topluDegerGir sets an exact value', () async {
      final provider = await _createLoadedProvider();

      provider.topluDegerGir("Yatsı", 12);

      expect(provider.kazaSayilari["Yatsı"], 12);
    });

    test('topluDegerGir ignores negative values', () async {
      final provider = await _createLoadedProvider();

      provider.topluDegerGir("Yatsı", 5);
      provider.topluDegerGir("Yatsı", -3);

      expect(provider.kazaSayilari["Yatsı"], 5);
    });

    test('ikonGosteriminiDegistir updates and notifies', () async {
      final provider = await _createLoadedProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.ikonGosteriminiDegistir(true);

      expect(provider.ikondaGoster, isTrue);
      expect(notified, isTrue);
    });

    test('counts persist across provider instances via SharedPreferences',
        () async {
      final first = await _createLoadedProvider();
      first.artir("Akşam");
      first.artir("Akşam");
      await pumpEventQueue();

      final second = await _createLoadedProvider();

      expect(second.kazaSayilari["Akşam"], 2);
    });

    test('toplamKazaSayisi sums every vakit', () async {
      final provider = await _createLoadedProvider();

      provider.artir("Sabah");
      provider.artir("Sabah");
      provider.artir("Öğle");
      provider.artir("Oruç");

      expect(provider.toplamKazaSayisi, 4);
    });
  });
}

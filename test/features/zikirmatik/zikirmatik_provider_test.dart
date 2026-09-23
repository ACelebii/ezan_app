import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikir.dart';
import 'package:ezan_vakti_uygulamasi/features/zikirmatik/zikirmatik_provider.dart';

Future<ZikirmatikProvider> _createLoadedProvider() async {
  final provider = ZikirmatikProvider();
  await pumpEventQueue();
  return provider;
}

Zikir _estagfirullah({String ad = 'Estağfirullah'}) => Zikir(
      id: '1',
      ad: ad,
      hedef: 100,
      imame: 100,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ZikirmatikProvider', () {
    test('starts with the default Zikirmatik counter and hazır zikirler',
        () async {
      final provider = await _createLoadedProvider();

      expect(provider.aktifZikirler.length, 1);
      expect(provider.aktifZikirler.first.ad, 'Zikirmatik');
      expect(provider.hazirZikirler.length, 3);
    });

    test('sayaciGuncelle updates the count in place', () async {
      final provider = await _createLoadedProvider();
      final zikir = provider.aktifZikirler.first;

      provider.sayaciGuncelle(zikir, 7);

      expect(provider.aktifZikirler.first.sayi, 7);
    });

    test('zikirEkle adds a new custom zikir to the active list', () async {
      final provider = await _createLoadedProvider();

      provider.zikirEkle(_estagfirullah());

      expect(provider.aktifZikirler.length, 2);
      expect(provider.aktifZikirler.last.ad, 'Estağfirullah');
    });

    test('zikirGuncelle replaces the zikir while keeping its count', () async {
      final provider = await _createLoadedProvider();
      provider.zikirEkle(_estagfirullah());
      final eski = provider.aktifZikirler.last;
      provider.sayaciGuncelle(eski, 4);

      provider.zikirGuncelle(eski, _estagfirullah(ad: 'Estağfirullahel Azim'));

      expect(provider.aktifZikirler.last.ad, 'Estağfirullahel Azim');
      expect(provider.aktifZikirler.last.sayi, 4);
    });

    test('aktiftenKaldir moves a zikir from active to hazır', () async {
      final provider = await _createLoadedProvider();
      final zikir = provider.aktifZikirler.first;

      provider.zikirEkle(_estagfirullah());
      final eklenen = provider.aktifZikirler.last;
      provider.aktiftenKaldir(eklenen);

      expect(provider.aktifZikirler.contains(eklenen), isFalse);
      expect(provider.hazirZikirler.contains(eklenen), isTrue);
      expect(provider.aktifZikirler.contains(zikir), isTrue);
    });

    test('hazirdanEkle moves a zikir from hazır to active', () async {
      final provider = await _createLoadedProvider();
      final hazirZikir = provider.hazirZikirler.first;

      provider.hazirdanEkle(hazirZikir);

      expect(provider.hazirZikirler.contains(hazirZikir), isFalse);
      expect(provider.aktifZikirler.contains(hazirZikir), isTrue);
    });

    test('state persists across provider instances via SharedPreferences',
        () async {
      final first = await _createLoadedProvider();
      first.sayaciGuncelle(first.aktifZikirler.first, 42);
      first.hazirdanEkle(first.hazirZikirler.first);
      await pumpEventQueue();

      final second = await _createLoadedProvider();

      expect(second.aktifZikirler.first.sayi, 42);
      expect(second.aktifZikirler.length, 2);
      expect(second.hazirZikirler.length, 2);
    });
  });
}

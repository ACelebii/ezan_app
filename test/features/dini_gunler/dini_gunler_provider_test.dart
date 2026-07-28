import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/locator.dart';
import 'package:ezan_vakti_uygulamasi/features/dini_gunler/data/dini_gunler_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/dini_gunler/dini_gunler_model.dart';
import 'package:ezan_vakti_uygulamasi/features/dini_gunler/providers/dini_gunler_provider.dart';

class _FakeDiniGunlerRepository extends DiniGunlerRepository {
  @override
  Future<List<DiniGunlerModel>> getDiniGunler() async {
    return [
      DiniGunlerModel(
          yil: 2026,
          ay: 'Ocak',
          gunNo: '1',
          gunAd: 'Perşembe',
          baslik: 'Yılbaşı',
          hicri: '',
          detay: ''),
      DiniGunlerModel(
          yil: 2026,
          ay: 'Ocak',
          gunNo: '15',
          gunAd: 'Perşembe',
          baslik: 'Regaib Gecesi',
          hicri: '',
          detay: ''),
      DiniGunlerModel(
          yil: 2026,
          ay: 'Mart',
          gunNo: '1',
          gunAd: 'Pazar',
          baslik: 'Miraç Gecesi',
          hicri: '',
          detay: ''),
      DiniGunlerModel(
          yil: 2025,
          ay: 'Aralık',
          gunNo: '31',
          gunAd: 'Çarşamba',
          baslik: 'Yıl Sonu',
          hicri: '',
          detay: ''),
    ];
  }
}

Future<DiniGunlerProvider> _createLoadedProvider() async {
  final provider = DiniGunlerProvider();
  await pumpEventQueue();
  return provider;
}

void main() {
  setUp(() {
    if (getIt.isRegistered<DiniGunlerRepository>()) {
      getIt.unregister<DiniGunlerRepository>();
    }
    getIt.registerSingleton<DiniGunlerRepository>(_FakeDiniGunlerRepository());
  });

  tearDown(() => getIt.reset());

  group('DiniGunlerProvider', () {
    test('defaults to year 2026 and loads data', () async {
      final provider = await _createLoadedProvider();

      expect(provider.isLoading, isFalse);
      expect(provider.seciliYil, 2026);
      expect(provider.yillikVeri, hasLength(3));
    });

    test('setYil filters yillikVeri to the selected year only', () async {
      final provider = await _createLoadedProvider();

      provider.setYil(2025);

      expect(provider.seciliYil, 2025);
      expect(provider.yillikVeri, hasLength(1));
      expect(provider.yillikVeri.first.baslik, 'Yıl Sonu');
    });

    test('gruplanmisVeri groups the selected year by month', () async {
      final provider = await _createLoadedProvider();

      final grouped = provider.gruplanmisVeri;

      expect(grouped.keys, containsAll(['Ocak', 'Mart']));
      expect(grouped['Ocak'], hasLength(2));
      expect(grouped['Mart'], hasLength(1));
    });
  });
}

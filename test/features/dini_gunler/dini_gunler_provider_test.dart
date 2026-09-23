import 'package:flutter_test/flutter_test.dart';
import 'package:ezan_vakti_uygulamasi/locator.dart';
import 'package:ezan_vakti_uygulamasi/features/dini_gunler/data/dini_gunler_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/dini_gunler/dini_gunler_model.dart';
import 'package:ezan_vakti_uygulamasi/features/dini_gunler/providers/dini_gunler_provider.dart';

DiniGunlerModel _gun(int y, int m, int d, String baslik) => DiniGunlerModel(
    tarih: DateTime.utc(y, m, d),
    tur: 'test',
    hicri: '',
    baslik: baslik,
    baslikEn: baslik,
    detay: '',
    detayEn: '');

class _FakeDiniGunlerRepository extends DiniGunlerRepository {
  @override
  Future<List<DiniGunlerModel>> getDiniGunler() async => [
        _gun(2026, 1, 1, 'Yılbaşı'),
        _gun(2026, 1, 15, 'Regaib Gecesi'),
        _gun(2026, 3, 1, 'Miraç Gecesi'),
        _gun(2025, 12, 31, 'Yıl Sonu'),
      ];
}

Future<DiniGunlerProvider> _createLoadedProvider(
    {DateTime Function()? simdi}) async {
  final provider = DiniGunlerProvider(simdi: simdi);
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
    test('varsayılan yıl, şimdiki yıldır ve o yılın verisi yüklenir', () async {
      final provider =
          await _createLoadedProvider(simdi: () => DateTime(2026, 9, 21));

      expect(provider.isLoading, isFalse);
      expect(provider.seciliYil, 2026);
      expect(provider.yillikVeri, hasLength(3));
    });

    test('şimdiki yılın verisi yoksa verisi olan son yıla düşer', () async {
      final provider =
          await _createLoadedProvider(simdi: () => DateTime(2031, 1, 1));

      expect(provider.seciliYil, 2026);
      expect(provider.yillikVeri, isNotEmpty);
    });

    test('yillar yalnızca verisi olan yılları sıralı listeler', () async {
      final provider =
          await _createLoadedProvider(simdi: () => DateTime(2026, 9, 21));

      expect(provider.yillar, [2025, 2026]);
    });

    test('setYil yillikVeri\'yi yalnızca seçilen yıla süzer', () async {
      final provider =
          await _createLoadedProvider(simdi: () => DateTime(2026, 9, 21));

      provider.setYil(2025);

      expect(provider.seciliYil, 2025);
      expect(provider.yillikVeri, hasLength(1));
      expect(provider.yillikVeri.first.baslik, 'Yıl Sonu');
    });

    test('gruplanmisVeri seçili yılı Türkçe ay adına göre gruplar', () async {
      final provider =
          await _createLoadedProvider(simdi: () => DateTime(2026, 9, 21));

      final grouped = provider.gruplanmisVeri;

      expect(grouped.keys, ['Ocak', 'Mart']);
      expect(grouped['Ocak'], hasLength(2));
      expect(grouped['Mart'], hasLength(1));
    });
  });
}

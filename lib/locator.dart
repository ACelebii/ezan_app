import 'package:get_it/get_it.dart';
import 'features/dini_gunler/data/dini_gunler_repository.dart';
import 'features/kutuphane/data/kutuphane_repository.dart';
import 'features/hutbe/data/hutbe_repository.dart';
import 'features/dualar/data/dualar_repository.dart';
import 'features/hatim/data/hatim_repository.dart';
import 'features/multimedya/data/multimedya_repository.dart';
import 'features/sync/sync_manager.dart';
import 'core/utils/network_service.dart';
import 'core/vakit/diyanet_kaynagi.dart';
import 'core/vakit/vakit_servisi.dart';
import 'features/kuran/data/kuran_repository.dart';

final locator = GetIt.instance;
final getIt = locator; // Eski kodların uyumluluğu için

void setupLocator() {
  // 1. Çekirdek Servisler (Core Services) - BUNLAR EKSİKTİ!
  locator.registerLazySingleton<NetworkService>(() => NetworkService());
  locator.registerLazySingleton<SyncManager>(() => SyncManager());
  locator.registerLazySingleton<KuranRepository>(() => KuranRepository());

  locator.registerLazySingleton<VakitServisi>(() => VakitServisi());
  // Diyanet yer listeleri (ülke/şehir/ilçe): seçici ve GPS eşleştirmesi aynı
  // örneği, yani aynı önbelleği kullanır (sunucu art arda isteğe 429 döner).
  locator.registerLazySingleton<DiyanetKaynagi>(() => DiyanetKaynagi());

  // 2. Repository Katmanları (Veri Çekiciler)
  locator.registerLazySingleton<DiniGunlerRepository>(
      () => DiniGunlerRepository());
  locator
      .registerLazySingleton<KutuphaneRepository>(() => KutuphaneRepository());
  locator.registerLazySingleton<HutbeRepository>(() => HutbeRepository());
  locator.registerLazySingleton<DualarRepository>(() => DualarRepository());
  locator.registerLazySingleton<HatimRepository>(() => HatimRepository());
  locator.registerLazySingleton<MultimediaRepository>(
      () => MultimediaRepository());
}

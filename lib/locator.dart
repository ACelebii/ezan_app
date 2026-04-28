import 'package:get_it/get_it.dart';
import 'features/dini_gunler/data/dini_gunler_repository.dart';
import 'features/kutuphane/data/kutuphane_repository.dart';
import 'features/vakitler/data/vakitler_repository.dart';
import 'features/zikirmatik/data/zikirmatik_repository.dart';
import 'features/hutbe/data/hutbe_repository.dart';
import 'features/dualar/data/dualar_repository.dart';
import 'features/sync/sync_manager.dart';
import 'core/utils/network_service.dart';

final locator = GetIt.instance;
final getIt = locator; // Eski kodların uyumluluğu için

void setupLocator() {
  // 1. Çekirdek Servisler (Core Services) - BUNLAR EKSİKTİ!
  locator.registerLazySingleton<NetworkService>(() => NetworkService());
  locator.registerLazySingleton<SyncManager>(() => SyncManager());

  // 2. Repository Katmanları (Veri Çekiciler)
  locator.registerLazySingleton<DiniGunlerRepository>(
      () => DiniGunlerRepository());
  locator
      .registerLazySingleton<KutuphaneRepository>(() => KutuphaneRepository());
  locator.registerLazySingleton<VakitlerRepository>(
      () => VakitlerRepository(city: 'İstanbul'));
  locator.registerLazySingleton<ZikirmatikRepository>(
      () => ZikirmatikRepository());
  locator.registerLazySingleton<HutbeRepository>(() => HutbeRepository());
  locator.registerLazySingleton<DualarRepository>(() => DualarRepository());
}

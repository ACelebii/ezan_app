import 'package:get_it/get_it.dart';
import 'features/dualar/data/dualar_repository.dart';
import 'features/hutbe/data/hutbe_repository.dart';
import 'features/kutuphane/data/kutuphane_repository.dart';
import 'features/dini_gunler/data/dini_gunler_repository.dart';
import 'features/sync/sync_manager.dart';
import 'core/utils/network_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton(() => NetworkService());
  getIt.registerLazySingleton(() => KutuphaneRepository());
  getIt.registerLazySingleton(() => DualarRepository());
  getIt.registerLazySingleton(() => HutbeRepository());
  getIt.registerLazySingleton(() => DiniGunlerRepository());
  getIt.registerLazySingleton(() => SyncManager());
}

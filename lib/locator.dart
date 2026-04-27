import 'package:get_it/get_it.dart';
import 'features/kutuphane/data/kutuphane_repository.dart';
import 'features/sync/sync_manager.dart';
import 'core/utils/network_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton(() => NetworkService());
  getIt.registerLazySingleton(() => KutuphaneRepository());
  getIt.registerLazySingleton(() => SyncManager());
}

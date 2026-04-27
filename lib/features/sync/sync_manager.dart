import '../data/repositories/kutuphane_repository.dart';
import '../features/kuran/kuran_download_service.dart';
import 'network_service.dart';
import '../providers/sync_notifier.dart';
import 'package:flutter/foundation.dart';
import '../locator.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final _networkService = getIt<NetworkService>();
  final _kutuphaneRepo = getIt<KutuphaneRepository>();
  SyncNotifier? _syncNotifier;

  void init(SyncNotifier syncNotifier) {
    _syncNotifier = syncNotifier;
    _networkService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        _sync();
      }
    });
  }

  Future<void> _sync() async {
    debugPrint("Sync started...");
    _syncNotifier?.setSyncing();
    try {
      await _kutuphaneRepo.refresh();
      await KuranDownloadService.refresh();
      debugPrint("Sync finished successfully.");
      _syncNotifier?.setSuccess();
    } catch (e) {
      debugPrint("Sync failed with error: $e");
      _syncNotifier?.setError(e.toString());
    }
  }
}

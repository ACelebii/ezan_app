import '../kutuphane/data/kutuphane_repository.dart';
import '../kuran/kuran_download_service.dart';
import '../../core/utils/network_service.dart';
import 'sync_notifier.dart';
import 'package:flutter/foundation.dart';
import '../../locator.dart';

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

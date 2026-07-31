import '../kutuphane/data/kutuphane_repository.dart';
import '../hutbe/data/hutbe_repository.dart';
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
  final _hutbeRepo = getIt<HutbeRepository>();
  SyncNotifier? _syncNotifier;
  bool _isSyncing = false;

  void init(SyncNotifier syncNotifier) {
    _syncNotifier = syncNotifier;
    _networkService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        _sync();
      }
    });
  }

  Future<void> _sync() async {
    // Ardışık bağlantı olayları (ör. wifi birkaç kez "bağlandı" bildirebilir)
    // çakışan senkronlar başlatmasın.
    if (_isSyncing) return;
    _isSyncing = true;
    debugPrint("Sync started...");
    _syncNotifier?.setSyncing();

    // Her repo kendi try/catch'inde: biri başarısız olsa bile diğerleri
    // yine de senkronlanır (önceden tek bir hata tüm zinciri durduruyordu).
    final basarisizlar = <String>[];
    try {
      await _kutuphaneRepo.refresh();
    } catch (e) {
      debugPrint("Kütüphane senkron hatası: $e");
      basarisizlar.add('Kütüphane');
    }
    try {
      await _hutbeRepo.refresh();
    } catch (e) {
      debugPrint("Hutbe senkron hatası: $e");
      basarisizlar.add('Hutbe');
    }
    try {
      await KuranDownloadService.refresh();
    } catch (e) {
      debugPrint("Kuran önbellek senkron hatası: $e");
      basarisizlar.add('Kuran');
    }

    _isSyncing = false;
    if (basarisizlar.isEmpty) {
      debugPrint("Sync finished successfully.");
      _syncNotifier?.setSuccess();
    } else {
      debugPrint("Sync finished with errors: $basarisizlar");
      _syncNotifier?.setError('${basarisizlar.join(", ")} güncellenemedi.');
    }
  }
}

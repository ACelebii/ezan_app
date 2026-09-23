// lib/core/ekran_uyanik.dart

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Sayaç ekranı açıkken telefonun ekranı kararmasın (zikir sayarken ekrana
/// sürekli bakılmaz ve dokunuş sayılsa da ekran kapanma süresi dolabilir).
/// Ekranlar `initState`te [ac], `dispose`ta [kapat] çağırır.
class EkranUyanik {
  /// Gerçek işlemi yapar; testte sahtesiyle değiştirilir.
  @visibleForTesting
  static Future<void> Function(bool acik) ayarla =
      (acik) => WakelockPlus.toggle(enable: acik);

  static Future<void> ac() => _dene(true);

  static Future<void> kapat() => _dene(false);

  /// Ayar yapılamazsa (eklenti yok vb.) sayaç yine çalışsın.
  static Future<void> _dene(bool acik) async {
    try {
      await ayarla(acik);
    } catch (e) {
      debugPrint('Ekran uyanık tutma ayarı yapılamadı: $e');
    }
  }
}

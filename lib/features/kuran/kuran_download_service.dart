import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ezan_vakti_uygulamasi/core/local_db.dart';

import 'data/sayfa_indirici.dart';

/// Mushaf sayfa görsellerinin cihaz önbelleği. Asıl iş [SayfaIndirici]dedir
/// (doğrulama, atomik yazma, toplu indirme); bu sınıf uygulamanın tek örneğini
/// ve eski statik çağrıları (ekran, senkron yöneticisi, arka plan görevi) tutar.
class KuranDownloadService {
  static final SayfaIndirici varsayilan = SayfaIndirici(
    istemci: http.Client(),
    klasor: getApplicationDocumentsDirectory,
    kayitlar: SqfliteSayfaKayitlari(),
  );

  /// Tek sayfayı indirir; görsel değilse ya da HTTP hatasında fırlatır.
  static Future<void> downloadPage(int pageNumber, String url) =>
      varsayilan.indir(pageNumber, adres: url);

  static Future<String?> getPagePath(int pageNumber) async {
    final db = await LocalDatabase.instance.database;
    final result = await db.query(
      'kuran_pages',
      where: 'page_number = ? AND is_downloaded = 1',
      whereArgs: [pageNumber],
    );

    if (result.isNotEmpty) {
      return result.first['local_path'] as String?;
    }
    return null;
  }

  /// Periyodik arka plan senkronizasyonu (bkz. sync_manager.dart): yalnızca
  /// dosyası silinmiş/bozulmuş sayfaları yeniden indirir. Sağlam sayfalara
  /// dokunmaz, ağ kullanmaz.
  static Future<void> refresh() => varsayilan.yenile();
}

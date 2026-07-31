import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ezan_vakti_uygulamasi/core/local_db.dart';

class KuranDownloadService {
  static Future<void> downloadPage(int pageNumber, String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/kuran_page_$pageNumber.png');
      await file.writeAsBytes(response.bodyBytes);

      final db = await LocalDatabase.instance.database;
      await db.update(
        'kuran_pages',
        {'local_path': file.path, 'is_downloaded': 1},
        where: 'page_number = ?',
        whereArgs: [pageNumber],
      );
    }
  }

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

  /// Daha önce indirilmiş sayfaları yeniden indirir; böylece periyodik
  /// arka plan senkronizasyonu (bkz. sync_manager.dart) çevrimdışı
  /// önbelleği güncel/bütün tutar. Ağ yoksa mevcut yerel kopyalar
  /// dokunulmadan kalır.
  static Future<void> refresh() async {
    final db = await LocalDatabase.instance.database;
    final downloaded =
        await db.query('kuran_pages', where: 'is_downloaded = 1');
    for (final row in downloaded) {
      final pageNumber = row['page_number'] as int;
      final pageStr = pageNumber.toString().padLeft(3, '0');
      final url = "https://android.quran.com/data/width_1024/page$pageStr.png";
      try {
        await downloadPage(pageNumber, url);
      } catch (_) {
        // Ağ yoksa/indirme başarısız olursa mevcut yerel kopya korunur.
      }
    }
  }
}

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../data/local_db.dart';

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

  static Future<void> refresh() async {
    // Sync logic (optional, e.g., check for updates)
  }
}

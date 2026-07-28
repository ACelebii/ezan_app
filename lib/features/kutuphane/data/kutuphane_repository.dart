// KESİN ÇÖZÜM: Dosya yollarını doğrudan paket adı üzerinden veriyoruz
import 'package:ezan_vakti_uygulamasi/features/kutuphane/kutuphane_model.dart';
import 'kutuphane_db_helper.dart';

class KutuphaneRepository {
  final dbHelper = KutuphaneDbHelper.instance;

  // main.dart ve sync_manager.dart'ın çökmesini engelleyen sahte yenileme metodu.
  Future<void> refresh() async {
    // Artık veritabanımız offline (yerel) olduğu için internetten bir şey çekmiyoruz.
    return;
  }

  // 1. Ana Ekran için
  Future<List<LibraryNode>> getAnaKategoriler() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kutuphane',
      where: 'parent_id IS NULL',
    );

    return maps
        .map((e) => LibraryNode(
              id: e['id'] as int,
              title: e['title'] as String,
              imagePath: e['image_path'] as String,
              isArticle: (e['is_article'] as int) == 1,
            ))
        .toList();
  }

  // 2. Tıklanan kartın alt klasörleri için
  Future<List<LibraryNode>> getAltKategoriler(int parentId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kutuphane',
      where: 'parent_id = ?',
      whereArgs: [parentId],
    );

    return maps
        .map((e) => LibraryNode(
              id: e['id'] as int,
              title: e['title'] as String,
              imagePath: e['image_path'] as String,
              isArticle: (e['is_article'] as int) == 1,
            ))
        .toList();
  }

  // 3. Okuma sayfasındaki asıl metni getirmek için
  Future<String> getMakaleIcerigi(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'kutuphane',
      columns: ['content'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty && maps.first['content'] != null) {
      return maps.first['content'].toString();
    }
    return "İçerik bulunamadı.";
  }
}

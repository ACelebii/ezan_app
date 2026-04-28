import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/kutuphane/kutuphane_model.dart';
import 'package:ezan_vakti_uygulamasi/core/utils/assets_constants.dart';
import 'package:ezan_vakti_uygulamasi/core/local_db.dart';
import '../../../core/utils/result.dart';

class KutuphaneRepository extends BaseRepository<List<LibraryNode>> {
  final dbHelper = LocalDatabase.instance;

  @override
  Future<List<LibraryNode>> fetchFromCache() async {
    final db = await dbHelper.database;
    final data = await db.query('library_items', where: 'parent_id IS NULL');

    return data
        .map((item) => LibraryNode(
              title: item['title'] as String,
              imagePath: item['image_path'] as String,
              content: item['content'] as String?,
            ))
        .toList();
  }

  @override
  Future<List<LibraryNode>> fetchFromRemote() async {
    // TODO: Replace hardcoded items with real API fetch.
    return _getHardcodedItems();
  }

  @override
  Future<void> saveToCache(List<LibraryNode> data) async {
    final db = await LocalDatabase.instance.database;
    await db.delete('library_items');
    for (var item in data) {
      await _insertItem(item);
    }
  }

  Future<Result<List<LibraryNode>>> getLibraryItems() async {
    try {
      final cached = await fetchFromCache();
      if (cached.isNotEmpty) return Result.success(cached);

      final remote = await fetchFromRemote();
      await saveToCache(remote);
      return Result.success(remote);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<void> _insertItem(LibraryNode item, {int? parentId}) async {
    final db = await LocalDatabase.instance.database;
    final id = await db.insert('library_items', {
      'title': item.title,
      'image_path': item.imagePath,
      'content': item.content,
      'parent_id': parentId,
    });

    if (item.children != null) {
      for (var child in item.children!) {
        await _insertItem(child, parentId: id);
      }
    }
  }

  List<LibraryNode> _getHardcodedItems() {
    return [
      LibraryNode(title: "Yâsîn", imagePath: Assets.yasinKapak),
      LibraryNode(title: "Tesbihat", imagePath: Assets.tesbihatKapak),
      LibraryNode(
          title: "Oruç",
          imagePath: Assets.orucKapak,
          children: getOrucAltKategorileri()),
      LibraryNode(title: "Namaz Hocası", imagePath: Assets.namazKapak),
      LibraryNode(title: "İlmihal", imagePath: Assets.ilmihalKapak),
      LibraryNode(title: "Dua", imagePath: Assets.duaKapak),
    ];
  }

  List<LibraryNode> getOrucAltKategorileri() {
    return [
      LibraryNode(
          title: "Oruç hakkında tüm bilgiler",
          imagePath: Assets.orucBilgi,
          children: [
            LibraryNode(
                title: "Oruca niyet ne zaman ve nasıl yapılır?",
                imagePath: Assets.orucNiyet,
                content:
                    "Oruca kalben niyet etmek yeterlidir. Ancak dille de söylenmesi sünnettir..."),
            LibraryNode(
                title: "Orucun Mahiyeti ve Çeşitleri",
                imagePath: Assets.orucMahiyet,
                content:
                    "Oruç, imsak vaktinden iftar vaktine kadar ibadet niyetiyle yeme, içme ve cinsel ilişkiden uzak durmaktır...")
          ]),
      LibraryNode(
          title: "Kuran-ı Kerim'de Oruç",
          imagePath: Assets.kuranOruc,
          content:
              "Kuran-ı Kerim'de oruç ile ilgili ayetler Bakara suresinde yer almaktadır..."),
    ];
  }
}

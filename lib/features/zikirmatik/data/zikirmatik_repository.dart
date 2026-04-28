import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';

class ZikirmatikRepository extends BaseRepository<int> {
  static const String _cacheKey = 'zikirmatik_count';

  @override
  Future<int> fetchFromRemote() async => 0; // No remote for Zikirmatik count

  @override
  Future<int?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheKey) ?? 0;
  }

  @override
  Future<void> saveToCache(int data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheKey, data);
  }
}

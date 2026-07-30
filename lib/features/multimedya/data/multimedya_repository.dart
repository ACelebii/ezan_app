import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_model.dart';

class MultimediaRepository extends BaseRepository<List<MultimediaItem>> {
  static const String _cacheKey = 'multimedya_cache';

  @override
  Future<List<MultimediaItem>> fetchFromRemote() async {
    try {
      final snapshot = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: dotenv.env['FIREBASE_DB_ID'] ?? 'default',
      ).collection('multimedya').get(const GetOptions(source: Source.server));

      return snapshot.docs
          .map((doc) => MultimediaItem.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Multimedya yüklenemedi: $e");
    }
  }

  @override
  Future<List<MultimediaItem>?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    if (cachedData == null) return null;

    final data = json.decode(cachedData);
    return (data as List)
        .map((e) => MultimediaItem.fromCache(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveToCache(List<MultimediaItem> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(data.map((e) => e.toCache()).toList());
    await prefs.setString(_cacheKey, encoded);
  }

  // Zaten çekilmiş listeyi türe göre filtreler (yeni Firestore okuması yapmaz).
  List<MultimediaItem> ofType(List<MultimediaItem> all, MultimediaType t) {
    final list = all.where((e) => e.type == t).toList();
    list.sort((a, b) => a.sira.compareTo(b.sira));
    return list;
  }

  // Kategoriye göre gruplar; satır sırası, o kategorideki en küçük sira'ya göre belirlenir.
  Map<String, List<MultimediaItem>> groupByCategory(
      List<MultimediaItem> typed) {
    final Map<String, List<MultimediaItem>> grouped = {};
    for (final item in typed) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final aMin = a.value.map((e) => e.sira).reduce((x, y) => x < y ? x : y);
        final bMin = b.value.map((e) => e.sira).reduce((x, y) => x < y ? x : y);
        return aMin.compareTo(bMin);
      });
    return {for (final e in sortedEntries) e.key: e.value};
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/kutuphane/kutuphane_model.dart';

class KutuphaneRepository extends BaseRepository<List<LibraryNode>> {
  static const String _cacheKey = 'kutuphane_cache';

  @override
  Future<List<LibraryNode>> fetchFromRemote() async {
    try {
      final snapshot = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: dotenv.env['FIREBASE_DB_ID'] ?? 'default',
      ).collection('kutuphane').get(const GetOptions(source: Source.server));

      return snapshot.docs
          .map((doc) => LibraryNode.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Kütüphane yüklenemedi: $e");
    }
  }

  @override
  Future<List<LibraryNode>?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    if (cachedData == null) return null;

    final data = json.decode(cachedData);
    return (data as List)
        .map((e) => LibraryNode.fromCache(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveToCache(List<LibraryNode> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(data.map((e) => e.toCache()).toList());
    await prefs.setString(_cacheKey, encoded);
  }

  // 1. Ana ekran için üst düzey kategoriler
  Future<List<LibraryNode>> getAnaKategoriler() async {
    final all = await getData();
    final list = all.where((e) => e.parentId == null).toList();
    list.sort((a, b) {
      final siraCompare = a.sira.compareTo(b.sira);
      return siraCompare != 0 ? siraCompare : a.title.compareTo(b.title);
    });
    return list;
  }

  // 2. Tıklanan kartın alt ögeleri için
  Future<List<LibraryNode>> getAltKategoriler(String parentId) async {
    final all = await getData();
    final list = all.where((e) => e.parentId == parentId).toList();
    list.sort((a, b) {
      final siraCompare = a.sira.compareTo(b.sira);
      return siraCompare != 0 ? siraCompare : a.title.compareTo(b.title);
    });
    return list;
  }
}

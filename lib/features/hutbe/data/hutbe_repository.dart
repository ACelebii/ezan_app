import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/hutbe/hutbe_page.dart';

class HutbeRepository extends BaseRepository<List<HutbeItem>> {
  static const String _cacheKey = 'hutbeler_cache';

  @override
  Future<List<HutbeItem>> fetchFromRemote() async {
    try {
      var snapshot = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: dotenv.env['FIREBASE_DB_ID'] ?? 'default',
      ).collection('hutbeler').get(const GetOptions(source: Source.server));

      return snapshot.docs
          .map((doc) => HutbeItem.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Hutbeler yüklenemedi: $e");
    }
  }

  @override
  Future<List<HutbeItem>?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    if (cachedData == null) return null;

    final data = json.decode(cachedData);
    return (data as List).map((i) => HutbeItem.fromFirestore(i)).toList();
  }

  @override
  Future<void> saveToCache(List<HutbeItem> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(data
        .map((e) => {
              'baslik': e.baslik,
              'tarih': e.tarih,
              'resimUrl': e.resimUrl,
              'pdfUrl': e.pdfUrl,
            })
        .toList());
    await prefs.setString(_cacheKey, encoded);
  }
}

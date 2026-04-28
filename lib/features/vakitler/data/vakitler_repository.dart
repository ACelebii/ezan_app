import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';

class VakitlerRepository extends BaseRepository<Map<String, dynamic>> {
  final String city;
  static const String _cacheKey = 'vakitler_cache';

  VakitlerRepository({required this.city});

  @override
  Future<Map<String, dynamic>> fetchFromRemote() async {
    // Simplified fetching logic for demonstration
    String url =
        'https://api.aladhan.com/v1/timingsByCity?city=$city&country=Turkey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data']['timings'];
    }
    throw Exception("Vakitler yüklenemedi");
  }

  @override
  Future<Map<String, dynamic>?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    return cachedData != null
        ? Map<String, dynamic>.from(json.decode(cachedData))
        : null;
  }

  @override
  Future<void> saveToCache(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode(data));
  }
}

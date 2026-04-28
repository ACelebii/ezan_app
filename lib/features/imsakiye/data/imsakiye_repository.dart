import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';

class ImsakiyeRepository extends BaseRepository<List<dynamic>> {
  final String city;
  final int method;
  static const String _cacheKey = 'imsakiye_cache';

  ImsakiyeRepository({required this.city, required this.method});

  @override
  Future<List<dynamic>> fetchFromRemote() async {
    // Simplified fetching logic for demonstration
    String url =
        'https://api.aladhan.com/v1/calendarByCity?city=$city&country=Turkey&method=$method';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    throw Exception("İmsakiye yüklenemedi");
  }

  @override
  Future<List<dynamic>?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    return cachedData != null ? json.decode(cachedData) : null;
  }

  @override
  Future<void> saveToCache(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, json.encode(data));
  }
}

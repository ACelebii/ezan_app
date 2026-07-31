import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';

class ImsakiyeRepository extends BaseRepository<List<dynamic>> {
  final String city;
  final int method;
  final int month;
  final int year;

  ImsakiyeRepository({
    required this.city,
    required this.method,
    required this.month,
    required this.year,
  });

  // Şehir/yöntem/ay/yıl birleşimine özel: aksi halde farklı bir şehir ya da
  // ayın önbelleği aynı tek anahtarın üzerine yazar ve yanlış veri gösterir.
  String get _cacheKey => 'imsakiye_cache_${city}_${method}_${month}_$year';

  @override
  Future<List<dynamic>> fetchFromRemote() async {
    final url = 'https://api.aladhan.com/v1/calendarByCity'
        '?city=${Uri.encodeComponent(city)}&country=Turkey'
        '&method=$method&month=$month&year=$year';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    throw Exception("İmsakiye yüklenemedi (${response.statusCode})");
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

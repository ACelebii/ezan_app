import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ezan_vakti_uygulamasi/core/repositories/base_repository.dart';
import 'package:ezan_vakti_uygulamasi/features/dualar/dualar_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DualarRepository extends BaseRepository<List<DuaCategory>> {
  static const String _cacheKey = 'dualar_cache';

  @override
  Future<List<DuaCategory>> fetchFromRemote() async {
    final String response = await rootBundle.loadString('assets/dualar.json');
    final data = json.decode(response);
    return (data as List).map((i) => DuaCategory.fromJson(i)).toList();
  }

  @override
  Future<List<DuaCategory>?> fetchFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString(_cacheKey);
    if (cachedData == null) return null;

    final data = json.decode(cachedData);
    return (data as List).map((i) => DuaCategory.fromJson(i)).toList();
  }

  @override
  Future<void> saveToCache(List<DuaCategory> data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(data.map((e) => e.toJson()).toList());
    await prefs.setString(_cacheKey, encoded);
  }
}

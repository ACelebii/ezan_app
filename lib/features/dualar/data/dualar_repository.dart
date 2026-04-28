import 'dart:convert';
import 'package:flutter/services.dart';
import '../dualar_model.dart';
import '../../../core/utils/result.dart';

class DualarRepository {
  Future<Result<List<DuaCategory>>> getDualar() async {
    try {
      final String response = await rootBundle.loadString('assets/dualar.json');
      final data = json.decode(response) as List<dynamic>;

      final resultData =
          data.map((json) => DuaCategory.fromJson(json)).toList();
      return Success(resultData);
    } catch (e) {
      return Failure("Dualar yüklenirken bir hata oluştu.",
          exception: e is Exception ? e : Exception(e.toString()));
    }
  }
}

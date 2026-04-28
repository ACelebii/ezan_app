import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../dini_gunler_model.dart';

class DiniGunlerRepository {
  Future<List<DiniGunlerModel>> getDiniGunler() async {
    try {
      // TODO: API'den veriyi çekmeye çalış.
      // API çökerse veya internet yoksa catch bloğuna düşecek.
      // Şimdilik sadece assets'ten okuyoruz.
      return await _fetchFromAssets();
    } catch (e) {
      // Hata durumunda (veya internet yoksa) lokal (asset) veriyi getir.
      return await _fetchFromAssets();
    }
  }

  Future<List<DiniGunlerModel>> _fetchFromAssets() async {
    final String response =
        await rootBundle.loadString('assets/json/dini_gunler.json');
    final List<dynamic> data = await json.decode(response);
    return data.map((item) => DiniGunlerModel.fromJson(item)).toList();
  }
}

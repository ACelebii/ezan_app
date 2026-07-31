import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../dini_gunler_model.dart';

class DiniGunlerRepository {
  /// Veri sabit bir asset'ten (assets/json/dini_gunler.json) okunur; uzak
  /// bir kaynak yok, dolayısıyla okuma başarısız olursa (bozuk JSON gibi)
  /// tekrar denemenin bir anlamı yoktur — hatayı olduğu gibi yukarı fırlatır.
  Future<List<DiniGunlerModel>> getDiniGunler() async {
    try {
      return await _fetchFromAssets();
    } catch (e) {
      debugPrint("Dini günler verisi okunamadı: $e");
      rethrow;
    }
  }

  Future<List<DiniGunlerModel>> _fetchFromAssets() async {
    final String response =
        await rootBundle.loadString('assets/json/dini_gunler.json');
    final List<dynamic> data = await json.decode(response);
    return data.map((item) => DiniGunlerModel.fromJson(item)).toList();
  }
}

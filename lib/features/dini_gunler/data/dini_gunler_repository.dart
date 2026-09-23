import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../dini_gunler_model.dart';

class DiniGunlerRepository {
  /// Veri sabit bir asset'ten (assets/json/dini_gunler.json, Diyanet'in resmi
  /// listesinden `tools/dini_gunler_uret.py` ile üretilir) okunur; uzak bir
  /// kaynak yok, dolayısıyla okuma başarısız olursa (bozuk JSON gibi) tekrar
  /// denemenin bir anlamı yoktur; hatayı olduğu gibi yukarı fırlatır.
  Future<List<DiniGunlerModel>> getDiniGunler() async {
    try {
      final metin = await rootBundle.loadString('assets/json/dini_gunler.json');
      return DiniGunlerModel.listeCoz(metin);
    } catch (e) {
      debugPrint("Dini günler verisi okunamadı: $e");
      rethrow;
    }
  }
}

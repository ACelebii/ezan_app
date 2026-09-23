// lib/features/kuran/data/arama_vurgusu.dart

import '../../../core/utils/arama_metni.dart';

/// Arama sonucunda gösterilecek meal parçası ve içinde vurgulanacak aralıklar.
class VurguluMeal {
  const VurguluMeal(this.metin, this.aralar);

  final String metin;

  /// [metin] içindeki `[başlangıç, bitiş)` aralıkları, sıralı ve çakışmasız.
  final List<(int, int)> aralar;
}

/// [meal] içinde [terimler]in geçtiği yerleri bulur. Sonuç satırı birkaç satırla
/// sınırlı olduğundan, ilk eşleşme [esik] karakterden sonra başlıyorsa eşleşmenin
/// [once] karakter öncesinden ("…" ile) başlayan bir parça verilir; yoksa vurgu
/// kesilen kısımda kalır ve hiç görünmezdi.
VurguluMeal vurguluMeal(String meal, Iterable<String> terimler,
    {int esik = 90, int once = 40}) {
  final aralar = aramaEslesmeleri(meal, terimler);
  if (aralar.isEmpty || aralar.first.$1 <= esik) return VurguluMeal(meal, aralar);

  final ilk = aralar.first.$1;
  final baslangic = ilk - once;
  // Sözcük ortasından kesmemek için eşleşmeden önceki ilk boşluktan başla.
  final bosluk = meal.indexOf(' ', baslangic);
  final kes = bosluk >= 0 && bosluk < ilk ? bosluk + 1 : baslangic;
  return VurguluMeal('…${meal.substring(kes)}',
      [for (final a in aralar) (a.$1 - kes + 1, a.$2 - kes + 1)]);
}

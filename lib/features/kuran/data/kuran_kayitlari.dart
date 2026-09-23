// lib/features/kuran/data/kuran_kayitlari.dart

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Bir ayet için kullanıcı kaydı: favori işareti ve/veya not. Ayetin metni
/// kaydın içinde saklanır; böylece Favori ve Not sayfaları internetsiz de okunur.
class AyetKaydi {
  const AyetKaydi({
    required this.verseKey,
    required this.sureAdi,
    required this.arapca,
    required this.meal,
    this.mealEn = '',
    this.favori = false,
    this.not = '',
  });

  /// "2:255" (sure:ayet).
  final String verseKey;
  final String sureAdi;
  final String arapca;
  final String meal;

  /// İngilizce meal; eski kayıtlarda boş (o zaman Türkçe meal gösterilir).
  final String mealEn;
  final bool favori;
  final String not;

  int get sureId => int.parse(verseKey.split(':').first);
  int get ayetNo => int.parse(verseKey.split(':').last);

  /// Ne favori ne de not kaldıysa kayıt silinir.
  bool get bos => !favori && not.isEmpty;

  AyetKaydi kopya({bool? favori, String? not, String? mealEn}) => AyetKaydi(
        verseKey: verseKey,
        sureAdi: sureAdi,
        arapca: arapca,
        meal: meal,
        mealEn: mealEn ?? this.mealEn,
        favori: favori ?? this.favori,
        not: not ?? this.not,
      );

  Map<String, dynamic> toJson() => {
        'verse_key': verseKey,
        'sure': sureAdi,
        'arapca': arapca,
        'meal': meal,
        if (mealEn.isNotEmpty) 'meal_en': mealEn,
        'favori': favori,
        'not': not,
      };

  /// Bozuk kayıt için null döner (uygulama açılışta çökmez).
  static AyetKaydi? fromJson(Object? j) {
    if (j is! Map) return null;
    final anahtar = j['verse_key'];
    if (anahtar is! String || !RegExp(r'^\d{1,3}:\d{1,3}$').hasMatch(anahtar)) {
      return null;
    }
    return AyetKaydi(
      verseKey: anahtar,
      sureAdi: j['sure']?.toString() ?? '',
      arapca: j['arapca']?.toString() ?? '',
      meal: j['meal']?.toString() ?? '',
      mealEn: j['meal_en']?.toString() ?? '',
      favori: j['favori'] == true,
      not: j['not']?.toString() ?? '',
    );
  }
}

/// Okuma listesindeki bir sure ve okundu işareti.
class OkumaOgesi {
  const OkumaOgesi({required this.sureId, this.okundu = false});

  final int sureId;
  final bool okundu;

  OkumaOgesi kopya({bool? okundu}) =>
      OkumaOgesi(sureId: sureId, okundu: okundu ?? this.okundu);

  Map<String, dynamic> toJson() => {'sure_id': sureId, 'okundu': okundu};

  static OkumaOgesi? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['sure_id'];
    if (id is! int || id < 1 || id > 114) return null;
    return OkumaOgesi(sureId: id, okundu: j['okundu'] == true);
  }
}

/// Favori/not ve okuma listesinin cihazdaki (SharedPreferences) saklanışı.
/// Bozuk ya da eksik kayıt boş liste sayılır.
class KuranKayitlari {
  static const _ayetAnahtari = 'kuran_ayet_kayitlari';
  static const _okumaAnahtari = 'kuran_okuma_listesi';

  static Future<List<AyetKaydi>> ayetleriOku() =>
      _oku(_ayetAnahtari, AyetKaydi.fromJson);

  static Future<void> ayetleriYaz(List<AyetKaydi> kayitlar) =>
      _yaz(_ayetAnahtari, kayitlar.map((k) => k.toJson()).toList());

  static Future<List<OkumaOgesi>> okumaOku() =>
      _oku(_okumaAnahtari, OkumaOgesi.fromJson);

  static Future<void> okumaYaz(List<OkumaOgesi> ogeler) =>
      _yaz(_okumaAnahtari, ogeler.map((o) => o.toJson()).toList());

  static Future<List<T>> _oku<T>(
      String anahtar, T? Function(Object?) coz) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metin = prefs.getString(anahtar);
      if (metin == null) return [];
      final liste = json.decode(metin);
      if (liste is! List) return [];
      return [
        for (final e in liste)
          if (coz(e) case final T oge) oge,
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _yaz(
      String anahtar, List<Map<String, dynamic>> liste) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(anahtar, json.encode(liste));
  }
}

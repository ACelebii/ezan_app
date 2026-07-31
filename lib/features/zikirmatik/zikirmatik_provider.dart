import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcının zikir listesini (aktif + hazır) ve her zikrin sayacını
/// SharedPreferences'a kalıcı olarak yazar. Kök seviyede (main.dart) tek
/// örnek olarak tutulur ki `/zikirmatik` ve `/zikirmatik/sayac` aynı veriyi
/// paylaşsın.
class ZikirmatikProvider extends ChangeNotifier {
  static const _aktifKey = 'zikirmatik_aktif_zikirler';
  static const _hazirKey = 'zikirmatik_hazir_zikirler';
  static const _gorunumKey = 'zikirmatik_gorunum_turu';
  static const _tesbihRengiKey = 'zikirmatik_tesbih_rengi';

  int gorunumTuru = 1;
  int tesbihRengi = 3;

  List<Map<String, dynamic>> aktifZikirler = [
    {"ad": "Zikirmatik", "sayi": 0, "hedef": 99, "imame": 33, "isDefault": true},
  ];

  List<Map<String, dynamic>> hazirZikirler = [
    {
      "ad": "100 Sübhânellâhi",
      "sayi": 0,
      "hedef": 100,
      "imame": 100,
      "arapca": "سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ سُبْحَانَ اللّٰهِ الْعَظِيمِ",
      "okunusu": "Sübhânellâhi ve bi hamdihî sübhânellâhil azîm",
      "anlami": "Allah'ü Teala'yı tesbih ederim, hamd O'na mahsustur.",
      "isDefault": false
    },
    {
      "ad": "99 Lâ havle",
      "sayi": 0,
      "hedef": 99,
      "imame": 99,
      "arapca":
          "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ الْعَلِيِّ الْعَظِيمِ",
      "okunusu": "Lâ havle ve lâ kuvvete illâ billâhil aliyyil azîm",
      "anlami": "Bütün kudret ve kuvvet, Aliyy ve Azîm olan Allah'a aittir.",
      "isDefault": false
    },
    {
      "ad": "Salavat",
      "sayi": 0,
      "hedef": 100,
      "imame": 25,
      "arapca":
          "اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى اٰلِ سَيِّدِنَا مُحَمَّدٍ",
      "okunusu":
          "Allahümme Salli Ala Seyyidina Muhammedin ve Ala Ali Seyyidina Muhammed",
      "anlami": "Allah'ım, efendimiz Hz. Muhammed'e ve aline salat eyle.",
      "isDefault": false
    },
  ];

  bool _yuklendi = false;
  bool get yuklendi => _yuklendi;

  ZikirmatikProvider() {
    _yukle();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final aktifJson = prefs.getString(_aktifKey);
      final hazirJson = prefs.getString(_hazirKey);
      if (aktifJson != null) {
        aktifZikirler = (json.decode(aktifJson) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      if (hazirJson != null) {
        hazirZikirler = (json.decode(hazirJson) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      // Bozuk/uyumsuz bir JSON blobu tüm sayfayı çökertmesin; varsayılan
      // zikir listeleriyle devam edilir.
      debugPrint("Zikirmatik verisi okunamadı, varsayılanlara dönülüyor: $e");
    }
    gorunumTuru = prefs.getInt(_gorunumKey) ?? gorunumTuru;
    tesbihRengi = prefs.getInt(_tesbihRengiKey) ?? tesbihRengi;
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> _kaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aktifKey, json.encode(aktifZikirler));
    await prefs.setString(_hazirKey, json.encode(hazirZikirler));
  }

  void setGorunumTuru(int v) {
    gorunumTuru = v;
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_gorunumKey, v));
    notifyListeners();
  }

  void setTesbihRengi(int v) {
    tesbihRengi = v;
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_tesbihRengiKey, v));
    notifyListeners();
  }

  void zikirEkle(Map<String, dynamic> zikir) {
    aktifZikirler.add(zikir);
    _kaydet();
    notifyListeners();
  }

  void zikirGuncelle(Map<String, dynamic> eski, Map<String, dynamic> yeni) {
    final index = aktifZikirler.indexOf(eski);
    if (index == -1) return;
    final eskiSayi = (eski['sayi'] as int?) ?? 0;
    final yeniHedef = (yeni['hedef'] as int?) ?? 99;
    // Hedef, mevcut sayının altına düşürüldüyse ilerlemeyi sıfırla; aksi
    // halde halka %100'ü aşan bir ilerleme gösterir.
    yeni['sayi'] = eskiSayi > yeniHedef ? 0 : eskiSayi;
    yeni['loop'] = eski['loop'] ?? 0;
    aktifZikirler[index] = yeni;
    _kaydet();
    notifyListeners();
  }

  void aktiftenKaldir(Map<String, dynamic> zikir) {
    aktifZikirler.remove(zikir);
    hazirZikirler.add(zikir);
    _kaydet();
    notifyListeners();
  }

  void hazirdanEkle(Map<String, dynamic> zikir) {
    hazirZikirler.remove(zikir);
    aktifZikirler.add(zikir);
    _kaydet();
    notifyListeners();
  }

  void sayaciGuncelle(Map<String, dynamic> zikir, int yeniSayi, {int? loop}) {
    zikir['sayi'] = yeniSayi;
    if (loop != null) zikir['loop'] = loop;
    _kaydet();
    notifyListeners();
  }
}

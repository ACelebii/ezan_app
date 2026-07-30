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
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> _kaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aktifKey, json.encode(aktifZikirler));
    await prefs.setString(_hazirKey, json.encode(hazirZikirler));
  }

  void zikirEkle(Map<String, dynamic> zikir) {
    aktifZikirler.add(zikir);
    _kaydet();
    notifyListeners();
  }

  void zikirGuncelle(Map<String, dynamic> eski, Map<String, dynamic> yeni) {
    final index = aktifZikirler.indexOf(eski);
    if (index == -1) return;
    yeni['sayi'] = eski['sayi'];
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

  void sayaciGuncelle(Map<String, dynamic> zikir, int yeniSayi) {
    zikir['sayi'] = yeniSayi;
    _kaydet();
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'zikir.dart';

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

  static Zikir _varsayilanZikir() => Zikir(
        ad: 'Zikirmatik',
        hedef: 99,
        imame: 33,
        varsayilan: true,
      );

  List<Zikir> aktifZikirler = [_varsayilanZikir()];

  List<Zikir> hazirZikirler = [
    Zikir(
      ad: '100 Sübhânellâhi',
      hedef: 100,
      imame: 100,
      arapca: 'سُبْحَانَ اللّٰهِ وَبِحَمْدِهِ سُبْحَانَ اللّٰهِ الْعَظِيمِ',
      okunusu: 'Sübhânellâhi ve bi hamdihî sübhânellâhil azîm',
      anlami: "Allah'ü Teala'yı tesbih ederim, hamd O'na mahsustur.",
    ),
    Zikir(
      ad: '99 Lâ havle',
      hedef: 99,
      imame: 99,
      arapca: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ الْعَلِيِّ الْعَظِيمِ',
      okunusu: 'Lâ havle ve lâ kuvvete illâ billâhil aliyyil azîm',
      anlami: "Bütün kudret ve kuvvet, Aliyy ve Azîm olan Allah'a aittir.",
    ),
    Zikir(
      ad: 'Salavat',
      hedef: 100,
      imame: 25,
      arapca:
          'اَللّٰهُمَّ صَلِّ عَلٰى سَيِّدِنَا مُحَمَّدٍ وَعَلٰى اٰلِ سَيِّدِنَا مُحَمَّدٍ',
      okunusu:
          'Allahümme Salli Ala Seyyidina Muhammedin ve Ala Ali Seyyidina Muhammed',
      anlami: "Allah'ım, efendimiz Hz. Muhammed'e ve aline salat eyle.",
    ),
  ];

  bool _yuklendi = false;
  bool get yuklendi => _yuklendi;

  ZikirmatikProvider() {
    _yukle();
  }

  /// Bozuk kayıtlar atlanır; hiçbiri okunamazsa [yedek] kalır.
  static List<Zikir>? _oku(String? metin) {
    if (metin == null) return null;
    final liste = json.decode(metin) as List;
    return [
      for (final e in liste)
        if (Zikir.fromJson(e) case final Zikir z) z,
    ];
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final aktif = _oku(prefs.getString(_aktifKey));
      final hazir = _oku(prefs.getString(_hazirKey));
      if (aktif != null) aktifZikirler = aktif;
      if (hazir != null) hazirZikirler = hazir;
    } catch (e) {
      // Bozuk/uyumsuz bir JSON blobu tüm sayfayı çökertmesin; varsayılan
      // zikir listeleriyle devam edilir.
      debugPrint('Zikirmatik verisi okunamadı, varsayılanlara dönülüyor: $e');
    }
    // Varsayılan sayaç her zaman listenin başında olmalı (silinemez).
    if (!aktifZikirler.any((z) => z.varsayilan)) {
      aktifZikirler.insert(0, _varsayilanZikir());
    }
    gorunumTuru = prefs.getInt(_gorunumKey) ?? gorunumTuru;
    tesbihRengi = prefs.getInt(_tesbihRengiKey) ?? tesbihRengi;
    _yuklendi = true;
    notifyListeners();
  }

  Future<void> _kaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _aktifKey, json.encode(aktifZikirler.map((z) => z.toJson()).toList()));
    await prefs.setString(
        _hazirKey, json.encode(hazirZikirler.map((z) => z.toJson()).toList()));
  }

  void setGorunumTuru(int v) {
    gorunumTuru = v;
    SharedPreferences.getInstance().then((p) => p.setInt(_gorunumKey, v));
    notifyListeners();
  }

  void setTesbihRengi(int v) {
    tesbihRengi = v;
    SharedPreferences.getInstance().then((p) => p.setInt(_tesbihRengiKey, v));
    notifyListeners();
  }

  void zikirEkle(Zikir zikir) {
    aktifZikirler.add(zikir);
    _kaydet();
    notifyListeners();
  }

  /// [eski] zikri [yeni] ile değiştirir; sayaç ve tur korunur (hedef sayının
  /// altına düşürüldüyse ilerleme sıfırlanır: halka %100'ü aşmasın).
  void zikirGuncelle(Zikir eski, Zikir yeni) {
    final index = aktifZikirler.indexOf(eski);
    if (index == -1) return;
    yeni.sayi = eski.sayi >= yeni.hedef ? 0 : eski.sayi;
    yeni.tur = eski.tur;
    aktifZikirler[index] = yeni;
    _kaydet();
    notifyListeners();
  }

  void aktiftenKaldir(Zikir zikir) {
    aktifZikirler.remove(zikir);
    hazirZikirler.add(zikir);
    _kaydet();
    notifyListeners();
  }

  void hazirdanEkle(Zikir zikir) {
    hazirZikirler.remove(zikir);
    aktifZikirler.add(zikir);
    _kaydet();
    notifyListeners();
  }

  /// "Hazır" listesindeki, kullanıcının kendi eklediği zikri kalıcı siler.
  /// Uygulamanın hazır zikirleri `id` taşımaz ve silinemez.
  void hazirdanSil(Zikir zikir) {
    if (!zikir.kendiEkledigim) return;
    hazirZikirler.remove(zikir);
    _kaydet();
    notifyListeners();
  }

  void sayaciGuncelle(Zikir zikir, int yeniSayi, {int? tur}) {
    zikir.sayi = yeniSayi;
    if (tur != null) zikir.tur = tur;
    _kaydet();
    notifyListeners();
  }
}

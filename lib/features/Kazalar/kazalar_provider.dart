import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KazalarProvider extends ChangeNotifier {
  Map<String, int> kazaSayilari = {
    "Sabah": 0,
    "Öğle": 0,
    "İkindi": 0,
    "Akşam": 0,
    "Yatsı": 0,
    "Vitr": 0,
    "Oruç": 0,
  };

  Map<String, String> sonKayitTarihleri = {
    "Sabah": "",
    "Öğle": "",
    "İkindi": "",
    "Akşam": "",
    "Yatsı": "",
    "Vitr": "",
    "Oruç": "",
  };

  bool _ikondaGoster = false;
  bool get ikondaGoster => _ikondaGoster;

  // Bazı launcher'lar (ör. Pixel/stock Android) sayısal rozeti hiç
  // desteklemez, yalnızca gerçek bir bildirimden gelen noktayı gösterir.
  // Kullanıcı anahtarı açtığında rozetin neden görünmediğini anlayabilsin
  // diye bu bilgi ayrı tutulur.
  bool _badgeDestekleniyor = true;
  bool get badgeDestekleniyor => _badgeDestekleniyor;

  int get toplamKazaSayisi =>
      kazaSayilari.values.fold(0, (toplam, deger) => toplam + deger);

  KazalarProvider() {
    _verileriYukle();
  }

  // Hafızadan verileri çeker
  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    _ikondaGoster = prefs.getBool('kaza_ikonda_goster') ?? false;

    for (String key in kazaSayilari.keys) {
      kazaSayilari[key] = prefs.getInt('kaza_sayi_$key') ?? 0;
      sonKayitTarihleri[key] = prefs.getString('kaza_tarih_$key') ?? "";
    }
    notifyListeners();
    _ikonRozetiniGuncelle();
  }

  // Uygulama ikonundaki rozeti günceller. Platform veya launcher desteklemiyorsa
  // (ör. Windows/Linux masaüstü, test ortamı, rozeti desteklemeyen bir launcher)
  // MethodChannel çağrısı sessizce başarısız olabilir; bu beklenen bir durumdur.
  Future<void> _ikonRozetiniGuncelle() async {
    try {
      _badgeDestekleniyor = await AppBadgePlus.isSupported();
      await AppBadgePlus.updateBadge(_ikondaGoster ? toplamKazaSayisi : 0);
    } catch (_) {
    } finally {
      notifyListeners();
    }
  }

  // Sadece değişen vakti hafızaya kaydeder
  Future<void> _veriyiKaydet(String vakit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kaza_sayi_$vakit', kazaSayilari[vakit]!);
    await prefs.setString('kaza_tarih_$vakit', sonKayitTarihleri[vakit]!);
  }

  // Ayarı hafızaya kaydeder
  Future<void> ikonGosteriminiDegistir(bool deger) async {
    _ikondaGoster = deger;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('kaza_ikonda_goster', _ikondaGoster);
    notifyListeners();
    _ikonRozetiniGuncelle();
  }

  String _simdikiZamaniGetir() {
    final now = DateTime.now();
    const aylar = [
      "",
      "Oca",
      "Şub",
      "Mar",
      "Nis",
      "May",
      "Haz",
      "Tem",
      "Ağu",
      "Eyl",
      "Eki",
      "Kas",
      "Ara"
    ];
    return "${now.day.toString().padLeft(2, '0')} ${aylar[now.month]} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}*";
  }

  void artir(String vakit) {
    kazaSayilari[vakit] = (kazaSayilari[vakit] ?? 0) + 1;
    sonKayitTarihleri[vakit] = _simdikiZamaniGetir();
    _veriyiKaydet(vakit);
    notifyListeners();
    _ikonRozetiniGuncelle();
  }

  void azalt(String vakit) {
    if ((kazaSayilari[vakit] ?? 0) > 0) {
      kazaSayilari[vakit] = (kazaSayilari[vakit] ?? 0) - 1;
      sonKayitTarihleri[vakit] = _simdikiZamaniGetir();
      _veriyiKaydet(vakit);
      notifyListeners();
      _ikonRozetiniGuncelle();
    }
  }

  void topluDegerGir(String vakit, int yeniDeger) {
    if (yeniDeger >= 0) {
      kazaSayilari[vakit] = yeniDeger;
      sonKayitTarihleri[vakit] = _simdikiZamaniGetir();
      _veriyiKaydet(vakit);
      notifyListeners();
      _ikonRozetiniGuncelle();
    }
  }
}

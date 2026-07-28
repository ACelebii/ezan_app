import 'package:flutter/material.dart';

class AjandaProvider extends ChangeNotifier {
  DateTime _seciliTarih = DateTime.now();
  bool _izinVerildiMi = false;

  DateTime get seciliTarih => _seciliTarih;
  bool get izinVerildiMi => _izinVerildiMi;

  void izinDurumunuGuncelle(bool durum) {
    _izinVerildiMi = durum;
    notifyListeners();
  }

  void sonrakiGun() {
    _seciliTarih = _seciliTarih.add(const Duration(days: 1));
    notifyListeners();
  }

  void oncekiGun() {
    _seciliTarih = _seciliTarih.subtract(const Duration(days: 1));
    notifyListeners();
  }

  void buguneDon() {
    _seciliTarih = DateTime.now();
    notifyListeners();
  }

  bool get isBugun {
    final now = DateTime.now();
    return _seciliTarih.year == now.year &&
        _seciliTarih.month == now.month &&
        _seciliTarih.day == now.day;
  }
}

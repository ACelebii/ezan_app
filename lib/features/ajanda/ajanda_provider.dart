import 'package:flutter/material.dart';

class AjandaProvider extends ChangeNotifier {
  DateTime _seciliTarih = DateTime.now();

  DateTime get seciliTarih => _seciliTarih;

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

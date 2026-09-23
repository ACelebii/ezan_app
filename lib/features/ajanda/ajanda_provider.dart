import 'package:flutter/material.dart';

class AjandaProvider extends ChangeNotifier {
  /// Seçili şehrin takvimine göre bugün (`DateTime.utc(y, a, g)`); sayfa
  /// [bugunuAyarla] ile bildirir. Telefonun saat dilimi farklıysa telefonun
  /// tarihi şehrin tarihinden bir gün geri/ileri olabilir.
  DateTime _bugun = _telefonBugunu();
  DateTime _seciliTarih = _telefonBugunu();
  bool _gunSecildi = false;

  static DateTime _telefonBugunu() {
    final simdi = DateTime.now();
    return DateTime.utc(simdi.year, simdi.month, simdi.day);
  }

  DateTime get seciliTarih => _seciliTarih;

  /// Şehrin bugününü bildirir. Kullanıcı henüz başka bir güne geçmediyse
  /// seçili gün de buna çekilir. Bilerek `notifyListeners` çağırmaz: sayfa bunu
  /// `didChangeDependencies` içinde çağırır ve kendi güncellemesini yapar.
  void bugunuAyarla(DateTime bugun) {
    _bugun = bugun;
    if (!_gunSecildi) _seciliTarih = bugun;
  }

  void sonrakiGun() {
    _gunSecildi = true;
    _seciliTarih = _seciliTarih.add(const Duration(days: 1));
    notifyListeners();
  }

  void oncekiGun() {
    _gunSecildi = true;
    _seciliTarih = _seciliTarih.subtract(const Duration(days: 1));
    notifyListeners();
  }

  void buguneDon() {
    _gunSecildi = false;
    _seciliTarih = _bugun;
    notifyListeners();
  }

  bool get isBugun => _seciliTarih == _bugun;
}

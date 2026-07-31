import 'package:flutter/material.dart';
import '../data/dini_gunler_repository.dart';
import '../dini_gunler_model.dart';
import '../../../locator.dart';

class DiniGunlerProvider extends ChangeNotifier {
  final DiniGunlerRepository _repository = getIt<DiniGunlerRepository>();
  List<DiniGunlerModel> _allData = [];
  int _seciliYil = DateTime.now().year;
  bool _isLoading = true;
  String? errorMessage;

  /// Yalnızca gerçekten veri bulunan yılları listeler; aksi halde yıl
  /// seçiciden veri olmayan bir yıl seçilince boş ekran çıkardı.
  List<int> get yillar => _allData.map((e) => e.yil).toSet().toList()..sort();

  DiniGunlerProvider() {
    _loadData();
  }

  int get seciliYil => _seciliYil;
  bool get isLoading => _isLoading;

  Future<void> _loadData() async {
    try {
      _allData = await _repository.getDiniGunler();
      errorMessage = null;
    } catch (e) {
      errorMessage = "Dini günler yüklenemedi: $e";
    }
    // Bugünün yılına ait veri yoksa (ör. veri seti henüz güncellenmediyse),
    // boş bir ekranda kalmak yerine verisi olan en yakın/son yıla düş.
    final mevcutYillar = yillar;
    if (mevcutYillar.isNotEmpty && !mevcutYillar.contains(_seciliYil)) {
      _seciliYil = mevcutYillar.last;
    }
    _isLoading = false;
    notifyListeners();
  }

  void setYil(int yil) {
    _seciliYil = yil;
    notifyListeners();
  }

  List<DiniGunlerModel> get yillikVeri =>
      _allData.where((e) => e.yil == _seciliYil).toList();

  Map<String, List<DiniGunlerModel>> get gruplanmisVeri {
    Map<String, List<DiniGunlerModel>> gruplanmis = {};
    for (var item in yillikVeri) {
      gruplanmis.putIfAbsent(item.ay, () => []).add(item);
    }
    return gruplanmis;
  }
}

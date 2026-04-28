import 'package:flutter/material.dart';
import '../data/dini_gunler_repository.dart';

class DiniGunlerProvider extends ChangeNotifier {
  final DiniGunlerRepository _repository = DiniGunlerRepository();
  List<Map<String, dynamic>> _allData = [];
  int _seciliYil = 2026;
  bool _isLoading = true;

  final List<int> yillar = [2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027];

  DiniGunlerProvider() {
    _loadData();
  }

  int get seciliYil => _seciliYil;
  bool get isLoading => _isLoading;

  Future<void> _loadData() async {
    _allData = await _repository.getDiniGunler();
    _isLoading = false;
    notifyListeners();
  }

  void setYil(int yil) {
    _seciliYil = yil;
    notifyListeners();
  }

  List<Map<String, dynamic>> get yillikVeri =>
      _allData.where((e) => e['yil'] == _seciliYil).toList();

  Map<String, List<Map<String, dynamic>>> get gruplanmisVeri {
    Map<String, List<Map<String, dynamic>>> gruplanmis = {};
    for (var item in yillikVeri) {
      gruplanmis.putIfAbsent(item['ay'], () => []).add(item);
    }
    return gruplanmis;
  }
}

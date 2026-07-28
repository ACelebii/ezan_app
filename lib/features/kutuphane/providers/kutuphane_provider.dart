import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../data/kutuphane_repository.dart';
import '../kutuphane_model.dart';

class KutuphaneProvider extends ChangeNotifier {
  final KutuphaneRepository _repository = GetIt.instance<KutuphaneRepository>();

  List<LibraryNode> _items = [];
  bool _isLoading = true;

  List<LibraryNode> get items => _items;
  bool get isLoading => _isLoading;

  KutuphaneProvider() {
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      _items = await _repository.getAnaKategoriler();
    } catch (e) {
      debugPrint("Kütüphane Veritabanı Yükleme Hatası: $e");
    }
    _isLoading = false;
    notifyListeners();
  }
}

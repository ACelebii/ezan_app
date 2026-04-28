import 'package:flutter/material.dart';
import '../data/kutuphane_repository.dart';
import '../kutuphane_model.dart';

class KutuphaneProvider extends ChangeNotifier {
  final KutuphaneRepository _repository = KutuphaneRepository();
  List<LibraryNode> _items = [];
  bool _isLoading = true;

  List<LibraryNode> get items => _items;
  bool get isLoading => _isLoading;

  KutuphaneProvider() {
    _loadItems();
  }

  Future<void> _loadItems() async {
    _items = await _repository.getLibraryItems();
    _isLoading = false;
    notifyListeners();
  }
}

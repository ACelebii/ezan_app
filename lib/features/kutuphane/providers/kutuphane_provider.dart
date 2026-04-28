import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../data/kutuphane_repository.dart';
import '../kutuphane_model.dart';
import '../../../locator.dart';

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
    final result = await _repository.getLibraryItems();
    if (result.isSuccess) {
      _items = result.data!;
    } else {
      // Hata yönetimi (loglama veya snackbar gösterimi)
      debugPrint("Hata: ${result.errorMessage}");
    }
    _isLoading = false;
    notifyListeners();
  }
}

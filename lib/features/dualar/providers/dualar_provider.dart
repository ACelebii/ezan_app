import 'package:flutter/material.dart';
import '../data/dualar_repository.dart';
import '../dualar_model.dart';
import '../../../locator.dart';

class DualarProvider extends ChangeNotifier {
  final DualarRepository _repository = locator<DualarRepository>();

  List<DuaCategory> categories = [];
  bool isLoading = true;
  String? errorMessage;

  DualarProvider() {
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repository.getDualar();

    if (result.isSuccess && result.data != null) {
      categories = result.data!;
    } else {
      errorMessage = result.errorMessage;
    }

    isLoading = false;
    notifyListeners();
  }
}

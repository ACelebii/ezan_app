import 'package:flutter/material.dart';
import '../kuran_download_service.dart';

class KuranProvider extends ChangeNotifier {
  int _currentPage = 435; // Başlangıç sayfası
  final int _totalPages = 604;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  void setPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  int getCuz(int sayfa) {
    if (sayfa <= 0) return 1;
    if (sayfa > 604) return 30;
    return ((sayfa - 1) ~/ 20) + 1;
  }

  Future<void> downloadPage(int page) async {
    await KuranDownloadService.downloadPage(
        page, "https://example.com/page_$page.png");
    notifyListeners();
  }
}

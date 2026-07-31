import 'package:flutter/material.dart';

enum SyncState { idle, syncing, success, error }

class SyncNotifier extends ChangeNotifier {
  SyncState _state = SyncState.idle;
  String? _errorMessage;

  // setSuccess()'ün 2 saniyelik gecikmeli "idle"a dönüş zamanlayıcısı,
  // bu süre içinde yeni bir senkron başlarsa/hata olursa devre dışı
  // bırakılmalı; aksi halde daha yeni bir durumun üzerine yazabilir.
  int _resetToken = 0;

  SyncState get state => _state;
  String? get errorMessage => _errorMessage;

  void setSyncing() {
    _resetToken++;
    _state = SyncState.syncing;
    notifyListeners();
  }

  void setSuccess() {
    final token = ++_resetToken;
    _state = SyncState.success;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      if (_resetToken != token) return;
      _state = SyncState.idle;
      notifyListeners();
    });
  }

  void setError(String message) {
    _resetToken++;
    _state = SyncState.error;
    _errorMessage = message;
    notifyListeners();
  }
}

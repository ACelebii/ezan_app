import 'package:flutter/material.dart';

enum SyncState { idle, syncing, success, error }

class SyncNotifier extends ChangeNotifier {
  SyncState _state = SyncState.idle;
  String? _errorMessage;

  SyncState get state => _state;
  String? get errorMessage => _errorMessage;

  void setSyncing() {
    _state = SyncState.syncing;
    notifyListeners();
  }

  void setSuccess() {
    _state = SyncState.success;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      _state = SyncState.idle;
      notifyListeners();
    });
  }

  void setError(String message) {
    _state = SyncState.error;
    _errorMessage = message;
    notifyListeners();
  }
}

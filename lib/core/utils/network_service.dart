import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    final connected = !results.contains(ConnectivityResult.none);
    debugPrint("NetworkStatus: Connected = $connected, Results = $results");
    return connected;
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      final connected = !results.contains(ConnectivityResult.none);
      debugPrint(
          "NetworkStatusChanged: Connected = $connected, Results = $results");
      return connected;
    });
  }
}

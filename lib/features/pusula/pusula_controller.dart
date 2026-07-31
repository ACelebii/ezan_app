import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class PusulaController extends ChangeNotifier {
  double _cumulativeHeading = 0;
  double _lastRawHeading = 0;
  double? _qiblaAngle;
  bool _isLoaded = false;
  Position? _currentPosition;
  String? _errorMessage;
  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _compassTimeoutTimer;

  double get cumulativeHeading => _cumulativeHeading;
  double? get qiblaAngle => _qiblaAngle;
  bool get isLoaded => _isLoaded;
  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;

  /// Pusulanın gerçekten kullanılabilir olması için hem cihazın yönü hem
  /// de gerçek kıble açısı hazır olmalı; aksi halde arayüz kıbleyi Kuzey'e
  /// sabitlenmiş gibi (yanlış) göstermiş olur.
  bool get isReady => _isLoaded && _qiblaAngle != null && _errorMessage == null;

  PusulaController() {
    _startCompass();
    _updateLocationAndQibla();
  }

  void _startCompass() {
    final events = FlutterCompass.events;
    if (events == null) {
      _errorMessage = "Cihazınızda pusula sensörü bulunamadı.";
      notifyListeners();
      return;
    }
    _compassSubscription = events.listen((event) {
      if (event.heading != null) {
        _compassTimeoutTimer?.cancel();
        double currentRaw = event.heading!;
        double diff = currentRaw - _lastRawHeading;
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;
        _cumulativeHeading += diff;
        _lastRawHeading = currentRaw;
        _isLoaded = true;
        notifyListeners();
      }
    });
    _compassTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!_isLoaded) {
        _errorMessage = "Pusula sensöründen veri alınamadı.";
        notifyListeners();
      }
    });
  }

  Future<void> _updateLocationAndQibla() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = "Konum servisleri kapalı.";
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = "Konum izni reddedildi.";
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = "Konum izni kalıcı olarak reddedildi.";
        notifyListeners();
        return;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          );
        } catch (e) {
          debugPrint("Konum hatası: $e");
        }
      }

      if (pos != null) {
        _currentPosition = pos;
        _qiblaAngle = _calculateTrueBearing(pos.latitude, pos.longitude);
        notifyListeners();
      } else {
        _errorMessage = "Konum alınamadı. Lütfen tekrar deneyin.";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Konum hatası: $e");
      _errorMessage = "Konum alınamadı. Lütfen tekrar deneyin.";
      notifyListeners();
    }
  }

  double _calculateTrueBearing(double lat, double lon) {
    const double mLat = 21.4225;
    const double mLon = 39.8262;
    double phi1 = lat * (math.pi / 180.0);
    double phi2 = mLat * (math.pi / 180.0);
    double lam1 = lon * (math.pi / 180.0);
    double lam2 = mLon * (math.pi / 180.0);
    double y = math.sin(lam2 - lam1) * math.cos(phi2);
    double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(lam2 - lam1);
    return (math.atan2(y, x) * 180.0 / math.pi + 360) % 360;
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _compassTimeoutTimer?.cancel();
    super.dispose();
  }
}

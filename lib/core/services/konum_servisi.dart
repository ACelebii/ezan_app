// Cihazın konumunu alır: servis açık mı, izin var mı, izin iste, konumu oku.
//
// Camiler, Pusula ve "Konumumu kullan" aynı adımları ayrı ayrı yazıyordu; tek
// yerde toplandı. Sorunlar [KonumHatasi] olarak, nedeniyle birlikte fırlatılır.

import 'package:geolocator/geolocator.dart';

enum KonumSorunu {
  servisKapali,
  izinReddedildi,
  izinKaliciReddedildi,
  alinamadi
}

class KonumHatasi implements Exception {
  const KonumHatasi(this.sorun);

  final KonumSorunu sorun;

  /// Kullanıcıya gösterilecek kısa metin.
  String get mesaj => switch (sorun) {
        KonumSorunu.servisKapali => 'Konum servisleri kapalı.',
        KonumSorunu.izinReddedildi => 'Konum izni reddedildi.',
        KonumSorunu.izinKaliciReddedildi =>
          'Konum izni kalıcı olarak reddedildi.',
        KonumSorunu.alinamadi => 'Konum alınamadı.',
      };

  @override
  String toString() => 'KonumHatasi: ${sorun.name}';
}

class KonumServisi {
  /// [geolocator] testte sahte platform vermek içindir.
  KonumServisi({GeolocatorPlatform? geolocator})
      : _g = geolocator ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _g;

  /// Konumu döndürür. [sonBilineniTercihEt] true ise önce işletim sisteminin
  /// bildiği son konuma bakar (hızlıdır), yoksa yeni konum ister. Sorunda
  /// [KonumHatasi] fırlatır.
  Future<Position> konumAl({
    bool sonBilineniTercihEt = false,
    LocationSettings? ayar,
  }) async {
    if (!await _g.isLocationServiceEnabled()) {
      throw const KonumHatasi(KonumSorunu.servisKapali);
    }

    var izin = await _g.checkPermission();
    if (izin == LocationPermission.denied) {
      izin = await _g.requestPermission();
    }
    switch (izin) {
      case LocationPermission.denied:
        throw const KonumHatasi(KonumSorunu.izinReddedildi);
      case LocationPermission.deniedForever:
        throw const KonumHatasi(KonumSorunu.izinKaliciReddedildi);
      case LocationPermission.unableToDetermine:
        throw const KonumHatasi(KonumSorunu.alinamadi);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
    }

    try {
      if (sonBilineniTercihEt) {
        final son = await _g.getLastKnownPosition();
        if (son != null) return son;
      }
      return await _g.getCurrentPosition(locationSettings: ayar);
    } catch (_) {
      // Zaman aşımı, sağlayıcı hatası...
      throw const KonumHatasi(KonumSorunu.alinamadi);
    }
  }

  /// Uygulamanın sistem ayarları sayfası (kalıcı reddedilen izin için).
  Future<bool> ayarlariAc() => _g.openAppSettings();
}

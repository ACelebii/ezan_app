import 'dart:async';

import 'package:ezan_vakti_uygulamasi/core/services/konum_servisi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

Position _konum(double enlem, double boylam) => Position(
      latitude: enlem,
      longitude: boylam,
      timestamp: DateTime.utc(2026, 9, 21),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

class _SahteGeo extends Fake implements GeolocatorPlatform {
  bool servisAcik = true;
  LocationPermission izin = LocationPermission.whileInUse;

  /// requestPermission çağrılınca verilecek izin.
  LocationPermission istenenIzin = LocationPermission.whileInUse;
  Position? sonBilinen;
  Object? konumHatasi;
  int izinIstegi = 0;
  int yeniKonumIstegi = 0;
  bool ayarlarAcildi = false;

  @override
  Future<bool> isLocationServiceEnabled() async => servisAcik;

  @override
  Future<LocationPermission> checkPermission() async => izin;

  @override
  Future<LocationPermission> requestPermission() async {
    izinIstegi++;
    return izin = istenenIzin;
  }

  @override
  Future<Position?> getLastKnownPosition(
          {bool forceLocationManager = false}) async =>
      sonBilinen;

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    yeniKonumIstegi++;
    if (konumHatasi != null) throw konumHatasi!;
    return _konum(41.0, 29.0);
  }

  @override
  Future<bool> openAppSettings() async => ayarlarAcildi = true;
}

Future<KonumSorunu?> _sorun(Future<Position> f) async {
  try {
    await f;
    return null;
  } on KonumHatasi catch (h) {
    return h.sorun;
  }
}

void main() {
  late _SahteGeo geo;
  late KonumServisi servis;

  setUp(() {
    geo = _SahteGeo();
    servis = KonumServisi(geolocator: geo);
  });

  test('izin ve servis tamamsa konum döner, izin istenmez', () async {
    final p = await servis.konumAl();

    expect((p.latitude, p.longitude), (41.0, 29.0));
    expect(geo.izinIstegi, 0);
  });

  test('konum servisleri kapalıysa servisKapali', () async {
    geo.servisAcik = false;

    expect(await _sorun(servis.konumAl()), KonumSorunu.servisKapali);
    expect(geo.izinIstegi, 0, reason: 'servis kapalıyken izin sorulmaz');
  });

  test('izin yoksa istenir; verilirse konum alınır', () async {
    geo.izin = LocationPermission.denied;
    geo.istenenIzin = LocationPermission.whileInUse;

    final p = await servis.konumAl();

    expect(geo.izinIstegi, 1);
    expect(p.latitude, 41.0);
  });

  test('izin istenip reddedilirse izinReddedildi (konum istenmez)', () async {
    geo.izin = LocationPermission.denied;
    geo.istenenIzin = LocationPermission.denied;

    expect(await _sorun(servis.konumAl()), KonumSorunu.izinReddedildi);
    expect(geo.yeniKonumIstegi, 0);
  });

  test('daha önce kalıcı reddedilmişse izin sorulmadan izinKaliciReddedildi',
      () async {
    geo.izin = LocationPermission.deniedForever;

    expect(await _sorun(servis.konumAl()), KonumSorunu.izinKaliciReddedildi);
    expect(geo.izinIstegi, 0);
  });

  test('izin istenince "bir daha sorma" seçilirse izinKaliciReddedildi',
      () async {
    geo.izin = LocationPermission.denied;
    geo.istenenIzin = LocationPermission.deniedForever;

    expect(await _sorun(servis.konumAl()), KonumSorunu.izinKaliciReddedildi);
  });

  test('izin belirlenemezse alinamadi', () async {
    geo.izin = LocationPermission.unableToDetermine;

    expect(await _sorun(servis.konumAl()), KonumSorunu.alinamadi);
  });

  test(
      'sonBilineniTercihEt: son konum varsa yeni konum istenmez, yoksa istenir',
      () async {
    geo.sonBilinen = _konum(10, 20);
    final hizli = await servis.konumAl(sonBilineniTercihEt: true);
    expect((hizli.latitude, hizli.longitude), (10, 20));
    expect(geo.yeniKonumIstegi, 0);

    geo.sonBilinen = null;
    final yeni = await servis.konumAl(sonBilineniTercihEt: true);
    expect(yeni.latitude, 41.0);
    expect(geo.yeniKonumIstegi, 1);
  });

  test('sonBilineniTercihEt kapalıyken son konum kullanılmaz', () async {
    geo.sonBilinen = _konum(10, 20);

    final p = await servis.konumAl();

    expect(p.latitude, 41.0);
  });

  test('zaman aşımı ve sağlayıcı hataları alinamadi olur', () async {
    geo.konumHatasi = TimeoutException('süre doldu');
    expect(await _sorun(servis.konumAl()), KonumSorunu.alinamadi);

    geo.konumHatasi = StateError('sağlayıcı yok');
    expect(await _sorun(servis.konumAl()), KonumSorunu.alinamadi);
  });

  test('mesajlar (Camiler ve Pusula ekranlarındaki eski metinlerle aynı)', () {
    expect(const KonumHatasi(KonumSorunu.servisKapali).mesaj,
        'Konum servisleri kapalı.');
    expect(const KonumHatasi(KonumSorunu.izinReddedildi).mesaj,
        'Konum izni reddedildi.');
    expect(const KonumHatasi(KonumSorunu.izinKaliciReddedildi).mesaj,
        'Konum izni kalıcı olarak reddedildi.');
  });

  test('ayarlariAc, sistem ayarlarını açar', () async {
    await servis.ayarlariAc();

    expect(geo.ayarlarAcildi, isTrue);
  });
}

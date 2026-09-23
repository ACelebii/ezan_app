import '../../core/i18n/cevir.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class QiblaMapPage extends StatefulWidget {
  const QiblaMapPage({super.key});

  @override
  State<QiblaMapPage> createState() => _QiblaMapPageState();
}

class _QiblaMapPageState extends State<QiblaMapPage> {
  final Completer<GoogleMapController> _controller = Completer();

  // İlk açılışta Uydu görünümü seçili gelsin (Talebin üzerine)
  MapType _currentMapType = MapType.satellite;

  // Mekke / Kâbe Koordinatları
  final LatLng _kaabaPosition = const LatLng(21.422487, 39.826206);
  LatLng? _userPosition;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Standart görünüm için fotoğraftaki gibi gece/karanlık mod harita stili
  final String _darkMapStyle = '''
  [
    {"elementType": "geometry","stylers": [{"color": "#242f3e"}]},
    {"elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},
    {"elementType": "labels.text.stroke","stylers": [{"color": "#242f3e"}]},
    {"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
    {"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
    {"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},
    {"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},
    {"featureType": "road","elementType": "geometry","stylers": [{"color": "#38414e"}]},
    {"featureType": "road","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},
    {"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},
    {"featureType": "road.highway","elementType": "geometry","stylers": [{"color": "#746855"}]},
    {"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},
    {"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},
    {"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},
    {"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},
    {"featureType": "water","elementType": "labels.text.stroke","stylers": [{"color": "#17263c"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
        _setMapData();
      });
      _goToUserLocation();
    } catch (e) {
      debugPrint("Konum alınamadı: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context
                .t('Konumunuz alınamadı, harita Kâbe merkezli gösteriliyor.')),
            backgroundColor: Colors.orange));
      }
    }
  }

  void _setMapData() {
    if (_userPosition == null) return;

    _markers = {
      Marker(
        markerId: const MarkerId('user'),
        position: _userPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: context.t('Konumunuz')),
      ),
      Marker(
        markerId: const MarkerId('kaaba'),
        position: _kaabaPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: context.t('Kâbe')),
      ),
    };

    _polylines = {
      Polyline(
        polylineId: const PolylineId('qibla_line'),
        points: [_userPosition!, _kaabaPosition],
        color: Colors.tealAccent, // Senin tasarım diline uygun çizgi rengi
        width: 3,
        patterns: [
          PatternItem.dash(20),
          PatternItem.gap(10)
        ], // Kesik Kesik Çizgi
      )
    };
  }

  Future<void> _goToUserLocation() async {
    if (_userPosition == null) return;
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _userPosition!, zoom: 16.5, tilt: 45),
    ));
  }

  void _onMenuSelection(String value) {
    setState(() {
      if (value == 'uydu') {
        _currentMapType = MapType.satellite;
      } else if (value == 'standart') {
        _currentMapType = MapType.normal;
      } else if (value == 'konumum') {
        _goToUserLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // HARİTA KATMANI
          GoogleMap(
            mapType: _currentMapType,
            initialCameraPosition: CameraPosition(
                target: _userPosition ?? _kaabaPosition, zoom: 4),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Kendi menümüzden yöneteceğiz
            compassEnabled: true,
            style: _currentMapType == MapType.normal ? _darkMapStyle : null,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // ÜST ARAYÜZ (Geri Butonu ve Menü)
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // SOL: GERİ BUTONU (Fotoğraf 1'deki gibi yuvarlak)
                  InkWell(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                          color: Color(0xFF1C1C1E), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),

                  // SAĞ: AÇILIR MENÜ (Fotoğraf 2 ve 3'teki Yapı)
                  Theme(
                    data: Theme.of(context).copyWith(
                      popupMenuTheme: PopupMenuThemeData(
                        color: const Color(0xFF2C2C2E), // Koyu menü arkaplanı
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      onSelected: _onMenuSelection,
                      offset: const Offset(0, 50),
                      icon: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                            color: Color(0xFF1C1C1E), shape: BoxShape.circle),
                        child:
                            const Icon(Icons.menu_rounded, color: Colors.white),
                      ),
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'uydu',
                          child: Row(
                            children: [
                              Icon(Icons.satellite_alt_rounded,
                                  color: _currentMapType == MapType.satellite
                                      ? Colors.white
                                      : Colors.white54,
                                  size: 20),
                              const SizedBox(width: 12),
                              Text(context.t('Uydu'),
                                  style: TextStyle(
                                      color:
                                          _currentMapType == MapType.satellite
                                              ? Colors.white
                                              : Colors.white54,
                                      fontWeight:
                                          _currentMapType == MapType.satellite
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                              const Spacer(),
                              if (_currentMapType == MapType.satellite)
                                const Icon(Icons.check,
                                    color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'standart',
                          child: Row(
                            children: [
                              Icon(Icons.map_outlined,
                                  color: _currentMapType == MapType.normal
                                      ? Colors.white
                                      : Colors.white54,
                                  size: 20),
                              const SizedBox(width: 12),
                              Text(context.t('Standart'),
                                  style: TextStyle(
                                      color: _currentMapType == MapType.normal
                                          ? Colors.white
                                          : Colors.white54,
                                      fontWeight:
                                          _currentMapType == MapType.normal
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                              const Spacer(),
                              if (_currentMapType == MapType.normal)
                                const Icon(Icons.check,
                                    color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem<String>(
                          value: 'konumum',
                          child: Row(
                            children: [
                              const Icon(Icons.near_me,
                                  color: Colors.white54, size: 20),
                              const SizedBox(width: 12),
                              Text(context.t('Konumum'),
                                  style:
                                      const TextStyle(color: Colors.white54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

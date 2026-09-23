import '../../core/i18n/cevir.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/konum_servisi.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cami_service.dart';
import 'cami_model.dart';

class CamiPage extends StatefulWidget {
  const CamiPage({super.key});

  @override
  State<CamiPage> createState() => _CamiPageState();
}

class _CamiPageState extends State<CamiPage> {
  final CamiService _camiService = CamiService();
  Set<Marker> _markers = {};
  List<Cami> _mosques = [];
  Cami? _selectedCami;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _fetchError = false;
  MapType _currentMapType = MapType.satellite;
  GoogleMapController? _mapController;

  String? _locationError;
  bool _locationPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  final _konumServisi = KonumServisi();

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
      _locationPermanentlyDenied = false;
    });
    try {
      final position = await _konumServisi.konumAl(
        ayar: const LocationSettings(timeLimit: Duration(seconds: 15)),
      );
      if (!mounted) return;
      setState(() => _currentPosition = position);
      _fetchMosques();
    } on KonumHatasi catch (h) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _locationError = h.sorun == KonumSorunu.alinamadi
            ? 'Konum bilgisi alınamadı.'
            : h.mesaj;
        _locationPermanentlyDenied =
            h.sorun == KonumSorunu.izinKaliciReddedildi;
      });
    }
  }

  Future<void> _fetchMosques() async {
    if (_currentPosition == null) return;
    if (!mounted) return;
    setState(() {
      _fetchError = false;
      _selectedCami = null;
    });
    try {
      final mosques = await _camiService.getNearbyMosques(
          _currentPosition!.latitude, _currentPosition!.longitude);
      if (!mounted) return;
      setState(() {
        _mosques = mosques;
        _markers = mosques
            .map((c) => Marker(
                  markerId: MarkerId(c.id),
                  position: LatLng(c.lat, c.lon),
                  infoWindow: InfoWindow(title: c.name),
                  onTap: () => setState(() => _selectedCami = c),
                ))
            .toSet();
        _isLoading = false;
      });
      _fitCameraToMarkers();
    } catch (e) {
      debugPrint("Cami getirme hatası: $e");
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _fetchError = true;
      });
    }
  }

  Future<void> _fitCameraToMarkers() async {
    if (_mapController == null ||
        _mosques.isEmpty ||
        _currentPosition == null) {
      return;
    }
    double minLat = _currentPosition!.latitude;
    double maxLat = _currentPosition!.latitude;
    double minLon = _currentPosition!.longitude;
    double maxLon = _currentPosition!.longitude;
    for (final m in _mosques) {
      if (m.lat < minLat) minLat = m.lat;
      if (m.lat > maxLat) maxLat = m.lat;
      if (m.lon < minLon) minLon = m.lon;
      if (m.lon > maxLon) maxLon = m.lon;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
    try {
      await _mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } catch (e) {
      debugPrint("Kamera odaklama hatası: $e");
    }
  }

  Future<void> _launchNavigation(Cami cami, String mode) async {
    final travelMode = mode == 'Otomobil' ? 'driving' : 'walking';
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${cami.lat},${cami.lon}&travelmode=$travelMode');
    bool launched = false;
    if (await canLaunchUrl(url)) {
      launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('Harita uygulaması açılamadı.'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              const Center(child: CircularProgressIndicator()),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildGlassButton(
                    Icons.arrow_back_ios_new_rounded, () => context.pop()),
              ),
            ],
          ),
        ),
      );
    }
    if (_currentPosition == null) {
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.t(_locationError ?? 'Konum bilgisi alınamadı'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _locationPermanentlyDenied
                            ? _konumServisi.ayarlariAc
                            : _determinePosition,
                        child: Text(_locationPermanentlyDenied
                            ? context.t('Ayarları Aç')
                            : context.t('Tekrar Dene')),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildGlassButton(
                    Icons.arrow_back_ios_new_rounded, () => context.pop()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _fitCameraToMarkers();
            },
            onTap: (_) => setState(() => _selectedCami = null),
            markers: _markers,
            myLocationEnabled: true,
            mapType: _currentMapType,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGlassButton(Icons.arrow_back_ios_new_rounded,
                          () => context.pop()),
                      _buildMapMenu(),
                    ],
                  ),
                  if (_fetchError) ...[
                    const SizedBox(height: 12),
                    _buildErrorBanner(),
                  ] else if (!_isLoading && _mosques.isEmpty) ...[
                    const SizedBox(height: 12),
                    _buildEmptyBanner(),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedCami != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: _buildSelectedCamiCard(_selectedCami!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(context.t('Cami listesi yüklenemedi.'),
                style: const TextStyle(color: Colors.black87, fontSize: 13)),
          ),
          TextButton(
            onPressed: _fetchMosques,
            child: Text(context.t('Tekrar Dene')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8)
        ],
      ),
      child: Text(context.t('Yakınında cami bulunamadı.'),
          style: const TextStyle(color: Colors.black87, fontSize: 13)),
    );
  }

  Widget _buildSelectedCamiCard(Cami cami) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cami.name,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    if (cami.address != null && cami.address!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(cami.address!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedCami = null),
                child: const Icon(Icons.close_rounded, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchNavigation(cami, 'Otomobil'),
                  icon: const Icon(Icons.directions_car_rounded, size: 18),
                  label: Text(context.t('Araçla')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchNavigation(cami, 'Yürüme'),
                  icon: const Icon(Icons.directions_walk_rounded, size: 18),
                  label: Text(context.t('Yürüyerek')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _buildMapMenu() {
    return Container(
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.menu_rounded, color: Colors.black),
        onSelected: (value) {
          setState(() {
            if (value == 'Uydu') _currentMapType = MapType.satellite;
            if (value == 'Standart') _currentMapType = MapType.normal;
          });
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'Uydu', child: Text(context.t('Uydu'))),
          PopupMenuItem(value: 'Standart', child: Text(context.t('Standart'))),
        ],
      ),
    );
  }
}

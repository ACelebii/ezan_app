import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(timeLimit: Duration(seconds: 15)),
      );
      setState(() {
        _currentPosition = position;
      });
      _fetchMosques();
    } catch (e) {
      debugPrint("Konum hatası: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMosques() async {
    if (_currentPosition == null) return;
    setState(() => _fetchError = false);
    try {
      final mosques = await _camiService.getNearbyMosques(
          _currentPosition!.latitude, _currentPosition!.longitude);
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
    } catch (e) {
      debugPrint("Cami getirme hatası: $e");
      setState(() {
        _isLoading = false;
        _fetchError = true;
      });
    }
  }

  Future<void> _launchNavigation(Cami cami, String mode) async {
    final travelMode = mode == 'Otomobil' ? 'driving' : 'walking';
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${cami.lat},${cami.lon}&travelmode=$travelMode');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
                child: _buildGlassButton(Icons.arrow_back_ios_new_rounded,
                    () => context.pop()),
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
              const Center(child: Text('Konum bilgisi alınamadı')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildGlassButton(Icons.arrow_back_ios_new_rounded,
                    () => context.pop()),
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
            onMapCreated: (controller) {},
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
          const Expanded(
            child: Text('Cami listesi yüklenemedi.',
                style: TextStyle(color: Colors.black87, fontSize: 13)),
          ),
          TextButton(
            onPressed: _fetchMosques,
            child: const Text('Tekrar Dene'),
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
      child: const Text('Yakınında cami bulunamadı.',
          style: TextStyle(color: Colors.black87, fontSize: 13)),
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
                  label: const Text('Araçla'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchNavigation(cami, 'Yürüme'),
                  icon: const Icon(Icons.directions_walk_rounded, size: 18),
                  label: const Text('Yürüyerek'),
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
          const PopupMenuItem(value: 'Uydu', child: Text('Uydu')),
          const PopupMenuItem(value: 'Standart', child: Text('Standart')),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
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
  late GoogleMapController _mapController;
  final CamiService _camiService = CamiService();
  Set<Marker> _markers = {};
  List<Cami> _mosques = [];
  Position? _currentPosition;
  bool _isLoading = true;
  MapType _currentMapType = MapType.satellite;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
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
                ))
            .toSet();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Cami getirme hatası: $e");
      setState(() {
        _isLoading = false;
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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude,
                        _currentPosition!.longitude),
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _markers,
                  myLocationEnabled: true,
                  mapType: _currentMapType,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildGlassButton(Icons.arrow_back_ios_new_rounded,
                            () => Navigator.pop(context)),
                        _buildMapMenu(),
                      ],
                    ),
                  ),
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
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)
          ],
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _buildMapMenu() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.menu_rounded, color: Colors.black),
        onSelected: (value) {
          setState(() {
            if (value == 'Uydu') _currentMapType = MapType.satellite;
            if (value == 'Standart') _currentMapType = MapType.normal;
          });
          if ((value == 'Otomobil' || value == 'Yürüme') &&
              _mosques.isNotEmpty) {
            _launchNavigation(_mosques.first, value);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'Uydu', child: Text('Uydu')),
          const PopupMenuItem(value: 'Standart', child: Text('Standart')),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'Otomobil', child: Text('Otomobil')),
          const PopupMenuItem(value: 'Yürüme', child: Text('Yürüme')),
        ],
      ),
    );
  }
}

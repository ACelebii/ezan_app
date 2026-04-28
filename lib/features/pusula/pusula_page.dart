import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../main/main_navigation_page.dart';
import 'pusula_controller.dart';

class PusulaPage extends StatelessWidget {
  const PusulaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PusulaController(),
      child: const _PusulaView(),
    );
  }
}

class _PusulaView extends StatelessWidget {
  const _PusulaView();

  @override
  Widget build(BuildContext context) {
    return Consumer<PusulaController>(
      builder: (context, controller, child) {
        if (!controller.isLoaded) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0B),
            body: Center(
              child: controller.errorMessage != null
                  ? Text(controller.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent))
                  : const CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }

        double displayHeading =
            (controller.cumulativeHeading % 360 + 360) % 360;
        double qibla = controller.qiblaAngle ?? 0;
        double diff = (qibla - displayHeading + 360) % 360;
        bool isAligned = diff < 5 || diff > 355;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0C),
          body: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBeautifulBackButton(context),
                    _buildMapButton(context, controller),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStatusHeader(isAligned),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildOuterGlow(isAligned),
                        _build3DBezel(),
                        _buildCompassBody(
                            displayHeading, controller, isAligned),
                        _buildFixedTopMarker(isAligned),
                        _buildGlassReflection(),
                      ],
                    ),
                  ),
                ),
                _buildAngleDisplay(displayHeading),
                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- UI Methods (No logic here) ---
  Widget _buildBeautifulBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0),
      child: InkWell(
        onTap: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const MainNavigationPage()),
              (route) => false,
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildMapButton(BuildContext context, PusulaController controller) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 8.0),
      child: InkWell(
        onTap: () {
          if (controller.currentPosition != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    QiblaMapPage(userPosition: controller.currentPosition!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Konum alınıyor, lütfen bekleyin...'),
                  backgroundColor: Colors.orange),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: const Icon(Icons.map_rounded, color: Colors.black87, size: 20),
        ),
      ),
    );
  }

  Widget _buildOuterGlow(bool isAligned) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                isAligned ? Colors.amber.withOpacity(0.2) : Colors.transparent,
            blurRadius: 50,
            spreadRadius: 15,
          )
        ],
      ),
    );
  }

  Widget _build3DBezel() {
    return Container(
      width: 330,
      height: 330,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF5A5A5E), Color(0xFF1A1A1C), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.9),
              blurRadius: 40,
              offset: const Offset(15, 15)),
          BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(-8, -8)),
        ],
      ),
    );
  }

  Widget _buildCompassBody(
      double heading, PusulaController controller, bool isAligned) {
    return AnimatedRotation(
      turns: -controller.cumulativeHeading / 360,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 295,
            height: 295,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xFF28282B), Color(0xFF0A0A0C)],
                stops: [0.6, 1.0],
              ),
            ),
          ),
          CustomPaint(
              size: const Size(295, 295), painter: RichCompassPainter()),
          _buildDirectionLetter("N", 0, Colors.redAccent),
          _buildDirectionLetter("E", 90, Colors.white70),
          _buildDirectionLetter("S", 180, Colors.white70),
          _buildDirectionLetter("W", 270, Colors.white70),
          Transform.rotate(
            angle: (controller.qiblaAngle ?? 0) * (math.pi / 180),
            child: SizedBox(
              height: 285,
              child: Column(
                children: [
                  const Icon(Icons.location_on, color: Colors.amber, size: 52),
                  Container(
                    width: 2,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.amber.withOpacity(0.8),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const Opacity(
            opacity: 0.05,
            child: Icon(Icons.explore_outlined, size: 140, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionLetter(String label, double angle, Color color) {
    return Transform.rotate(
      angle: angle * (math.pi / 180),
      child: SizedBox(
        height: 245,
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.w900)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedTopMarker(bool isAligned) {
    return Container(
      width: 4,
      height: 45,
      decoration: BoxDecoration(
        color: isAligned ? Colors.amber : Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
              color: (isAligned ? Colors.amber : Colors.white).withOpacity(0.6),
              blurRadius: 15)
        ],
      ),
      margin: const EdgeInsets.only(bottom: 315),
    );
  }

  Widget _buildGlassReflection() {
    return IgnorePointer(
      child: Container(
        width: 295,
        height: 295,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.transparent,
              Colors.black.withOpacity(0.15)
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(bool isAligned) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      decoration: BoxDecoration(
        color: isAligned ? Colors.amber.withOpacity(0.15) : Colors.black26,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isAligned ? Colors.amber : Colors.white10),
      ),
      child: Text(
        isAligned ? "KIBLEYE YÖNELDİNİZ" : "KIBLE YÖNÜ",
        style: TextStyle(
            color: isAligned ? Colors.amber : Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 2),
      ),
    );
  }

  Widget _buildAngleDisplay(double heading) {
    return Column(
      children: [
        Text("${heading.toInt()}°",
            style: const TextStyle(
                color: Colors.white,
                fontSize: 58,
                fontWeight: FontWeight.w100,
                letterSpacing: -2)),
        const Text("DERECE",
            style: TextStyle(
                color: Colors.white24,
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class RichCompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (var i = 0; i < 360; i += 2) {
      final angle = i * math.pi / 180;
      final is30 = i % 30 == 0;
      final is10 = i % 10 == 0;
      final is5 = i % 5 == 0;

      double tickLen = is30 ? 20.0 : (is10 ? 14.0 : (is5 ? 8.0 : 4.0));
      final paint = Paint()
        ..color =
            is30 ? Colors.white70 : (is10 ? Colors.white30 : Colors.white10)
        ..strokeWidth = is30 ? 2.5 : 1.0;

      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle - math.pi / 2),
            center.dy + (radius - tickLen) * math.sin(angle - math.pi / 2)),
        Offset(center.dx + radius * math.cos(angle - math.pi / 2),
            center.dy + radius * math.sin(angle - math.pi / 2)),
        paint,
      );

      if (is30 && i != 0 && i != 90 && i != 180 && i != 270) {
        _drawText(canvas, center, radius - 40, angle, i.toString());
      }
    }
  }

  void _drawText(
      Canvas canvas, Offset center, double radius, double angle, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: const TextStyle(
              color: Colors.white24,
              fontSize: 12,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();

    final x = center.dx +
        radius * math.cos(angle - math.pi / 2) -
        textPainter.width / 2;
    final y = center.dy +
        radius * math.sin(angle - math.pi / 2) -
        textPainter.height / 2;
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(oldDelegate) => false;
}

// NOTE: QiblaMapPage remains as it is or can be moved to a separate file later.
// For now, it stays here as per the original file structure, just adapted.
class QiblaMapPage extends StatefulWidget {
  final Position userPosition;
  const QiblaMapPage({super.key, required this.userPosition});

  @override
  State<QiblaMapPage> createState() => _QiblaMapPageState();
}

class _QiblaMapPageState extends State<QiblaMapPage> {
  late GoogleMapController _mapController;
  MapType _currentMapType = MapType.satellite;

  final LatLng _kabeLocation = const LatLng(21.422487, 39.826206);
  late LatLng _userLocation;

  @override
  void initState() {
    super.initState();
    _userLocation =
        LatLng(widget.userPosition.latitude, widget.userPosition.longitude);
  }

  void _goToMyLocation() {
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _userLocation, zoom: 16.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _userLocation,
              zoom: 16.0,
            ),
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: const MarkerId('kabe'),
                position: _kabeLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange),
                infoWindow: const InfoWindow(title: 'Kâbe-i Muazzama'),
              ),
            },
            polylines: {
              Polyline(
                polylineId: const PolylineId('qibla_line'),
                points: [_userLocation, _kabeLocation],
                color: Colors.orangeAccent,
                width: 4,
                patterns: [PatternItem.dash(30), PatternItem.gap(20)],
              ),
            },
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.black, size: 20),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.menu_rounded,
                          color: Colors.black, size: 24),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) {
                        setState(() {
                          if (value == 'Uydu')
                            _currentMapType = MapType.satellite;
                          if (value == 'Standart')
                            _currentMapType = MapType.normal;
                          if (value == 'Konumum') _goToMyLocation();
                        });
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'Uydu',
                          child: Row(
                            children: [
                              Icon(Icons.satellite_alt_rounded,
                                  color: _currentMapType == MapType.satellite
                                      ? Colors.blue
                                      : Colors.black87),
                              const SizedBox(width: 12),
                              Text('Uydu',
                                  style: TextStyle(
                                      color:
                                          _currentMapType == MapType.satellite
                                              ? Colors.blue
                                              : Colors.black87,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'Standart',
                          child: Row(
                            children: [
                              Icon(Icons.map_outlined,
                                  color: _currentMapType == MapType.normal
                                      ? Colors.blue
                                      : Colors.black87),
                              const SizedBox(width: 12),
                              Text('Standart',
                                  style: TextStyle(
                                      color: _currentMapType == MapType.normal
                                          ? Colors.blue
                                          : Colors.black87,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'Konumum',
                          child: Row(
                            children: [
                              Icon(Icons.near_me_rounded,
                                  color: Colors.black87),
                              SizedBox(width: 12),
                              Text('Konumum',
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600)),
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

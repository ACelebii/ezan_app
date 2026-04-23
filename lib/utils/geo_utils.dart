import 'dart:math' as math;

class GeoUtils {
  static double calculateTrueBearing(double lat, double lon) {
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
}

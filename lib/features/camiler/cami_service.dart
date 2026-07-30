import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/api_client.dart';
import 'cami_model.dart';

class CamiService {
  Future<List<Cami>> getNearbyMosques(double lat, double lon) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final response = await ApiClient.dio.get(
        'maps/api/place/nearbysearch/json?location=$lat,$lon&radius=2000&type=mosque&key=$apiKey');

    if (response.statusCode == 200) {
      final data = response.data;
      final status = data['status'] as String?;
      // Google, Places API kapalı/kotası aşılmış gibi durumlarda da HTTP 200
      // döner; gerçek sonucu 'status' alanından ayırt etmek gerekir, aksi
      // halde bir API hatası sessizce "yakında cami yok" gibi görünür.
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        throw Exception('Places API error: ${data['error_message'] ?? status}');
      }
      final List results = data['results'] ?? [];
      return results.map((e) => Cami.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load mosques');
    }
  }
}

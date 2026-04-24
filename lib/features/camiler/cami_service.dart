import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cami_model.dart';

class CamiService {
  final String _apiKey = 'AIzaSyAQYfgmJaQARDif2L2q-NPi8O1HntjSkEc';

  Future<List<Cami>> getNearbyMosques(double lat, double lon) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lon&radius=2000&type=mosque&key=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((e) => Cami.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load mosques');
    }
  }
}

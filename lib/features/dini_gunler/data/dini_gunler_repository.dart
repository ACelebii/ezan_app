import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DiniGunlerRepository {
  Future<List<Map<String, dynamic>>> getDiniGunler() async {
    final String response =
        await rootBundle.loadString('assets/json/dini_gunler.json');
    final List<dynamic> data = await json.decode(response);
    return data.cast<Map<String, dynamic>>();
  }
}

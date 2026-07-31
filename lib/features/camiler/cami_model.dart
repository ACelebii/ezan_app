class Cami {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String? address;

  Cami({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.address,
  });

  factory Cami.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']?['location'] as Map<String, dynamic>?;
    return Cami(
      id: json['place_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Cami',
      // Places API tam sayı bir koordinat döndürürse dart:convert bunu int
      // olarak çözer; doğrudan double alana atarsak TypeError fırlatır.
      lat: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (location?['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['vicinity']?.toString(),
    );
  }
}

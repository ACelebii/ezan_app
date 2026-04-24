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
    return Cami(
      id: json['place_id'],
      name: json['name'],
      lat: json['geometry']['location']['lat'],
      lon: json['geometry']['location']['lng'],
      address: json['vicinity'],
    );
  }
}

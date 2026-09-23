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

  /// Places API (New) `places` dizisindeki bir kayıttan üretir.
  factory Cami.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    final lat = location?['latitude'] as num?;
    final lon = location?['longitude'] as num?;
    // Konumsuz kayıt haritada 0,0'a (okyanus) düşerdi; fırlatılan hata
    // CamiService'te yakalanır ve kayıt atlanır.
    if (lat == null || lon == null) {
      throw const FormatException('Cami kaydında konum yok');
    }
    final adi = (json['displayName'] as Map<String, dynamic>?)?['text']?.toString();
    return Cami(
      id: json['id']?.toString() ?? '',
      name: adi == null || adi.isEmpty ? 'Cami' : adi,
      // Tam sayı bir koordinat dart:convert'te int olarak çözülür; doğrudan
      // double alana atarsak TypeError fırlatır.
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      address: json['shortFormattedAddress']?.toString(),
    );
  }
}

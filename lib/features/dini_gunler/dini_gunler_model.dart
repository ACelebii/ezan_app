class DiniGunlerModel {
  final int yil;
  final String ay;
  final String gunNo;
  final String gunAd;
  final String baslik;
  final String hicri;
  final String detay;

  DiniGunlerModel({
    required this.yil,
    required this.ay,
    required this.gunNo,
    required this.gunAd,
    required this.baslik,
    required this.hicri,
    required this.detay,
  });

  factory DiniGunlerModel.fromJson(Map<String, dynamic> json) {
    return DiniGunlerModel(
      yil: json['yil'] as int,
      ay: json['ay'] as String,
      gunNo: json['gunNo'] as String,
      gunAd: json['gunAd'] as String,
      baslik: json['baslik'] as String,
      hicri: json['hicri'] as String,
      detay: json['detay'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yil': yil,
      'ay': ay,
      'gunNo': gunNo,
      'gunAd': gunAd,
      'baslik': baslik,
      'hicri': hicri,
      'detay': detay,
    };
  }
}

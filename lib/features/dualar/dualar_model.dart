class DuaModel {
  final String baslik;
  final String arapca;
  final String okunus;
  final String anlam;

  DuaModel({
    required this.baslik,
    required this.arapca,
    required this.okunus,
    required this.anlam,
  });

  factory DuaModel.fromJson(Map<String, dynamic> json) {
    return DuaModel(
      baslik: json['baslik']?.toString() ?? '',
      arapca: json['arapca']?.toString() ?? '',
      okunus: json['okunus']?.toString() ?? '',
      anlam: json['anlam']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baslik': baslik,
      'arapca': arapca,
      'okunus': okunus,
      'anlam': anlam,
    };
  }
}

class DuaCategory {
  final String kategori;
  final List<DuaModel> dualar;

  DuaCategory({
    required this.kategori,
    required this.dualar,
  });

  factory DuaCategory.fromJson(Map<String, dynamic> json) {
    return DuaCategory(
      kategori: json['kategori']?.toString() ?? '',
      dualar: (json['dualar'] as List<dynamic>?)
              ?.map((e) => DuaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kategori': kategori,
      'dualar': dualar.map((e) => e.toJson()).toList(),
    };
  }
}

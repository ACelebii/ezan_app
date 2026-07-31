class DuaModel {
  final String baslik;
  final String arapca;
  final String okunus;
  final String anlam;
  final String kaynak;

  DuaModel({
    required this.baslik,
    required this.arapca,
    required this.okunus,
    required this.anlam,
    this.kaynak = '',
  });

  factory DuaModel.fromJson(Map<String, dynamic> json) {
    return DuaModel(
      // JSON'daki İngilizce key'leri modeldeki değişkenlerle eşleştiriyoruz
      baslik: json['title']?.toString() ?? '',
      arapca: json['arabic']?.toString() ?? '',
      okunus: json['pronunciation']?.toString() ?? '',
      anlam: json['meaning']?.toString() ?? '',
      kaynak: json['reference']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': baslik,
      'arabic': arapca,
      'pronunciation': okunus,
      'meaning': anlam,
      'reference': kaynak,
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
      // JSON'daki 'category' ve 'items' key'lerini eşleştiriyoruz
      kategori: json['category']?.toString() ?? '',
      dualar: (json['items'] as List<dynamic>?)
              ?.map((e) => DuaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': kategori,
      'items': dualar.map((e) => e.toJson()).toList(),
    };
  }
}

// lib/features/kuran/kuran_models.dart

class SurahModel {
  final int id;

  /// Latin harfli yazım (İngilizce kaynaklı), ör. "Al-Fatihah".
  final String nameSimple;
  final String nameArabic;
  final int versesCount;

  /// Türkçe adı, ör. "Fâtiha", "Bakara", "Âl-i İmrân" (API'nin `language=tr`
  /// yanıtındaki `translated_name`). Gelmezse boş.
  final String turkishName;

  /// "makkah" ya da "madinah" (bilinmiyorsa boş).
  final String revelationPlace;

  /// Mushaf'ta (604 sayfalık Medine baskısı) suranın başladığı sayfa; 0 = bilinmiyor.
  final int startPage;

  SurahModel({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
    this.turkishName = '',
    this.revelationPlace = '',
    this.startPage = 0,
  });

  /// Fihrist'te görünen iniş yeri; bilinmiyorsa boş.
  String get inisYeri => switch (revelationPlace) {
        'makkah' => 'Mekke',
        'madinah' => 'Medine',
        _ => '',
      };

  /// Ekranda görünen ad: Türkçe ad, yoksa Latin yazım.
  String get displayName => turkishName.isNotEmpty ? turkishName : nameSimple;

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final cevirili = json['translated_name'];
    return SurahModel(
      id: json['id'] ?? 0,
      nameSimple: json['name_simple']?.toString() ?? '',
      nameArabic: json['name_arabic']?.toString() ?? '',
      versesCount: json['verses_count'] ?? 0,
      revelationPlace: json['revelation_place']?.toString() ?? '',
      startPage: json['start_page'] ?? 0,
      turkishName: cevirili is Map &&
              cevirili['language_name']?.toString().toLowerCase() == 'turkish'
          ? cevirili['name']?.toString() ?? ''
          : '',
    );
  }
}

class AyahModel {
  final int id;
  final String verseKey;
  final String textUthmani;
  final String translation;

  /// İngilizce meal (Saheeh International); yoksa boş.
  final String translationEn;

  /// Mealin kaynağı: "Diyanet"; Diyanet metni boşsa ya da önceki ayetle aynı
  /// blok ise (Diyanet birkaç ayeti birlikte çevirir) "Elmalılı".
  final String mealKaynagi;
  final String audioUrl;
  final int pageNumber;

  AyahModel({
    required this.id,
    required this.verseKey,
    required this.textUthmani,
    required this.translation,
    required this.audioUrl,
    required this.pageNumber,
    this.mealKaynagi = 'Diyanet',
    this.translationEn = '',
  });

  AyahModel sesli(String url) => AyahModel(
        id: id,
        verseKey: verseKey,
        textUthmani: textUthmani,
        translation: translation,
        translationEn: translationEn,
        audioUrl: url,
        pageNumber: pageNumber,
        mealKaynagi: mealKaynagi,
      );

  /// Cihaz önbelleği biçimi. Ses adresi yazılmaz (okuyucuya bağlı, türetilir).
  Map<String, dynamic> toJson() => {
        'id': id,
        'k': verseKey,
        'a': textUthmani,
        'm': translation,
        'e': translationEn,
        's': mealKaynagi,
        'p': pageNumber,
      };

  /// Önceki [toJson] çıktısından; bozuk kayıt için hata fırlatır.
  factory AyahModel.fromCache(Map<String, dynamic> j) => AyahModel(
        id: j['id'] as int,
        verseKey: j['k'] as String,
        textUthmani: j['a'] as String,
        translation: j['m'] as String,
        translationEn: j['e'] as String,
        mealKaynagi: j['s'] as String,
        audioUrl: '',
        pageNumber: j['p'] as int,
      );
}

/// Meal metnindeki HTML: etiketler (dipnot `<sup>`...) silinir, karakter kodları
/// (`&quot;`, `&amp;`, `&#39;`) gerçek karaktere çevrilir. Aksi halde ekranda
/// harfiyen "&quot;" görünür.
String mealMetniniTemizle(String metin) {
  const adlar = {
    'quot': '"',
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'apos': "'",
    'nbsp': ' ',
  };
  return metin
      // Dipnot işaretleri (`<sup foot_note=..>1</sup>`) tamamen atılır; yoksa
      // rakam kelimeye yapışır ("Allāh,1 the Entirely Merciful,2").
      .replaceAll(RegExp(r'\s*<sup[^>]*>.*?</sup>', dotAll: true), '')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAllMapped(RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);'), (m) {
    final k = m[1]!;
    if (k.startsWith('#x') || k.startsWith('#X')) {
      final kod = int.tryParse(k.substring(2), radix: 16);
      return kod == null ? m[0]! : String.fromCharCode(kod);
    }
    if (k.startsWith('#')) {
      final kod = int.tryParse(k.substring(1));
      return kod == null ? m[0]! : String.fromCharCode(kod);
    }
    return adlar[k] ?? m[0]!;
  });
}

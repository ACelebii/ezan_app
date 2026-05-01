// lib/features/kuran/kuran_models.dart

class SurahModel {
  final int id;
  final String nameSimple;
  final String nameArabic;
  final int versesCount;

  SurahModel({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] ?? 0,
      nameSimple: json['name_simple']?.toString() ?? '',
      nameArabic: json['name_arabic']?.toString() ?? '',
      versesCount: json['verses_count'] ?? 0,
    );
  }
}

class AyahModel {
  final int id;
  final String verseKey;
  final String textUthmani;
  final String translation;
  final String audioUrl;
  final int pageNumber;

  AyahModel({
    required this.id,
    required this.verseKey,
    required this.textUthmani,
    required this.translation,
    required this.audioUrl,
    required this.pageNumber,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    // Ne gelirse gelsin zorla String'e çeviriyoruz (.toString() eklendi)
    String arText = json['text_uthmani']?.toString() ?? '';

    String trText = '';
    if (json['translations'] != null &&
        (json['translations'] as List).isNotEmpty) {
      trText = json['translations'][0]['text']?.toString() ?? '';
      trText = trText.replaceAll(RegExp(r'<[^>]*>'), '');
    }

    String audio = '';
    if (json['audio'] != null && json['audio'] is Map) {
      audio = json['audio']['url']?.toString() ?? '';
      if (audio.isNotEmpty && !audio.startsWith('http')) {
        audio = 'https://verses.quran.com/$audio';
      }
    }

    return AyahModel(
      // Sayı dönüşümlerini her ihtimale karşı garantiledik
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      verseKey: json['verse_key']?.toString() ?? '',
      textUthmani: arText,
      translation: trText,
      audioUrl: audio,
      pageNumber: json['page_number'] is int
          ? json['page_number']
          : int.tryParse(json['page_number']?.toString() ?? '1') ?? 1,
    );
  }
}

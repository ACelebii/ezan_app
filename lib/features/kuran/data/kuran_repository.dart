// lib/features/kuran/data/kuran_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/utils/result.dart';
import '../kuran_models.dart';

class KuranRepository {
  Future<Result<List<SurahModel>>> getSurahs() async {
    try {
      final url = 'https://api.quran.com/api/v4/chapters?language=tr';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['chapters'] as List;
        final list = data.map((e) => SurahModel.fromJson(e)).toList();
        return Success(list);
      }
      return Failure("Sureler yüklenemedi: HTTP ${response.statusCode}");
    } catch (e) {
      return Failure("Sureler yüklenirken bağlantı hatası: $e");
    }
  }

  // YENİ EKLENEN: Güvenli Ayet Çekme (Ses ve Çeviri hatalarını görmezden gelmek için)
  Future<Result<List<AyahModel>>> getAyahsBySurah(
    int surahId,
    int reciterId,
  ) async {
    try {
      // Çeviri (77) ve Ses parametresi eklendi. per_page sınırı 500 yapıldı.
      final detailedUrl =
          'https://api.quran.com/api/v4/verses/by_chapter/$surahId?language=tr&words=false&translations=77&audio=$reciterId&fields=text_uthmani&per_page=500';
      final response = await http.get(Uri.parse(detailedUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['verses'] as List;
        final list = data.map((e) => AyahModel.fromJson(e)).toList();
        return Success(list);
      }
      return Failure(
        "Sure ayetleri yüklenemedi: HTTP ${response.statusCode}\nBody: ${response.body}",
      );
    } catch (e) {
      return Failure("Sure ayetleri çekilirken bağlantı hatası: $e");
    }
  }

  Future<Result<List<AyahModel>>> getAyahsByJuz(
    int juzId,
    int reciterId,
  ) async {
    try {
      final detailedUrl =
          'https://api.quran.com/api/v4/verses/by_juz/$juzId?language=tr&words=false&translations=77&audio=$reciterId&fields=text_uthmani&per_page=500';
      final response = await http.get(Uri.parse(detailedUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['verses'] as List;
        final list = data.map((e) => AyahModel.fromJson(e)).toList();
        return Success(list);
      }
      return Failure("Cüz ayetleri yüklenemedi: HTTP ${response.statusCode}");
    } catch (e) {
      return Failure("Cüz ayetleri çekilirken bağlantı hatası: $e");
    }
  }

  Future<Result<List<AyahModel>>> getAyahsByPage(
    int pageId,
    int reciterId,
  ) async {
    try {
      final detailedUrl =
          'https://api.quran.com/api/v4/verses/by_page/$pageId?language=tr&words=false&translations=77&audio=$reciterId&fields=text_uthmani&per_page=500';
      final response = await http.get(Uri.parse(detailedUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['verses'] as List;
        final list = data.map((e) => AyahModel.fromJson(e)).toList();
        return Success(list);
      }
      return Failure("Sayfa ayetleri yüklenemedi: HTTP ${response.statusCode}");
    } catch (e) {
      return Failure("Sayfa ayetleri çekilirken bağlantı hatası: $e");
    }
  }

  Future<Result<List<int>>> getJuzList() async {
    try {
      final list = List<int>.generate(30, (i) => i + 1);
      return Success(list);
    } catch (e) {
      return Failure("Cüzler yüklenemedi: $e");
    }
  }
}

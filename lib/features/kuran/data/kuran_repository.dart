// lib/features/kuran/data/kuran_repository.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/result.dart';
import '../kuran_models.dart';

/// Kur'an verisi.
/// - 114 surenin listesi uygulamaya gömülüdür (internet gerekmez).
/// - Ayetler quran.com API v4'ten gelir ve İLK OKUMADA cihaza kaydedilir; sonra
///   internetsiz açılır (Kur'an metni değişmez, önce önbelleğe bakılır).
/// - Meal: Diyanet (İngilizce arayüzde Saheeh International); Diyanet metni boşsa ya da önceki ayetle aynı blok ise
///   (Diyanet birkaç ayeti birlikte çevirir) o ayet Elmalılı'dan tamamlanır ve
///   kaynak ayette işaretlenir.
/// Kullanıcıya gösterilen hata metinleri teknik ayrıntı (HTTP gövdesi, istisna
/// adı) içermez; ayrıntı yalnızca günlüğe yazılır.
class KuranRepository {
  KuranRepository({
    http.Client? istemci,
    AssetBundle? varliklar,
    Directory? onbellekKlasoru,
    this.zamanAsimi = const Duration(seconds: 20),
  })  : _istemci = istemci ?? http.Client(),
        _varliklar = varliklar ?? rootBundle,
        _verilenKlasor = onbellekKlasoru;

  final http.Client _istemci;
  final AssetBundle _varliklar;
  final Directory? _verilenKlasor;

  /// quran.com `chapters?language=tr` yanıtından üretildi ve doğrulandı
  /// (114 sure, toplam 6236 ayet, sayfa 1-604; ayet sayıları ve iniş yerleri
  /// alquran.cloud ile birebir aynı).
  static const _sureDosyasi = 'assets/json/sureler.json';

  /// `tools/meal_gruplu_uret.py` üretir: Diyanet'in önceki ayetle aynı metin
  /// verdiği ve Elmalılı'nın ayete özel metin verdiği ayetler.
  static const _grupluDosyasi = 'assets/json/diyanet_gruplu.json';

  /// Tek bir isteğin en uzun süresi.
  final Duration zamanAsimi;

  static const _kok = 'https://api.quran.com/api/v4';

  /// quran.com çeviri kimlikleri: 77 = Diyanet, 52 = Elmalılı Hamdi Yazır,
  /// 20 = Saheeh International (İngilizce; 6236 ayetin hepsinde dolu).
  static const _diyanetId = 77;
  static const _elmaliId = 52;
  static const _ingilizceId = 20;

  /// API en fazla bu kadar ayeti tek sayfada verir; daha fazlası sayfalanır
  /// (Cüz 30: 564 ayet). Sayfalama izlenmezse fazlası SESSİZCE düşer.
  static const _sayfaBoyutu = 500;

  /// Bir sure/cüz/sayfa en fazla bu kadar API sayfasına bölünebilir; sunucu
  /// hatalı `next_page` verirse sonsuz döngüyü önleyen üst sınır.
  static const _enFazlaSayfa = 20;

  /// Önbellek biçimi değişirse (ör. meal kuralı) artırılır; eski dosyalar
  /// görmezden gelinir.
  static const _onbellekSurumu = 2;

  /// Okuyucu kimliği -> ses adresi ön eki. Adres `{ön ek}/{sure 3 hane}{ayet 3
  /// hane}.mp3`; 4 okuyucu x 5 sure (1688 ayet) API yanıtıyla birebir doğrulandı.
  /// (Husary'nin API adresi `//mirrors...` diye başlar; eski kod başına
  /// `https://verses.quran.com/` ekleyip 404 veren bir adres kuruyordu.)
  static const _sesOnEkleri = {
    1: 'https://verses.quran.com/AbdulBaset/Mujawwad/mp3',
    7: 'https://verses.quran.com/Alafasy/mp3',
    12: 'https://mirrors.quranicaudio.com/everyayah/Husary_Muallim_128kbps',
    3: 'https://verses.quran.com/Sudais/mp3',
  };

  /// [verseKey] ("2:255") ayetinin [reciterId] okuyucusundaki ses adresi;
  /// bilinmeyen okuyucu ya da bozuk anahtar için boş.
  static String sesAdresi(int reciterId, String verseKey) {
    final onEk = _sesOnEkleri[reciterId];
    final p = verseKey.split(':');
    final sure = p.length == 2 ? int.tryParse(p[0]) : null;
    final ayet = p.length == 2 ? int.tryParse(p[1]) : null;
    if (onEk == null || sure == null || ayet == null) return '';
    return '$onEk/${sure.toString().padLeft(3, '0')}${ayet.toString().padLeft(3, '0')}.mp3';
  }

  Future<Result<List<SurahModel>>> getSurahs() async {
    try {
      final metin = await _varliklar.loadString(_sureDosyasi);
      final liste = (json.decode(metin) as Map)['chapters'] as List;
      return Success(liste.map((e) => SurahModel.fromJson(e)).toList());
    } catch (e) {
      debugPrint('Sure listesi okunamadı: $e');
      return Failure('Sure listesi okunamadı.');
    }
  }

  Future<Result<List<AyahModel>>> getAyahsBySurah(int surahId, int reciterId) =>
      _ayetleriGetir(
          'by_chapter/$surahId', 'sure_$surahId', reciterId, 'Sure ayetleri');

  Future<Result<List<AyahModel>>> getAyahsByJuz(int juzId, int reciterId) =>
      _ayetleriGetir('by_juz/$juzId', 'cuz_$juzId', reciterId, 'Cüz ayetleri');

  Future<Result<List<AyahModel>>> getAyahsByPage(int pageId, int reciterId) =>
      _ayetleriGetir(
          'by_page/$pageId', 'sayfa_$pageId', reciterId, 'Sayfa ayetleri');

  Future<Result<List<int>>> getJuzList() async =>
      Success(List<int>.generate(30, (i) => i + 1));

  /// [yol] için TÜM ayetleri döndürür: önce cihaz önbelleği, yoksa sayfa sayfa
  /// toplayarak ağdan (ve başarılıysa önbelleğe yazarak).
  Future<Result<List<AyahModel>>> _ayetleriGetir(
      String yol, String anahtar, int reciterId, String ne) async {
    final kayitli = await _onbellektenOku(anahtar);
    if (kayitli != null) return Success(_sesle(kayitli, reciterId));

    try {
      final gruplu = await _grupluAyetler();
      final ayetler = <AyahModel>[];
      var sayfa = 1;
      for (var tur = 0; tur < _enFazlaSayfa; tur++) {
        final adres = Uri.parse('$_kok/verses/$yol?language=tr&words=false'
            '&translations=$_diyanetId,$_elmaliId,$_ingilizceId&fields=text_uthmani'
            '&per_page=$_sayfaBoyutu&page=$sayfa');
        final yanit = await _istemci.get(adres).timeout(zamanAsimi);
        if (yanit.statusCode != 200) {
          debugPrint('$ne ($yol, sayfa $sayfa): HTTP ${yanit.statusCode}');
          return Failure(_hataMetni(ne, yanit.statusCode));
        }
        final govde = _coz(yanit);
        ayetler.addAll((govde['verses'] as List)
            .map((e) => _ayetiCoz(e as Map<String, dynamic>, gruplu)));

        final sonraki = (govde['pagination'] as Map?)?['next_page'];
        if (sonraki is! int || sonraki <= sayfa) {
          await _onbellegeYaz(anahtar, ayetler);
          return Success(_sesle(ayetler, reciterId));
        }
        sayfa = sonraki;
      }
      // Üst sınıra takıldı: eksik ayetli listeyi tam gibi göstermek yerine hata.
      debugPrint('$ne ($yol): sayfa sınırı aşıldı');
      return Failure(_hataMetni(ne));
    } catch (e) {
      debugPrint('$ne ($yol) alınamadı: $e');
      return Failure(_hataMetni(ne));
    }
  }

  /// Cihazda kayıtlı (ağa çıkmadan okunabilen) sure numaraları.
  Future<Set<int>> onbellekliSureler() async {
    try {
      final k = await _klasor();
      if (k == null) return {};
      final kalip = RegExp('^v${_onbellekSurumu}_sure_(\\d+)\\.json\$');
      return {
        for (final f in k.listSync())
          if (f is File)
            if (kalip.firstMatch(f.uri.pathSegments.last) case final m?)
              int.parse(m[1]!),
      };
    } catch (e) {
      debugPrint('Kayıtlı sure listesi okunamadı: $e');
      return {};
    }
  }

  /// [sureId] suresinin cihazdaki kaydı (ağa ASLA çıkmaz); yoksa null. Ses
  /// adresi boştur (okuyucuya bağlı, gerekirse `getAyahsBySurah` verir).
  Future<List<AyahModel>?> sureOnbellekten(int sureId) =>
      _onbellektenOku('sure_$sureId');

  List<AyahModel> _sesle(List<AyahModel> ayetler, int reciterId) => [
        for (final a in ayetler) a.sesli(sesAdresi(reciterId, a.verseKey)),
      ];

  /// Bir API ayetini uygulama modeline çevirir; meal kuralı burada.
  AyahModel _ayetiCoz(Map<String, dynamic> j, Set<String> gruplu) {
    final anahtar = j['verse_key']?.toString() ?? '';
    String meal(int kimlik) {
      for (final t in (j['translations'] as List? ?? const [])) {
        if (t is Map && t['resource_id'] == kimlik) {
          return mealMetniniTemizle(t['text']?.toString() ?? '').trim();
        }
      }
      return '';
    }

    final diyanet = meal(_diyanetId), elmali = meal(_elmaliId);
    final elmalidan =
        elmali.isNotEmpty && (diyanet.isEmpty || gruplu.contains(anahtar));
    return AyahModel(
      id: j['id'] is int ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      verseKey: anahtar,
      textUthmani: j['text_uthmani']?.toString() ?? '',
      translation: elmalidan ? elmali : diyanet,
      translationEn: meal(_ingilizceId),
      mealKaynagi: elmalidan ? 'Elmalılı' : 'Diyanet',
      audioUrl: '',
      pageNumber: j['page_number'] is int
          ? j['page_number'] as int
          : int.tryParse('${j['page_number']}') ?? 1,
    );
  }

  Future<Set<String>>? _grupluOnbellek;

  /// "2:27" gibi ayet anahtarları. Dosya okunamazsa boş küme (yalnız Diyanet'in
  /// boş bıraktığı ayetler Elmalılı'dan tamamlanır).
  Future<Set<String>> _grupluAyetler() => _grupluOnbellek ??= () async {
        try {
          final metin = await _varliklar.loadString(_grupluDosyasi);
          final sure = (json.decode(metin) as Map)['sure'] as Map;
          return {
            for (final e in sure.entries)
              for (final a in e.value as List) '${e.key}:$a',
          };
        } catch (e) {
          debugPrint('Diyanet grup listesi okunamadı: $e');
          return <String>{};
        }
      }();

  // ---------------- cihaz önbelleği ----------------

  Future<Directory?> _klasor() async {
    try {
      final k = _verilenKlasor ??
          Directory(
              '${(await getApplicationSupportDirectory()).path}/kuran_ayetler');
      if (!await k.exists()) await k.create(recursive: true);
      return k;
    } catch (e) {
      debugPrint('Kur\'an önbellek klasörü açılamadı: $e');
      return null;
    }
  }

  Future<File?> _dosya(String anahtar) async {
    final k = await _klasor();
    return k == null
        ? null
        : File('${k.path}/v${_onbellekSurumu}_$anahtar.json');
  }

  /// Bozuk ya da eksik dosya "önbellek yok" sayılır (ağdan yeniden alınır).
  Future<List<AyahModel>?> _onbellektenOku(String anahtar) async {
    try {
      final d = await _dosya(anahtar);
      if (d == null || !await d.exists()) return null;
      final govde = json.decode(await d.readAsString()) as Map;
      if (govde['v'] != _onbellekSurumu) return null;
      final liste = [
        for (final e in govde['ayetler'] as List)
          AyahModel.fromCache(e as Map<String, dynamic>),
      ];
      return liste.isEmpty ? null : liste;
    } catch (e) {
      debugPrint('Kur\'an önbelleği okunamadı ($anahtar): $e');
      return null;
    }
  }

  /// Yazılamazsa (disk dolu vb.) sessizce geçer: okuma etkilenmez.
  Future<void> _onbellegeYaz(String anahtar, List<AyahModel> ayetler) async {
    try {
      final d = await _dosya(anahtar);
      if (d == null) return;
      final gecici = File('${d.path}.tmp');
      await gecici.writeAsString(
          json.encode({
            'v': _onbellekSurumu,
            'ayetler': [for (final a in ayetler) a.toJson()],
          }),
          flush: true);
      await gecici.rename(d.path);
    } catch (e) {
      debugPrint('Kur\'an önbelleğine yazılamadı ($anahtar): $e');
    }
  }

  /// Yanıtı başlıktaki charset'e güvenmeden UTF-8 olarak çözer (Türkçe meal).
  static Map<String, dynamic> _coz(http.Response yanit) =>
      json.decode(utf8.decode(yanit.bodyBytes)) as Map<String, dynamic>;

  static String _hataMetni(String ne, [int? httpKodu]) => httpKodu == null
      ? '$ne yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.'
      : '$ne yüklenemedi (sunucu yanıtı: $httpKodu). Lütfen daha sonra tekrar deneyin.';
}

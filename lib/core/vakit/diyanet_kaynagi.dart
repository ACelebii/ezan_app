// Diyanet'in yayınladığı namaz vakitleri (EzanVakti API üzerinden).
//
// Bu dosya da saf Dart: `http` ve `timezone` dışında bir şeye bağlı değil.
// Ağ isteği ile ayrıştırma ayrı tutuldu: [DiyanetKaynagi.coz] yalnızca metin
// alır, bu yüzden internetsiz test edilebilir.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

import '../utils/arama_metni.dart';
import 'vakit_modelleri.dart';
import 'zaman_dilimi.dart';

// `aramaMetni` eskiden bu dosyadaydı; eski `show aramaMetni` içe aktarmaları çalışsın.
export '../utils/arama_metni.dart';

/// Diyanet kaynağından vakit alınamadığında fırlatılır. Çağıran taraf bu hatayı
/// yakalayıp yedek kaynağa (Aladhan) geçer.
class DiyanetHatasi implements Exception {
  DiyanetHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => 'DiyanetHatasi: $mesaj';
}

/// Ülke, şehir ya da ilçe listesindeki bir satır.
class DiyanetYeri {
  const DiyanetYeri({required this.id, required this.ad, required this.adEn});

  final int id;

  /// Diyanet'in yazımıyla, ör. "AFYONKARAHİSAR".
  final String ad;

  /// Latin harfli yazım, ör. "AFYONKARAHISAR". Arama için işe yarar.
  final String adEn;
}

/// [yerler] içinden Türkçe ya da Latin adında [arama] geçenleri (sıra korunur).
List<DiyanetYeri> yerleriSuz(List<DiyanetYeri> yerler, String arama) {
  final aranan = aramaMetni(arama);
  if (aranan.isEmpty) return yerler;
  return yerler
      .where((y) =>
          aramaMetni(y.ad).contains(aranan) ||
          aramaMetni(y.adEn).contains(aranan))
      .toList();
}

class DiyanetKaynagi {
  DiyanetKaynagi({http.Client? istemci}) : _istemci = istemci ?? http.Client();

  final http.Client _istemci;

  static const _kok = 'https://ezanvakti.emushaf.net';
  static const _zamanAsimi = Duration(seconds: 10);

  /// [konum] için yaklaşık 32 günlük vakti getirir (içinde bulunulan haftanın
  /// başından başlar).
  Future<List<GunlukVakit>> vakitleriGetir(Konum konum) async {
    final ilceId = konum.diyanetIlceId;
    if (ilceId == null) {
      throw DiyanetHatasi('${konum.ad} için Diyanet ilçe kodu yok.');
    }
    return coz(await _getir('/vakitler/$ilceId'), konum);
  }

  /// Yer listeleri (değişmez): başarılı yanıtlar bu nesnenin ömrü boyunca
  /// saklanır. Diyanet'in EzanVakti sunucusu art arda ~15 istekten sonra 429
  /// ("çok fazla istek") döndürüyor; seçici ve GPS eşleştirmesi aynı listeleri
  /// tekrar tekrar isterdi. Hatalar saklanmaz (tekrar denenebilir).
  final _listeOnbellegi = <String, List<DiyanetYeri>>{};

  Future<List<DiyanetYeri>> _liste(String yol, String alan) async {
    final eldeki = _listeOnbellegi[yol];
    if (eldeki != null) return eldeki;
    return _listeOnbellegi[yol] = _yerleriCoz(await _getir(yol), alan);
  }

  Future<List<DiyanetYeri>> ulkeler() => _liste('/ulkeler', 'Ulke');

  /// Türkiye'de iller, ABD gibi ülkelerde eyaletler.
  Future<List<DiyanetYeri>> sehirler(int ulkeId) =>
      _liste('/sehirler/$ulkeId', 'Sehir');

  Future<List<DiyanetYeri>> ilceler(int sehirId) =>
      _liste('/ilceler/$sehirId', 'Ilce');

  Future<String> _getir(String yol) async {
    final http.Response yanit;
    try {
      yanit = await _istemci.get(Uri.parse('$_kok$yol')).timeout(_zamanAsimi);
    } on Exception catch (e) {
      // Zaman aşımı, bağlantı yok, DNS hatası...
      throw DiyanetHatasi('Diyanet servisine ulaşılamadı: $e');
    }
    if (yanit.statusCode != 200) {
      throw DiyanetHatasi('Diyanet servisi ${yanit.statusCode} döndürdü.');
    }
    // Başlıktaki charset'e güvenme: Türkçe harfler her durumda UTF-8 çözülür.
    return utf8.decode(yanit.bodyBytes);
  }

  /// `/vakitler/{ilceId}` yanıtını günlük vakitlere çevirir. Bozuk satırlar
  /// atlanır; hiç geçerli satır kalmazsa [DiyanetHatasi] fırlatır.
  static List<GunlukVakit> coz(String json, Konum konum) {
    zamanDilimleriniHazirla();
    final satirlar = _listeCoz(json);
    final saatDilimi = tz.getLocation(konum.saatDilimi);

    final gunler = <GunlukVakit>[];
    for (final satir in satirlar) {
      if (satir is Map<String, dynamic>) {
        final gun = _gunuCoz(satir, saatDilimi);
        if (gun != null) gunler.add(gun);
      }
    }
    if (gunler.isEmpty) {
      throw DiyanetHatasi('Yanıtta geçerli bir vakit satırı yok.');
    }
    return gunler;
  }

  static const _alanlar = {
    Vakit.imsak: 'Imsak',
    Vakit.gunes: 'Gunes',
    Vakit.ogle: 'Ogle',
    Vakit.ikindi: 'Ikindi',
    Vakit.aksam: 'Aksam',
    Vakit.yatsi: 'Yatsi',
  };

  static GunlukVakit? _gunuCoz(Map<String, dynamic> satir, tz.Location dilim) {
    final tarih = _tarihCoz(satir['MiladiTarihKisa']);
    if (tarih == null) return null;

    final saatler = <Vakit, String>{};
    final anlar = <Vakit, DateTime>{};
    for (final MapEntry(key: vakit, value: alan) in _alanlar.entries) {
      final metin = satir[alan];
      final saatDakika = metin is String ? saatDakikaCoz(metin) : null;
      if (saatDakika == null) return null;
      final (:saat, :dakika) = saatDakika;
      saatler[vakit] = '${saat.toString().padLeft(2, '0')}:'
          '${dakika.toString().padLeft(2, '0')}';
      // Saat o yerin yerel saatidir; gerçek anı IANA dilimiyle hesapla.
      anlar[vakit] = tz.TZDateTime(
          dilim, tarih.year, tarih.month, tarih.day, saat, dakika);
    }
    final hicri = satir['HicriTarihUzun'];
    return GunlukVakit(
      tarih: tarih,
      saatler: saatler,
      anlar: anlar,
      kaynak: VakitKaynagi.diyanet,
      hicriTarih: hicri is String ? hicri : null,
    );
  }

  /// "19.09.2026" → `DateTime.utc(2026, 9, 19)`. Geçersizse null.
  static DateTime? _tarihCoz(Object? metin) {
    final parcalar = metin is String ? metin.split('.') : const <String>[];
    if (parcalar.length != 3) return null;
    return gunAnahtariniCoz('${parcalar[2]}-${parcalar[1].padLeft(2, '0')}-'
        '${parcalar[0].padLeft(2, '0')}');
  }

  /// [onEk]: 'Ulke', 'Sehir' ya da 'Ilce' (alan adları buna göre: UlkeAdi,
  /// UlkeAdiEn, UlkeID). ID'ler API'den metin olarak gelir.
  static List<DiyanetYeri> _yerleriCoz(String json, String onEk) {
    final yerler = <DiyanetYeri>[];
    for (final satir in _listeCoz(json)) {
      if (satir is! Map<String, dynamic>) continue;
      final id = int.tryParse('${satir['${onEk}ID']}');
      final ad = satir['${onEk}Adi'];
      if (id == null || ad is! String) continue;
      final adEn = satir['${onEk}AdiEn'];
      yerler.add(DiyanetYeri(id: id, ad: ad, adEn: adEn is String ? adEn : ad));
    }
    if (yerler.isEmpty) throw DiyanetHatasi('Yanıtta geçerli bir yer yok.');
    return yerler;
  }

  static List<dynamic> _listeCoz(String json) {
    final Object? veri;
    try {
      veri = jsonDecode(json);
    } on FormatException catch (e) {
      throw DiyanetHatasi('Yanıt JSON değil: ${e.message}');
    }
    if (veri is! List) throw DiyanetHatasi('Yanıt bir liste değil.');
    return veri;
  }
}

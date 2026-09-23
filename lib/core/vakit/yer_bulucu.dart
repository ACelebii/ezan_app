// Diyanet'in ülke → şehir → ilçe listesinden seçilen bir yeri, uygulamanın
// [Konum]una çevirir.
//
// Diyanet listeleri koordinat ve saat dilimi vermez, ikisi de gerekli:
// koordinat yedek kaynak (Aladhan) ve hava durumu için, saat dilimi de
// vakitlerin gerçek anını (geri sayım, bildirim) bulmak için. Koordinatı
// Nominatim (OpenStreetMap), saat dilimini Aladhan (koordinattan) verir.
// Yanlış yer = yanlış saat dilimi = yanlış bildirim anı; bu yüzden hata
// durumunda tahmin yürütülmez, [YerBulucuHatasi] fırlatılır.
//
// Saf Dart: yalnızca `http` ve `timezone`a bağlı.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

import 'diyanet_kaynagi.dart';
import 'vakit_modelleri.dart';
import 'zaman_dilimi.dart';

/// Yerin koordinatı ya da saat dilimi bulunamadığında fırlatılır.
class YerBulucuHatasi implements Exception {
  YerBulucuHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => 'YerBulucuHatasi: $mesaj';
}

/// Diyanet'in ülke listesinde Türkiye'nin kimliği.
const diyanetTurkiyeUlkeId = 2;

/// "LOS ANGELES" → "Los Angeles". Diyanet adları BÜYÜK HARFLİDİR. [turkce]
/// true ise Türkçe kuralı uygulanır ("İSTANBUL" → "İstanbul", "IĞDIR" → "Iğdır");
/// yabancı yerlerin adı ASCII İngilizcedir, orada "I" küçülünce "i" olur.
String baslikYaz(String metin, {bool turkce = false}) {
  final kucuk = metin
      .trim()
      .replaceAll('İ', 'i')
      .replaceAll('I', turkce ? 'ı' : 'i')
      .toLowerCase();
  return kucuk
      .replaceAllMapped(
        RegExp(r"(^|[\s\-'(])(\S)"),
        (m) => '${m[1]}${turkce && m[2] == 'i' ? 'İ' : m[2]!.toUpperCase()}',
      )
      // Bağlaçlar küçük kalır ("Antigua ve Barbuda"); ilk kelime hariç.
      .replaceAllMapped(
          RegExp(r' (Ve|And|Of|The)(?= )'), (m) => ' ${m[1]!.toLowerCase()}');
}

class YerBulucu {
  YerBulucu({
    http.Client? istemci,
    this.denemeAraligi = const Duration(milliseconds: 1100),
  }) : _istemci = istemci ?? http.Client();

  final http.Client _istemci;

  /// Nominatim saniyede en çok 1 istek ister; ikinci aday sorgudan önce beklenir.
  final Duration denemeAraligi;

  static const _zamanAsimi = Duration(seconds: 10);

  // Nominatim kullanım koşulu: uygulamayı tanıtan bir User-Agent şart.
  static const _kimlik = 'ezan_vakti_uygulamasi/1.0 (Flutter)';

  /// [ilce] için [Konum] üretir. [sehir], ülkenin şehir/eyalet basamağıdır
  /// (yoksa null; ülke adıyla aynıysa yok sayılır).
  Future<Konum> bul({
    required DiyanetYeri ulke,
    DiyanetYeri? sehir,
    required DiyanetYeri ilce,
  }) async {
    final turkiye = ulke.id == diyanetTurkiyeUlkeId;
    final koordinat = await _koordinat(ulke, sehir, ilce);
    final saatDilimi = turkiye
        ? 'Europe/Istanbul'
        : await saatDilimiBul(koordinat.enlem, koordinat.boylam);
    return Konum(
      ad: baslikYaz(ilce.ad, turkce: turkiye),
      ulke: baslikYaz(ulke.ad, turkce: true),
      saatDilimi: saatDilimi,
      diyanetIlceId: ilce.id,
      enlem: koordinat.enlem,
      boylam: koordinat.boylam,
    );
  }

  /// Önce "İlçe, Şehir, Ülke", olmazsa "İlçe, Ülke" aranır. (Diyanet'in
  /// eyalet adı OSM'dekiyle uyuşmazsa ikincisi yine bulur.)
  Future<({double enlem, double boylam})> _koordinat(
      DiyanetYeri ulke, DiyanetYeri? sehir, DiyanetYeri ilce) async {
    String yaz(DiyanetYeri y) => baslikYaz(y.adEn);
    final adaylar = <String>{
      {yaz(ilce), if (sehir != null) yaz(sehir), yaz(ulke)}.join(', '),
      {yaz(ilce), yaz(ulke)}.join(', '),
    };

    var ilk = true;
    for (final sorgu in adaylar) {
      if (!ilk) await Future<void>.delayed(denemeAraligi);
      ilk = false;
      final sonuc = await _nominatim(sorgu);
      if (sonuc != null) return sonuc;
    }
    throw YerBulucuHatasi('Konum bulunamadı: ${adaylar.first}');
  }

  /// Koordinatın adres bilgisi (Nominatim ters geokodlama, İngilizce adlar):
  /// `country`, `country_code`, `state`, `province`, `town`, `city`... Yalnızca
  /// dolu metin alanlar döner. Bir yer bulunamazsa (okyanus gibi) boş harita.
  Future<Map<String, String>> adresBul(double enlem, double boylam) async {
    final yanit = await _al(
      Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': '$enlem',
        'lon': '$boylam',
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'en',
        'zoom': '14',
      }),
      'Konum servisi',
    );
    final Object? veri;
    try {
      veri = jsonDecode(yanit);
    } on FormatException {
      throw YerBulucuHatasi('Konum servisi anlaşılmaz yanıt verdi.');
    }
    final adres = veri is Map ? veri['address'] : null;
    if (adres is! Map) return {};
    return {
      for (final e in adres.entries)
        if (e.value is String && (e.value as String).trim().isNotEmpty)
          '${e.key}': (e.value as String).trim(),
    };
  }

  Future<({double enlem, double boylam})?> _nominatim(String sorgu) async {
    final yanit = await _al(
      Uri.https('nominatim.openstreetmap.org', '/search',
          {'q': sorgu, 'format': 'jsonv2', 'limit': '1'}),
      'Konum servisi',
    );
    final Object? veri;
    try {
      veri = jsonDecode(yanit);
    } on FormatException {
      throw YerBulucuHatasi('Konum servisi anlaşılmaz yanıt verdi.');
    }
    if (veri is! List || veri.isEmpty) return null;
    final ilk = veri.first;
    final enlem = ilk is Map ? double.tryParse('${ilk['lat']}') : null;
    final boylam = ilk is Map ? double.tryParse('${ilk['lon']}') : null;
    if (enlem == null || boylam == null) return null;
    if (enlem.abs() > 90 || boylam.abs() > 180) return null;
    return (enlem: enlem, boylam: boylam);
  }

  /// Koordinatın IANA saat dilimi (Aladhan'ın `meta.timezone`u). Bilinmeyen ya da
  /// alınamayan saat dilimi için tahmin yürütülmez, [YerBulucuHatasi] fırlatılır.
  Future<String> saatDilimiBul(double enlem, double boylam) async {
    final yanit = await _al(
      Uri.https('api.aladhan.com', '/v1/timings',
          {'latitude': '$enlem', 'longitude': '$boylam', 'method': '13'}),
      'Saat dilimi servisi',
    );
    String? ad;
    try {
      final veri = jsonDecode(yanit);
      final data = veri is Map ? veri['data'] : null;
      final meta = data is Map ? data['meta'] : null;
      final deger = meta is Map ? meta['timezone'] : null;
      if (deger is String) ad = deger;
    } on FormatException {
      // ad null kalır
    }
    if (ad == null) throw YerBulucuHatasi('Saat dilimi alınamadı.');
    zamanDilimleriniHazirla();
    try {
      tz.getLocation(ad);
    } on tz.LocationNotFoundException {
      throw YerBulucuHatasi('Bilinmeyen saat dilimi: $ad');
    }
    return ad;
  }

  Future<String> _al(Uri adres, String servis) async {
    final http.Response yanit;
    try {
      yanit = await _istemci
          .get(adres, headers: {'User-Agent': _kimlik}).timeout(_zamanAsimi);
    } on Exception catch (e) {
      throw YerBulucuHatasi('$servis: ulaşılamadı ($e)');
    }
    if (yanit.statusCode != 200) {
      throw YerBulucuHatasi('$servis: ${yanit.statusCode} döndürdü.');
    }
    return utf8.decode(yanit.bodyBytes);
  }
}

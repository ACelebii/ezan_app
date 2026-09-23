// GPS koordinatını uygulamanın [Konum]una çevirir ("Konumumu kullan").
//
// Vakit kaynağı kararı: Diyanet'in yayınladığı saatler, birebir. Diyanet'in
// yer listelerinde koordinat yok, bu yüzden yer ADLA eşleştirilir: koordinatın
// adresi (Nominatim) ülke → şehir/eyalet → ilçe olarak Diyanet listeleriyle
// karşılaştırılır. Eşleşme varsa Diyanet ilçesi kullanılır (Diyanet saatleri).
// Eşleşme yoksa (Diyanet o yeri yayınlamıyor ya da adı farklı yazıyor) yalnızca
// koordinatlı bir konum döner; vakitleri Aladhan hesaplar. Ad ya da saat dilimi
// TAHMİN EDİLMEZ: bulunamazsa [YerBulucuHatasi] fırlatılır.

import 'diyanet_kaynagi.dart';
import 'vakit_modelleri.dart';
import 'yer_bulucu.dart';

class KonumEsleyici {
  KonumEsleyici({YerBulucu? yerBulucu, DiyanetKaynagi? diyanet})
      : _yerBulucu = yerBulucu ?? YerBulucu(),
        _diyanet = diyanet ?? DiyanetKaynagi();

  final YerBulucu _yerBulucu;
  final DiyanetKaynagi _diyanet;

  Future<Konum> bul(double enlem, double boylam) async {
    final adres = await _yerBulucu.adresBul(enlem, boylam);
    if (adres.isEmpty) {
      throw YerBulucuHatasi('Bu konumun adı bulunamadı.');
    }
    final ({Konum? konum, DiyanetYeri? ulke}) esleme;
    try {
      esleme = await _diyanetIleEsle(adres, enlem, boylam);
    } on DiyanetHatasi catch (e) {
      // Diyanet'e ulaşılamıyorsa hesaplanmış vakite SESSİZCE düşülmez: kullanıcı
      // tekrar denesin (ulaşılınca Diyanet saatleri gelir).
      throw YerBulucuHatasi('Diyanet yer listesine ulaşılamadı: ${e.mesaj}');
    }
    return esleme.konum ??
        await _hesaplanmisKonum(adres, enlem, boylam, esleme.ulke);
  }

  /// Ülke eşleştiyse ama şehir/ilçe eşleşmediyse konum null, ülke dolu döner
  /// (hesaplanmış konumun ülkesi de Türkçe yazılsın diye).
  Future<({Konum? konum, DiyanetYeri? ulke})> _diyanetIleEsle(
      Map<String, String> adres, double enlem, double boylam) async {
    final ulkeler = await _diyanet.ulkeler();
    final turkiyeMi = adres['country_code']?.toLowerCase() == 'tr';
    final ulke = turkiyeMi
        ? ulkeler.where((u) => u.id == diyanetTurkiyeUlkeId).firstOrNull
        : _eslestir(ulkeler, [adres['country']], onekOlur: false);
    if (ulke == null) return (konum: null, ulke: null);

    // Tek şehirli ülkelerde (Japonya gibi) şehir basamağı yoktur.
    final sehirler = await _diyanet.sehirler(ulke.id);
    final sehir = sehirler.length == 1
        ? sehirler.single
        : _eslestir(sehirler, [
            adres['province'], // Türkiye: il
            adres['state'],
            adres['county'],
            adres['city'], // şehir devletleri (Berlin)
          ]);
    if (sehir == null) return (konum: null, ulke: ulke);

    final ilceler = await _diyanet.ilceler(sehir.id);
    var ilce = _eslestir(ilceler, [
      adres['town'],
      adres['city'],
      adres['village'],
      adres['municipality'],
      adres['city_district'],
      adres['county'],
      adres['suburb'],
    ]);
    // Türkiye'de ilçe bulunamazsa il merkezi (ilçesi il adıyla aynı olan).
    if (ilce == null && turkiyeMi) {
      ilce = _eslestir(ilceler, [sehir.adEn, sehir.ad], onekOlur: false);
    }
    if (ilce == null) return (konum: null, ulke: ulke);

    final konum = Konum(
      ad: baslikYaz(ilce.ad, turkce: turkiyeMi),
      ulke: baslikYaz(ulke.ad, turkce: true),
      saatDilimi: turkiyeMi
          ? 'Europe/Istanbul'
          : await _yerBulucu.saatDilimiBul(enlem, boylam),
      diyanetIlceId: ilce.id,
      // Yedek kaynak ve hava durumu için GPS'in kendi koordinatı (Diyanet'in
      // ilçe merkezi değil).
      enlem: enlem,
      boylam: boylam,
    );
    return (konum: konum, ulke: ulke);
  }

  /// Diyanet'te karşılığı olmayan yer: yalnızca koordinat. Ülke Diyanet'in
  /// listesinde bulunduysa Türkçe adıyla yazılır (listedeki diğer yerler gibi).
  Future<Konum> _hesaplanmisKonum(Map<String, String> adres, double enlem,
      double boylam, DiyanetYeri? ulke) async {
    final ad = [
      adres['city'],
      adres['town'],
      adres['village'],
      adres['municipality'],
      adres['suburb'],
      adres['county'],
      adres['state'],
      adres['province'],
    ].whereType<String>().firstOrNull;
    if (ad == null) throw YerBulucuHatasi('Bu konumun adı bulunamadı.');
    final turkiyeMi = adres['country_code']?.toLowerCase() == 'tr';
    return Konum(
      ad: ad,
      ulke: turkiyeMi
          ? 'Türkiye'
          : ulke != null
              ? baslikYaz(ulke.ad, turkce: true)
              : adres['country'] ?? '',
      saatDilimi: turkiyeMi
          ? 'Europe/Istanbul'
          : await _yerBulucu.saatDilimiBul(enlem, boylam),
      enlem: enlem,
      boylam: boylam,
    );
  }

  /// [adaylar] sırasıyla [liste]deki yerlerle karşılaştırılır. Önce TAM eşleşme
  /// (harf, aksan ve büyük/küçük harf farkı yok sayılır), yoksa ÖNEK eşleşmesi
  /// ("Adachi" ↔ "ADACHI-KU"): adayın sözcükleri, yerin ilk sözcükleriyle aynıysa.
  /// "Ada" ↔ "ADACHI-KU" eşleşmez (sözcük bütün karşılaştırılır).
  static DiyanetYeri? _eslestir(List<DiyanetYeri> liste, List<String?> adaylar,
      {bool onekOlur = true}) {
    final parcali = [
      for (final a in adaylar)
        if (a != null && _parcala(a).isNotEmpty) _parcala(a),
    ];
    for (final a in parcali) {
      for (final y in liste) {
        if (_adlar(y).any((d) => _esit(d, a))) return y;
      }
    }
    if (!onekOlur) return null;
    for (final a in parcali) {
      for (final y in liste) {
        if (_adlar(y).any(
            (d) => d.length > a.length && _esit(d.sublist(0, a.length), a))) {
          return y;
        }
      }
    }
    return null;
  }

  static List<List<String>> _adlar(DiyanetYeri y) =>
      [_parcala(y.ad), _parcala(y.adEn)];

  /// "Baden-Württemberg" → [baden, wurttemberg]; harf/rakam dışı her şey ayırıcı.
  static List<String> _parcala(String ad) => aramaMetni(ad)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((p) => p.isNotEmpty)
      .toList();

  static bool _esit(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

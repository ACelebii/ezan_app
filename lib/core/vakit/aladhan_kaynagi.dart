// Aladhan'ın hesapladığı namaz vakitleri: Diyanet'e ulaşılamazsa yedek kaynak.
//
// Diyanet, ikindiyi asr-ı evvele göre yayınlar. Aladhan'ın `method=13` ayarı
// Diyanet'in açılarını ve temkinlerini kullanır; sonuç Diyanet'ten en çok
// 1 dakika (akşam ve yatsıda hep erken) sapar. Bu yüzden vakitlerin
// `kaynak` alanı `aladhan` olarak işaretlenir.
//
// Saf Dart: yalnızca `http`e bağlı. Ayrıştırma ağ isteğinden ayrıdır
// ([AladhanKaynagi.coz]).

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'vakit_modelleri.dart';

/// Aladhan'dan vakit alınamadığında fırlatılır.
class AladhanHatasi implements Exception {
  AladhanHatasi(this.mesaj);

  final String mesaj;

  @override
  String toString() => 'AladhanHatasi: $mesaj';
}

class AladhanKaynagi {
  AladhanKaynagi({http.Client? istemci}) : _istemci = istemci ?? http.Client();

  final http.Client _istemci;

  static const _sunucu = 'api.aladhan.com';
  static const _zamanAsimi = Duration(seconds: 10);

  /// [bugun]ün ayı ile bir sonraki ayın vakitlerini getirir (iki istek).
  /// Bu ay alınamazsa hata fırlatır. Sonraki ay alınamazsa yalnızca bu ay
  /// döner; yeterli gün kaldı mı diye bakmak çağıranın (servisin) işidir.
  Future<List<GunlukVakit>> vakitleriGetir(Konum konum, DateTime bugun,
      {int yontem = 13, bool hanefi = false}) async {
    final sonraki = DateTime(bugun.year, bugun.month + 1);
    final aylar = await Future.wait([
      ayiGetir(konum, bugun.year, bugun.month, yontem: yontem, hanefi: hanefi),
      ayiGetir(konum, sonraki.year, sonraki.month,
              yontem: yontem, hanefi: hanefi)
          .then((gunler) => gunler, onError: (_) => <GunlukVakit>[]),
    ]);
    return [...aylar[0], ...aylar[1]];
  }

  /// Tek bir ayın (ör. imsakiye için) vakitleri. Hata olursa [AladhanHatasi].
  Future<List<GunlukVakit>> ayiGetir(Konum konum, int yil, int ay,
      {int yontem = 13, bool hanefi = false}) async {
    final http.Response yanit;
    try {
      yanit = await _istemci
          .get(_adres(konum, yil, ay, yontem, hanefi))
          .timeout(_zamanAsimi);
    } on Exception catch (e) {
      // Zaman aşımı, bağlantı yok, DNS hatası...
      throw AladhanHatasi('Aladhan servisine ulaşılamadı: $e');
    }
    if (yanit.statusCode != 200) {
      throw AladhanHatasi('Aladhan servisi ${yanit.statusCode} döndürdü.');
    }
    return coz(utf8.decode(yanit.bodyBytes));
  }

  /// Koordinat varsa koordinatla, yoksa şehir adıyla sorar. `method` hesap
  /// yöntemidir (13 = Diyanet); `school=1` ikindiyi asr-ı sani (Hanefi) yapar,
  /// diğer vakitleri değiştirmez; `iso8601=true` saatleri
  /// "2026-09-19T05:15:00+03:00" biçiminde verir; `timezonestring`, ekran
  /// saatinin [Konum.saatDilimi]nde olmasını sağlar.
  static Uri _adres(Konum konum, int yil, int ay, int yontem, bool hanefi) {
    final ortak = {
      'method': '$yontem',
      if (hanefi) 'school': '1',
      'iso8601': 'true',
      'timezonestring': konum.saatDilimi,
    };
    if (konum.koordinatVar) {
      return Uri.https(_sunucu, '/v1/calendar/$yil/$ay', {
        ...ortak,
        'latitude': '${konum.enlem}',
        'longitude': '${konum.boylam}',
      });
    }
    // Aladhan, Türkçe harfli şehir adında 500 hatası verir ve "Türkiye"yi
    // tanımaz ("Turkey" ister).
    final ulke = _asciiYap(konum.ulke);
    return Uri.https(_sunucu, '/v1/calendarByCity/$yil/$ay', {
      ...ortak,
      'city': _asciiYap(konum.ad),
      'country': ulke.toLowerCase() == 'turkiye' ? 'Turkey' : ulke,
    });
  }

  // ponytail: yalnızca Türkçe harfler çevrilir. Başka aksanlı adlar ("São
  // Paulo") için konuma koordinat verilmeli.
  static String _asciiYap(String metin) {
    const turkce = 'çğıöşüÇĞİÖŞÜ';
    const ascii = 'cgiosuCGIOSU';
    return metin.split('').map((harf) {
      final i = turkce.indexOf(harf);
      return i < 0 ? harf : ascii[i];
    }).join();
  }

  /// Aladhan'ın `calendar` yanıtını günlük vakitlere çevirir. Bozuk günler
  /// atlanır; hiç geçerli gün kalmazsa [AladhanHatasi] fırlatır.
  static List<GunlukVakit> coz(String json) {
    final Object? veri;
    try {
      veri = jsonDecode(json);
    } on FormatException catch (e) {
      throw AladhanHatasi('Yanıt JSON değil: ${e.message}');
    }
    final gunlerHam = veri is Map<String, dynamic> ? veri['data'] : null;
    if (gunlerHam is! List) throw AladhanHatasi('Yanıtta vakit listesi yok.');

    final gunler = <GunlukVakit>[];
    for (final ham in gunlerHam) {
      if (ham is Map<String, dynamic>) {
        final gun = _gunuCoz(ham);
        if (gun != null) gunler.add(gun);
      }
    }
    if (gunler.isEmpty) {
      throw AladhanHatasi('Yanıtta geçerli bir vakit satırı yok.');
    }
    return gunler;
  }

  // Aladhan'ın ayrı bir "Imsak" alanı da var (Fajr'dan 10 dakika önce); o
  // Diyanet'in imsakı değildir. Diyanet imsakı = Fajr.
  static const _alanlar = {
    Vakit.imsak: 'Fajr',
    Vakit.gunes: 'Sunrise',
    Vakit.ogle: 'Dhuhr',
    Vakit.ikindi: 'Asr',
    Vakit.aksam: 'Maghrib',
    Vakit.yatsi: 'Isha',
  };

  static GunlukVakit? _gunuCoz(Map<String, dynamic> gun) {
    final zamanlar = gun['timings'];
    final tarih = _tarihCoz(gun['date']);
    if (zamanlar is! Map<String, dynamic> || tarih == null) return null;

    final saatler = <Vakit, String>{};
    final anlar = <Vakit, DateTime>{};
    for (final MapEntry(key: vakit, value: alan) in _alanlar.entries) {
      final metin = zamanlar[alan];
      if (metin is! String || metin.length < 16) return null;
      final an = DateTime.tryParse(metin);
      final saat =
          metin.substring(11, 16); // "2026-09-19T05:15:00+03:00" → "05:15"
      if (an == null || saatDakikaCoz(saat) == null) return null;
      saatler[vakit] = saat;
      anlar[vakit] = an; // ofsetli metinden gelir, gerçek an olarak doğrudur
    }
    return GunlukVakit(
      tarih: tarih,
      saatler: saatler,
      anlar: anlar,
      kaynak: VakitKaynagi.aladhan,
    );
  }

  /// `date.gregorian.date`: "19-09-2026" → `DateTime.utc(2026, 9, 19)`.
  static DateTime? _tarihCoz(Object? tarih) {
    final miladi = tarih is Map<String, dynamic> ? tarih['gregorian'] : null;
    final metin = miladi is Map<String, dynamic> ? miladi['date'] : null;
    final parcalar = metin is String ? metin.split('-') : const <String>[];
    if (parcalar.length != 3) return null;
    return gunAnahtariniCoz('${parcalar[2]}-${parcalar[1]}-${parcalar[0]}');
  }
}
